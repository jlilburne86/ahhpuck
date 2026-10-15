import XCTest
@testable import FreedomMobileCore

final class MobileCoreTests: XCTestCase {
    func testDashboardIsAlwaysReadOnly() async {
        let controller = MobileDashboardController()
        await controller.setReadOnlyVerified()
        let snapshot = await controller.snapshot
        XCTAssertEqual(snapshot.transport, .readOnlyVerified)
        XCTAssertEqual(snapshot.writeAuthorization, "never")
    }

    func testCriticalFrameIsMarkedAborted() async {
        let controller = MobileDashboardController()
        await controller.setReadOnlyVerified()
        await controller.ingest(.init(rpm: 5000, loadKPa: 95, lambda: 1.1, coolantC: 106, knockLevel: 0.2))
        let snapshot = await controller.snapshot
        XCTAssertEqual(snapshot.protectionState, "aborted")
    }

    func testUSBTransportDoesNotPretendToWork() async {
        let transport = IOSUSBTransport()
        do {
            try await transport.connect()
            XCTFail("placeholder transport must not connect")
        } catch let error as MobileTransportError {
            XCTAssertEqual(error, .usbAccessoryUnavailable)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testFC03ProtocolUsesExactReadOnlyDATRequest() {
        XCTAssertEqual(FC03ReadOnlyProtocol.makeDATRequest(), Data([0x3F, 0x44, 0x41, 0x54]))
        XCTAssertEqual(FC03ReadOnlyProtocol.serialProfile, .documented)
    }

    func testFC03CoordinatorRetainsInvalidRawResponseAndPersistsSession() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = FC03CaptureFileStore(directory: directory)
        let metadata = FC03CaptureMetadata(ecuLabel: "FC-03 desk unit", ecuProfile: "unknown",
                                            adapter: "bench adapter", cableNotes: "unverified")
        let coordinator = FC03CaptureCoordinator(metadata: metadata, store: store)
        let exchange = await coordinator.ingestDAT(response: Data([0x00, 0x01]))
        XCTAssertEqual(exchange.request, FC03ReadOnlyProtocol.makeDATRequest())
        XCTAssertFalse(exchange.shapeValid)
        XCTAssertEqual(exchange.responseLength, 2)
        let url = try await coordinator.finish()
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let loaded = try store.loadLatest()
        XCTAssertEqual(loaded?.exchanges.count, 1)
        XCTAssertEqual(loaded?.invalidExchangeCount, 1)
        XCTAssertEqual(loaded?.metadata.serialProfile, .documented)
    }

    func testReplayTransportYieldsStoredFramesInOrderAndNeverWrites() async throws {
        let frames = [
            MobileTelemetryFrame(sequence: 10, rpm: 1200, loadKPa: 25, lambda: 1.02),
            MobileTelemetryFrame(sequence: 11, rpm: 1800, loadKPa: 35, lambda: 0.99)
        ]
        let transport = MobileReplayTransport(frames: frames)
        do {
            _ = try await transport.readOnlyIdentity()
            XCTFail("replay must require connect")
        } catch let error as MobileTransportError {
            XCTAssertEqual(error, .notConnected)
        }
        try await transport.connect()
        let identity = try await transport.readOnlyIdentity()
        XCTAssertEqual(identity, "LOCAL EVIDENCE REPLAY")
        var received: [MobileTelemetryFrame] = []
        for try await frame in transport.frames() { received.append(frame) }
        XCTAssertEqual(received, frames)
        await transport.disconnect()
    }

    func testReadinessPausesOnMissingFuelPressureAndIgnitionReference() {
        var evidence = MobileReadinessEvidence()
        evidence.ecuIdentityVerified = true
        evidence.protocolVerified = true
        evidence.originalMapBackup = true
        evidence.engineProfileVerified = true
        let result = MobileReadinessAssessor.assess(evidence)
        XCTAssertEqual(result.state, .paused)
        XCTAssertTrue(result.missingEvidence.contains("Fuel pressure"))
        XCTAssertTrue(result.missingEvidence.contains("Ignition reference"))
        XCTAssertFalse(result.canTest)
        XCTAssertEqual(result.writeAuthorization, "never")
    }

    func testReadinessStopsOnCriticalFault() {
        let result = MobileReadinessAssessor.assess(.init(), criticalReasons: ["knock"])
        XCTAssertEqual(result.state, .stop)
        XCTAssertEqual(result.criticalReasons, ["knock"])
        XCTAssertFalse(result.canTest)
    }

    func testFirstTrialRunsEndToEndWithoutEnablingWrites() {
        var trial = MobileTrialSession.demo()
        XCTAssertEqual(trial.stage, .assessed)
        XCTAssertEqual(trial.assessment?.decision, .acceptCandidate)
        XCTAssertFalse(trial.approvalRecorded)
        XCTAssertTrue(trial.recordApproval())
        XCTAssertTrue(trial.approvalRecorded)
        XCTAssertEqual(trial.assessment?.writeAuthorization, "never")
    }

    func testTrialCannotCaptureBeforeReadiness() {
        var trial = MobileTrialSession()
        XCTAssertFalse(trial.capture(.baseline, frames: [MobileTelemetryFrame(rpm: 2000, loadKPa: 30)]))
        XCTAssertEqual(trial.stage, .blocked)
    }

    func testExperimentAssessmentRequiresRepeatableImprovement() {
        let baseline = demoFrames(lambda: [1.00, 0.99, 1.00])
        let candidate = demoFrames(lambda: [0.93, 0.92, 0.91], start: 10)
        let repeatRun = demoFrames(lambda: [0.925, 0.915, 0.905], start: 20)
        let result = MobileExperimentAssessor.assess(baseline: baseline, candidate: candidate, repeatRun: repeatRun)
        XCTAssertEqual(result.decision, .acceptCandidate)
        XCTAssertTrue(result.repeatable == true)
        XCTAssertEqual(result.nextChangeFractionLimit, 0.005, accuracy: 0.0001)
        XCTAssertEqual(result.writeAuthorization, "never")
    }

    func testExperimentAssessmentAbortsOnKnock() {
        let frames = demoFrames(lambda: [0.98, 0.99]).map { frame in
            MobileTelemetryFrame(timestamp: frame.timestamp, sequence: frame.sequence, rpm: frame.rpm, loadKPa: 90, lambda: frame.lambda, knockLevel: 0.3)
        }
        let result = MobileExperimentAssessor.assess(baseline: frames, candidate: frames, repeatRun: frames)
        XCTAssertEqual(result.decision, .stopAndAbort)
        XCTAssertTrue(result.hasCriticalConcern)
    }

    func testExperimentAssessmentTreatsGapsAsIncomplete() {
        let baseline = demoFrames(lambda: [1.00, 0.99, 1.00])
        let gapped = [demoFrames(lambda: [0.93], start: 10)[0], demoFrames(lambda: [0.92], start: 14)[0]]
        let repeatRun = demoFrames(lambda: [0.925, 0.915], start: 20)
        let result = MobileExperimentAssessor.assess(baseline: baseline, candidate: gapped, repeatRun: repeatRun)
        XCTAssertFalse(result.telemetryComplete)
        XCTAssertEqual(result.decision, .stopAndAbort)
    }

    func testBaselineSummaryCalculatesStatsAndFlagsMissingLambda() {
        let start = Date(timeIntervalSince1970: 1_000)
        let frames = [
            MobileTelemetryFrame(timestamp: start, rpm: 900, loadKPa: 35, lambda: 1.02, coolantC: 82, batteryV: 13.7),
            MobileTelemetryFrame(timestamp: start.addingTimeInterval(0.25), rpm: 1100, loadKPa: 40, lambda: nil, coolantC: 83, batteryV: 13.8),
            MobileTelemetryFrame(timestamp: start.addingTimeInterval(0.5), rpm: 1300, loadKPa: 45, lambda: 0.98, coolantC: 84, batteryV: 13.9)
        ]
        let summary = MobileBaselineSummary(run: MobileRunRecord(kind: .baseline, title: "Desk baseline", frames: frames))
        XCTAssertEqual(summary.frameCount, 3)
        XCTAssertEqual(summary.rpm?.median, 1100)
        XCTAssertEqual(summary.lambda?.count, 2)
        XCTAssertTrue(summary.issues.contains(.missingLambda))
        XCTAssertEqual(summary.coveragePercent, 100, accuracy: 0.01)
    }

    func testRunComparisonRequiresRepeatForConfirmation() {
        let start = Date(timeIntervalSince1970: 2_000)
        func run(_ kind: MobileRunKind, _ values: [Double], offset: TimeInterval) -> MobileRunRecord {
            MobileRunRecord(kind: kind, title: kind.rawValue, frames: values.enumerated().map { i, lambda in
                MobileTelemetryFrame(timestamp: start.addingTimeInterval(offset + Double(i) * 0.25), rpm: 3000, loadKPa: 60, lambda: lambda)
            })
        }
        let baseline = run(.baseline, [1.08, 1.07, 1.09], offset: 0)
        let candidate = run(.candidate, [1.03, 1.02, 1.03], offset: 10)
        let repeatRun = run(.repeatRun, [1.031, 1.021, 1.029], offset: 20)
        let result = MobileRunComparison(baseline: baseline, candidate: candidate, repeatRun: repeatRun)
        XCTAssertEqual(result.decision, .improvementConfirmed)
        XCTAssertEqual(result.repeatable, true)
        XCTAssertGreaterThan(result.improvementPercent ?? 0, 50)
    }

    func testRunStoreRoundTripsRawFrames() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = MobileRunStore(directory: directory)
        let fixed = Date(timeIntervalSince1970: 3_000.125)
        let run = MobileRunRecord(kind: .baseline, title: "Round trip", createdAt: fixed,
                                  frames: [MobileTelemetryFrame(timestamp: fixed, rpm: 1200, loadKPa: 30)])
        _ = try await store.save(run)
        let loaded = try await store.loadAll()
        XCTAssertEqual(loaded, [run])
    }

    func testOfflineAIStopsOnCriticalEvidenceAndNeverAuthorizesWrites() {
        let frames = demoFrames(lambda: [0.98, 0.99]).map { frame in
            MobileTelemetryFrame(timestamp: frame.timestamp, sequence: frame.sequence, rpm: frame.rpm,
                                  loadKPa: frame.loadKPa, lambda: frame.lambda, knockLevel: 0.3)
        }
        let baseline = MobileRunRecord(kind: .baseline, title: "base", frames: frames)
        let candidate = MobileRunRecord(kind: .candidate, title: "candidate", frames: frames)
        let repeatRun = MobileRunRecord(kind: .repeatRun, title: "repeat", frames: frames)
        let assessment = MobileExperimentAssessor.assess(baseline: frames, candidate: frames, repeatRun: frames)
        let result = DeterministicMobileAIEngine().analyze(.init(
            baselineID: baseline.id, candidateID: candidate.id, repeatID: repeatRun.id,
            comparison: MobileRunComparison(baseline: baseline, candidate: candidate, repeatRun: repeatRun),
            assessment: assessment,
            summaries: [MobileBaselineSummary(run: baseline)]))
        XCTAssertEqual(result.decision, .stopAndAbort)
        XCTAssertTrue(result.findings.contains { $0.id == "knock_detected" })
        XCTAssertEqual(result.writeAuthorization, "never")
        XCTAssertFalse(result.nextAction.contains("lambda"))
    }

    func testDeepLinksCarryOnlyRunIdentifiers() {
        let baseline = UUID(), candidate = UUID(), repeatID = UUID()
        let url = URL(string: "ahhpuck://ai/assess?baseline=\(baseline.uuidString)&candidate=\(candidate.uuidString)&repeat=\(repeatID.uuidString)")!
        XCTAssertEqual(MobileDeepLink.parse(url), .assess(baseline: baseline, candidate: candidate, repeatID: repeatID))
        XCTAssertEqual(MobileDeepLink.parse(MobileDeepLink.assess(baseline: baseline, candidate: candidate, repeatID: repeatID).url!), .assess(baseline: baseline, candidate: candidate, repeatID: repeatID))
        XCTAssertEqual(MobileDeepLink.parse(URL(string: "ahhpuck://runs/\(baseline.uuidString)")!), .run(baseline))
        XCTAssertNil(MobileDeepLink.parse(URL(string: "https://example.com/ai/assess")!))
        XCTAssertNil(MobileDeepLink.parse(URL(string: "ahhpuck://ai/assess?lambda=0.9")!))
    }

    func testAIResultStoreRoundTripsLocalAssessment() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = MobileAIResultStore(directory: directory)
        let result = MobileAIResult(id: UUID(), createdAt: Date(timeIntervalSince1970: 4_000),
                                    summary: "Repeat required", confidence: 0.6, findings: [],
                                    nextAction: "Repeat", decision: .repeatExperiment)
        _ = try await store.save(result)
        let loaded = try await store.loadLatest()
        XCTAssertEqual(loaded, result)
    }

    func testReadOnlyCaptureRunnerSendsOnlyDATAndPersistsInvalidReplies() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = FC03CaptureFileStore(directory: directory)
        let metadata = FC03CaptureMetadata(ecuLabel: "desk FC-03", ecuProfile: "unknown",
                                            adapter: "test adapter", cableNotes: "bench")
        let transport = FixedFC03Transport(response: Data(repeating: 0xAA, count: 2))
        let summary = try await FC03ReadOnlyCaptureRunner(transport: transport)
            .capture(metadata: metadata, samples: 3, store: store)
        XCTAssertEqual(summary.requestedSamples, 3)
        XCTAssertEqual(summary.capturedSamples, 3)
        XCTAssertEqual(summary.invalidSamples, 3)
        let requests = await transport.requests
        let opened = await transport.opened
        let closed = await transport.closed
        XCTAssertEqual(requests, [FC03ReadOnlyProtocol.makeDATRequest(), FC03ReadOnlyProtocol.makeDATRequest(), FC03ReadOnlyProtocol.makeDATRequest()])
        XCTAssertTrue(opened)
        XCTAssertTrue(closed)
    }

    func testReadOnlyCaptureRunnerRejectsZeroSamples() async {
        let transport = FixedFC03Transport(response: Data())
        do {
            _ = try await FC03ReadOnlyCaptureRunner(transport: transport).capture(
                metadata: .init(ecuLabel: "desk", ecuProfile: "unknown", adapter: "test", cableNotes: "test"),
                samples: 0)
            XCTFail("zero samples must be rejected")
        } catch let error as FC03CaptureRunError {
            XCTAssertEqual(error, .invalidSampleCount)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    private func demoFrames(lambda: [Double], start: Int = 0) -> [MobileTelemetryFrame] {
        lambda.enumerated().map { index, value in
            MobileTelemetryFrame(sequence: start + index, rpm: 3000 + Double(index * 100), loadKPa: 50, lambda: value, coolantC: 85, intakeAirC: 32, oilPressureKPa: 380, fuelPressureKPa: 300, batteryV: 13.8)
        }
    }
}

private actor FixedFC03Transport: FC03ByteTransport {
    let response: Data
    private(set) var requests: [Data] = []
    private(set) var opened = false
    private(set) var closed = false

    init(response: Data) { self.response = response }
    func open() async throws { opened = true }
    func close() async { closed = true }
    func exchange(_ request: Data) async throws -> Data {
        requests.append(request)
        return response
    }
}
