import Foundation

public enum MobileTrialRunType: String, Codable, Sendable {
    case baseline, candidate, repeatCandidate
}

public enum MobileTrialStage: String, Codable, Sendable {
    case setup, ready, baselineCaptured, candidateCaptured, repeatCaptured, assessed, blocked
}

/// A complete first-trial workflow using normalized fixture data. The same
/// state machine will be fed by the verified FC-03 transport later.
public struct MobileTrialSession: Codable, Equatable, Sendable {
    public let profile: String
    public var stage: MobileTrialStage
    public var readiness: MobileReadinessAssessment
    public private(set) var baseline: [MobileTelemetryFrame]
    public private(set) var candidate: [MobileTelemetryFrame]
    public private(set) var repeatCandidate: [MobileTelemetryFrame]
    public private(set) var assessment: MobileExperimentAssessment?
    public private(set) var approvalRecorded = false

    public init(profile: String = "AE86 · 4A-GE 20V Blacktop · Freedom FC-03") {
        self.profile = profile
        self.stage = .setup
        self.readiness = MobileReadinessAssessor.assess(.init())
        self.baseline = []
        self.candidate = []
        self.repeatCandidate = []
    }

    public var isComplete: Bool { assessment != nil }

    public mutating func loadReadiness(_ evidence: MobileReadinessEvidence) {
        readiness = MobileReadinessAssessor.assess(evidence)
        stage = readiness.canTest ? .ready : .setup
    }

    @discardableResult
    public mutating func capture(_ type: MobileTrialRunType, frames: [MobileTelemetryFrame]) -> Bool {
        guard readiness.canTest, !frames.isEmpty else {
            stage = .blocked
            return false
        }
        switch type {
        case .baseline:
            baseline = frames
            stage = .baselineCaptured
        case .candidate:
            guard !baseline.isEmpty else { stage = .blocked; return false }
            candidate = frames
            stage = .candidateCaptured
        case .repeatCandidate:
            guard !candidate.isEmpty else { stage = .blocked; return false }
            repeatCandidate = frames
            stage = .repeatCaptured
        }
        return true
    }

    @discardableResult
    public mutating func assess(targetLambda: Double = 0.90) -> MobileExperimentAssessment? {
        guard !baseline.isEmpty, !candidate.isEmpty, !repeatCandidate.isEmpty else {
            stage = .blocked
            return nil
        }
        let result = MobileExperimentAssessor.assess(
            baseline: baseline,
            candidate: candidate,
            repeatRun: repeatCandidate,
            targetLambda: targetLambda
        )
        assessment = result
        stage = result.decision == .stopAndAbort ? .blocked : .assessed
        return result
    }

    public mutating func recordApproval() -> Bool {
        guard assessment?.decision == .acceptCandidate else { return false }
        approvalRecorded = true
        return true
    }

    public static func demo() -> MobileTrialSession {
        var session = MobileTrialSession()
        var evidence = MobileReadinessEvidence()
        evidence.ecuIdentityVerified = true
        evidence.protocolVerified = true
        evidence.originalMapBackup = true
        evidence.engineProfileVerified = true
        evidence.injectorDataVerified = true
        evidence.fuelPressureVerified = true
        evidence.widebandCalibrated = true
        evidence.ignitionOffsetVerified = true
        evidence.sensorPlausibilityPassed = true
        evidence.protectionConfigured = true
        evidence.repeatableLogEvidence = true
        session.loadReadiness(evidence)
        _ = session.capture(.baseline, frames: FixtureRuns.baseline)
        _ = session.capture(.candidate, frames: FixtureRuns.candidate)
        _ = session.capture(.repeatCandidate, frames: FixtureRuns.repeatCandidate)
        _ = session.assess()
        return session
    }
}

private enum FixtureRuns {
    static func frames(_ values: [Double], start: Int) -> [MobileTelemetryFrame] {
        values.enumerated().map { index, lambda in
            MobileTelemetryFrame(sequence: start + index, rpm: 3200 + Double(index * 100), loadKPa: 55,
                                 lambda: lambda, coolantC: 84, intakeAirC: 31,
                                 oilPressureKPa: 380, fuelPressureKPa: 300, batteryV: 13.8)
        }
    }

    static let baseline = frames([1.00, 0.99, 1.00, 0.99], start: 0)
    static let candidate = frames([0.93, 0.92, 0.91, 0.92], start: 10)
    static let repeatCandidate = frames([0.925, 0.915, 0.905, 0.915], start: 20)
}
