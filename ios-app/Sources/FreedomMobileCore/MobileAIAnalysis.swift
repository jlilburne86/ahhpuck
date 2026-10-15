import Foundation

public enum MobileAIFindingSeverity: String, Codable, Equatable, Sendable {
    case critical, warning, note
}

public struct MobileAIFinding: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let severity: MobileAIFindingSeverity
    public let title: String
    public let explanation: String
    public let nextCheck: String
    public let evidenceIDs: [UUID]

    public init(id: String, severity: MobileAIFindingSeverity, title: String,
                explanation: String, nextCheck: String, evidenceIDs: [UUID] = []) {
        self.id = id; self.severity = severity; self.title = title
        self.explanation = explanation; self.nextCheck = nextCheck
        self.evidenceIDs = evidenceIDs
    }
}

public struct MobileAIRequest: Codable, Equatable, Sendable {
    public let baselineID: UUID?
    public let candidateID: UUID?
    public let repeatID: UUID?
    public let comparison: MobileRunComparison?
    public let assessment: MobileExperimentAssessment?
    public let summaries: [MobileBaselineSummary]

    public init(baselineID: UUID? = nil, candidateID: UUID? = nil, repeatID: UUID? = nil,
                comparison: MobileRunComparison? = nil, assessment: MobileExperimentAssessment? = nil,
                summaries: [MobileBaselineSummary] = []) {
        self.baselineID = baselineID; self.candidateID = candidateID; self.repeatID = repeatID
        self.comparison = comparison; self.assessment = assessment; self.summaries = summaries
    }
}

public struct MobileAIResult: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let createdAt: Date
    public let mode: String
    public let summary: String
    public let confidence: Double
    public let findings: [MobileAIFinding]
    public let nextAction: String
    public let decision: MobileExperimentDecision?
    public let sourceRunIDs: [UUID]
    public let writeAuthorization: String

    public init(id: UUID = UUID(), createdAt: Date = Date(), mode: String = "deterministic_local",
                summary: String, confidence: Double, findings: [MobileAIFinding], nextAction: String,
                decision: MobileExperimentDecision? = nil, sourceRunIDs: [UUID] = [],
                writeAuthorization: String = "never") {
        self.id = id; self.createdAt = createdAt; self.mode = mode; self.summary = summary
        self.confidence = max(0, min(1, confidence)); self.findings = findings
        self.nextAction = nextAction; self.decision = decision; self.sourceRunIDs = sourceRunIDs
        self.writeAuthorization = writeAuthorization
    }
}

public protocol MobileAIAnalysisEngine: Sendable {
    func analyze(_ request: MobileAIRequest) -> MobileAIResult
}

/// A local, deterministic explanation layer. It can explain evidence and name the
/// next measurement, but it cannot alter the gate, suggest calibration values, or write ECU data.
public struct DeterministicMobileAIEngine: MobileAIAnalysisEngine, Sendable {
    public init() {}

    public func analyze(_ request: MobileAIRequest) -> MobileAIResult {
        var findings: [MobileAIFinding] = []
        let sourceIDs = [request.baselineID, request.candidateID, request.repeatID].compactMap { $0 }
        let assessment = request.assessment
        let decision = assessment?.decision ?? decision(from: request.comparison)

        if let concerns = assessment?.concerns {
            for concern in concerns {
                findings.append(finding(for: concern, evidenceIDs: sourceIDs))
            }
        } else if let comparison = request.comparison {
            findings.append(contentsOf: comparisonFindings(comparison, evidenceIDs: sourceIDs))
        }

        if findings.isEmpty {
            findings.append(.init(id: "evidence_pending", severity: .warning,
                                  title: "Evidence pending",
                                  explanation: "There is not enough persisted evidence to explain a change.",
                                  nextCheck: "Capture a baseline, candidate and repeat under the same conditions.",
                                  evidenceIDs: sourceIDs))
        }
        let critical = findings.contains { $0.severity == .critical }
        let hasWarning = findings.contains { $0.severity == .warning }
        let summary: String
        let next: String
        switch decision {
        case .stopAndAbort:
            summary = "Stop and investigate before learning from this run."
            next = findings.first(where: { $0.severity == .critical })?.nextCheck ?? "Preserve the capture and inspect the critical signal."
        case .repeatExperiment:
            summary = "The evidence is not repeatable enough to accept the candidate."
            next = "Repeat the same test condition and keep the ECU read-only."
        case .rollbackAndInvestigate:
            summary = "The candidate regressed against the baseline."
            next = "Hold the candidate, preserve both captures and investigate the changed condition."
        case .acceptCandidate:
            summary = "The captured result is consistent with an improvement."
            next = "Record operator approval, then run a smaller controlled experiment; no ECU write is authorised."
        case .none:
            summary = "More evidence is required before this change can be explained."
            next = "Capture complete baseline, candidate and repeat runs."
        }
        let quality = request.summaries.isEmpty ? 0.35 : Double(request.summaries.map(\.qualityScore).reduce(0, +)) / Double(request.summaries.count) / 100
        let confidence = max(0.2, min(0.95, quality - (critical ? 0.25 : hasWarning ? 0.1 : 0)))
        return .init(summary: summary, confidence: confidence, findings: findings,
                     nextAction: next, decision: decision, sourceRunIDs: sourceIDs)
    }

    private func decision(from comparison: MobileRunComparison?) -> MobileExperimentDecision? {
        switch comparison?.decision {
        case .improvementConfirmed: return .acceptCandidate
        case .repeatRequired: return .repeatExperiment
        case .regression: return .rollbackAndInvestigate
        case .insufficientData, .none: return nil
        }
    }

    private func finding(for concern: MobileExperimentConcern, evidenceIDs: [UUID]) -> MobileAIFinding {
        let severity: MobileAIFindingSeverity = switch concern.severity {
        case .critical: .critical
        case .warning: .warning
        case .note: .note
        }
        let check: String = switch concern.code {
        case "knock_detected": "Stop the test; verify knock with an independent measurement before another run."
        case "telemetry_incomplete": "Check cable stability, frame sequence and sensor availability, then recapture."
        case "not_repeatable": "Repeat the same route, gear, temperature and load window."
        case "missing_run": "Capture the missing baseline, candidate or repeat run."
        default: "Inspect the source capture and repeat the smallest safe check."
        }
        return .init(id: concern.code, severity: severity, title: concern.title,
                     explanation: concern.detail, nextCheck: check, evidenceIDs: evidenceIDs)
    }

    private func comparisonFindings(_ comparison: MobileRunComparison, evidenceIDs: [UUID]) -> [MobileAIFinding] {
        switch comparison.decision {
        case .improvementConfirmed:
            return [.init(id: "repeat_confirmed", severity: .note, title: "Repeat agrees with candidate",
                          explanation: "The candidate and repeat lambda error are within the current comparison tolerance.",
                          nextCheck: "Review the source runs and keep the next experiment smaller.", evidenceIDs: evidenceIDs)]
        case .repeatRequired:
            return [.init(id: "not_repeatable", severity: .warning, title: "Repeatability not proven",
                          explanation: "The candidate changed the measured error, but the repeat does not yet agree closely enough.",
                          nextCheck: "Repeat under matched conditions before accepting the candidate.", evidenceIDs: evidenceIDs)]
        case .regression:
            return [.init(id: "performance_regression", severity: .warning, title: "Candidate regressed",
                          explanation: "The candidate error is not better than the baseline in the persisted comparison.",
                          nextCheck: "Hold the candidate and investigate the changed condition.", evidenceIDs: evidenceIDs)]
        case .insufficientData:
            return [.init(id: "missing_run", severity: .warning, title: "Insufficient comparison data",
                          explanation: "One or more runs do not contain enough lambda evidence for comparison.",
                          nextCheck: "Capture complete baseline, candidate and repeat runs.", evidenceIDs: evidenceIDs)]
        }
    }
}

public actor MobileAIResultStore {
    public let directory: URL
    private let fileManager: FileManager

    public init(directory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.directory = directory ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AhhPuck/AIResults", isDirectory: true)
    }

    @discardableResult public func save(_ result: MobileAIResult) throws -> URL {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let url = directory.appendingPathComponent("assessment-\(result.id.uuidString).json")
        try encoder.encode(result).write(to: url, options: .atomic)
        return url
    }

    public func loadLatest() throws -> MobileAIResult? {
        guard fileManager.fileExists(atPath: directory.path) else { return nil }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .millisecondsSince1970
        return try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .compactMap { try? decoder.decode(MobileAIResult.self, from: Data(contentsOf: $0)) }
            .first
    }
}

public enum MobileDeepLink: Equatable, Sendable {
    case assess(baseline: UUID?, candidate: UUID?, repeatID: UUID?)
    case explain(run: UUID)
    case run(UUID)

    public static func parse(_ url: URL) -> MobileDeepLink? {
        guard url.scheme?.lowercased() == "ahhpuck" else { return nil }
        let host = url.host?.lowercased()
        let parts = url.path.split(separator: "/").map(String.init)
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func uuid(_ name: String) -> UUID? { query.first(where: { $0.name == name })?.value.flatMap(UUID.init) }
        switch (host, parts) {
        case ("ai", ["assess"]):
            let values = [uuid("baseline"), uuid("candidate"), uuid("repeat")]
            return values.contains(where: { $0 != nil }) ? .assess(baseline: values[0], candidate: values[1], repeatID: values[2]) : nil
        case ("ai", ["explain"]):
            guard let id = uuid("run") else { return nil }; return .explain(run: id)
        case ("runs", let path) where path.count == 1:
            guard let uuid = UUID(uuidString: path[0]) else { return nil }; return .run(uuid)
        default: return nil
        }
    }
}
