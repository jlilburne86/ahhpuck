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

    private func demoFrames(lambda: [Double], start: Int = 0) -> [MobileTelemetryFrame] {
        lambda.enumerated().map { index, value in
            MobileTelemetryFrame(sequence: start + index, rpm: 3000 + Double(index * 100), loadKPa: 50, lambda: value, coolantC: 85, intakeAirC: 32, oilPressureKPa: 380, fuelPressureKPa: 300, batteryV: 13.8)
        }
    }
}
