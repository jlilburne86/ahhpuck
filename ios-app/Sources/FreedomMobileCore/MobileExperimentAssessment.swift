import Foundation

public enum MobileExperimentDecision: String, Codable, Sendable {
    case acceptCandidate, repeatExperiment, rollbackAndInvestigate, stopAndAbort
}

public struct MobileExperimentConcern: Codable, Equatable, Sendable {
    public enum Severity: String, Codable, Sendable { case critical, warning, note }
    public let severity: Severity
    public let code: String
    public let title: String
    public let detail: String

    public init(severity: Severity, code: String, title: String, detail: String) {
        self.severity = severity; self.code = code; self.title = title; self.detail = detail
    }
}

public struct MobileExperimentAssessment: Codable, Equatable, Sendable {
    public let decision: MobileExperimentDecision
    public let baselineLambdaError: Double?
    public let candidateLambdaError: Double?
    public let improvementFraction: Double?
    public let repeatDifference: Double?
    public let repeatable: Bool?
    public let telemetryComplete: Bool
    public let knockEvents: Int
    public let nextChangeFractionLimit: Double
    public let concerns: [MobileExperimentConcern]

    public var writeAuthorization: String { "never" }
    public var hasCriticalConcern: Bool { concerns.contains { $0.severity == .critical } }

    public init(decision: MobileExperimentDecision, baselineLambdaError: Double?, candidateLambdaError: Double?, improvementFraction: Double?, repeatDifference: Double?, repeatable: Bool?, telemetryComplete: Bool, knockEvents: Int, nextChangeFractionLimit: Double, concerns: [MobileExperimentConcern]) {
        self.decision = decision; self.baselineLambdaError = baselineLambdaError; self.candidateLambdaError = candidateLambdaError; self.improvementFraction = improvementFraction; self.repeatDifference = repeatDifference; self.repeatable = repeatable; self.telemetryComplete = telemetryComplete; self.knockEvents = knockEvents; self.nextChangeFractionLimit = nextChangeFractionLimit; self.concerns = concerns
    }
}

/// Deterministic assessment used by the native UI and future local AI explanations.
/// It cannot authorize ECU writes and requires a repeat run before accepting an improvement.
public enum MobileExperimentAssessor {
    public static func assess(baseline: [MobileTelemetryFrame], candidate: [MobileTelemetryFrame], repeatRun: [MobileTelemetryFrame], targetLambda: Double = 0.90, previousChangeFraction: Double = 0.01) -> MobileExperimentAssessment {
        let baselineError = meanError(baseline, target: targetLambda)
        let candidateError = meanError(candidate, target: targetLambda)
        let repeatError = meanError(repeatRun, target: targetLambda)
        let improvement: Double? = if let baselineError, let candidateError, baselineError > 0 { (baselineError - candidateError) / baselineError } else { nil }
        let repeatDifference: Double? = if let candidateError, let repeatError { abs(candidateError - repeatError) } else { nil }
        let repeatable = repeatDifference.map { $0 <= 0.03 }
        let telemetryComplete = isComplete(candidate) && isComplete(repeatRun)
        let knockEvents = candidate.filter { ($0.knockLevel ?? 0) > 0.15 }.count + repeatRun.filter { ($0.knockLevel ?? 0) > 0.15 }.count
        var concerns: [MobileExperimentConcern] = []
        if knockEvents > 0 { concerns.append(.init(severity: .critical, code: "knock_detected", title: "Knock detected", detail: "Stop the test and investigate before learning from this change.")) }
        if !telemetryComplete { concerns.append(.init(severity: .critical, code: "telemetry_incomplete", title: "Telemetry incomplete", detail: "Dropped or missing frames mean this run cannot be used for learning.")) }
        if repeatable == false { concerns.append(.init(severity: .warning, code: "not_repeatable", title: "Repeatability not proven", detail: "Repeat the same test condition before accepting the candidate.")) }
        if baseline.isEmpty || candidate.isEmpty || repeatRun.isEmpty { concerns.append(.init(severity: .warning, code: "missing_run", title: "Run data missing", detail: "Baseline, candidate, and repeat captures are all required.")) }

        let critical = concerns.contains { $0.severity == .critical }
        let accepted = !critical && improvement.map { $0 > 0 } == true && repeatable == true
        let decision: MobileExperimentDecision = critical ? .stopAndAbort : accepted ? .acceptCandidate : (improvement.map { $0 < 0 } == true ? .rollbackAndInvestigate : .repeatExperiment)
        let nextLimit = accepted ? min(abs(previousChangeFraction) / 2, 0.02) : 0
        return .init(decision: decision, baselineLambdaError: baselineError, candidateLambdaError: candidateError, improvementFraction: improvement, repeatDifference: repeatDifference, repeatable: repeatable, telemetryComplete: telemetryComplete, knockEvents: knockEvents, nextChangeFractionLimit: nextLimit, concerns: concerns)
    }

    private static func meanError(_ frames: [MobileTelemetryFrame], target: Double) -> Double? {
        let values = frames.compactMap { $0.lambda }.map { abs($0 - target) }
        return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }

    private static func isComplete(_ frames: [MobileTelemetryFrame]) -> Bool {
        // Fail closed and match tools/telemetry_stats.py: every frame needs a sequence number,
        // there must be at least two, and there may be no gaps (frames 1, 5, 9 are incomplete).
        let sequences = frames.compactMap(\.sequence)
        guard frames.count > 1, sequences.count == frames.count else { return false }
        return zip(sequences, sequences.dropFirst()).allSatisfy { $1 == $0 + 1 }
    }
}
