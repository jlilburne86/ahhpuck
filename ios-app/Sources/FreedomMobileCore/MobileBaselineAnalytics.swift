import Foundation

public enum MobileRunKind: String, Codable, Equatable, Sendable {
    case baseline
    case candidate
    case repeatRun
    case observation
}

/// A portable run record. Frames are retained exactly as received; derived
/// statistics are calculated on demand so the raw evidence remains canonical.
public struct MobileRunRecord: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let kind: MobileRunKind
    public let title: String
    public let createdAt: Date
    public let vehicleProfile: [String: String]
    public let modifications: [String]
    public let frames: [MobileTelemetryFrame]

    public init(id: UUID = UUID(), kind: MobileRunKind, title: String,
                createdAt: Date = Date(), vehicleProfile: [String: String] = [:],
                modifications: [String] = [], frames: [MobileTelemetryFrame]) {
        self.id = id
        self.kind = kind
        self.title = title
        self.createdAt = createdAt
        self.vehicleProfile = vehicleProfile
        self.modifications = modifications
        self.frames = frames
    }
}

public struct MobileSignalStats: Codable, Equatable, Sendable {
    public let count: Int
    public let minimum: Double
    public let maximum: Double
    public let mean: Double
    public let median: Double

    public init(values: [Double]) {
        let sorted = values.sorted()
        count = sorted.count
        minimum = sorted.first ?? 0
        maximum = sorted.last ?? 0
        mean = sorted.isEmpty ? 0 : sorted.reduce(0, +) / Double(sorted.count)
        if sorted.isEmpty { median = 0 }
        else if sorted.count.isMultiple(of: 2) {
            median = (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2
        } else {
            median = sorted[sorted.count / 2]
        }
    }

    public var spread: Double { maximum - minimum }
}

public enum MobileDataQualityIssue: String, Codable, Equatable, Sendable {
    case noFrames
    case missingLambda
    case missingLoad
    case timestampGap
    case criticalValueOutOfRange
}

public struct MobileBaselineSummary: Codable, Equatable, Sendable {
    public let runID: UUID
    public let frameCount: Int
    public let durationSeconds: Double
    public let coveragePercent: Double
    public let qualityScore: Int
    public let rpm: MobileSignalStats?
    public let loadKPa: MobileSignalStats?
    public let lambda: MobileSignalStats?
    public let coolantC: MobileSignalStats?
    public let batteryV: MobileSignalStats?
    public let issues: [MobileDataQualityIssue]

    public var isUsable: Bool {
        frameCount >= 3 && coveragePercent >= 95 && !issues.contains(.criticalValueOutOfRange)
    }

    public init(run: MobileRunRecord, expectedIntervalSeconds: Double = 0.25) {
        runID = run.id
        frameCount = run.frames.count
        durationSeconds = Self.duration(of: run.frames)
        coveragePercent = Self.coverage(of: run.frames, expectedIntervalSeconds: expectedIntervalSeconds)
        rpm = Self.stats(run.frames.map(\.rpm))
        loadKPa = Self.stats(run.frames.map(\.loadKPa))
        lambda = Self.stats(run.frames.compactMap(\.lambda))
        coolantC = Self.stats(run.frames.compactMap(\.coolantC))
        batteryV = Self.stats(run.frames.compactMap(\.batteryV))

        var findings: [MobileDataQualityIssue] = []
        if run.frames.isEmpty { findings.append(.noFrames) }
        if run.frames.count >= 3 && run.frames.contains(where: { $0.lambda == nil }) { findings.append(.missingLambda) }
        if run.frames.contains(where: { !$0.loadKPa.isFinite || $0.loadKPa < 0 || $0.loadKPa > 300 }) {
            findings.append(.criticalValueOutOfRange)
        }
        if run.frames.count >= 2 && Self.hasGap(run.frames, expectedIntervalSeconds: expectedIntervalSeconds) {
            findings.append(.timestampGap)
        }
        issues = findings
        qualityScore = Self.score(frameCount: frameCount, coveragePercent: coveragePercent, issues: findings)
    }

    private static func stats(_ values: [Double]) -> MobileSignalStats? {
        values.isEmpty ? nil : MobileSignalStats(values: values)
    }

    private static func duration(of frames: [MobileTelemetryFrame]) -> Double {
        guard let first = frames.first, let last = frames.last else { return 0 }
        return max(0, last.timestamp.timeIntervalSince(first.timestamp))
    }

    private static func hasGap(_ frames: [MobileTelemetryFrame], expectedIntervalSeconds: Double) -> Bool {
        zip(frames, frames.dropFirst()).contains { pair in
            pair.1.timestamp.timeIntervalSince(pair.0.timestamp) > expectedIntervalSeconds * 3
        }
    }

    private static func coverage(of frames: [MobileTelemetryFrame], expectedIntervalSeconds: Double) -> Double {
        guard frames.count > 1 else { return frames.isEmpty ? 0 : 100 }
        let duration = Self.duration(of: frames)
        guard duration > 0 else { return 100 }
        let expected = max(1, Int((duration / expectedIntervalSeconds).rounded()) + 1)
        return min(100, Double(frames.count) / Double(expected) * 100)
    }

    private static func score(frameCount: Int, coveragePercent: Double, issues: [MobileDataQualityIssue]) -> Int {
        guard frameCount > 0 else { return 0 }
        let penalty = issues.reduce(0) { $0 + ($1 == .criticalValueOutOfRange ? 35 : 12) }
        return max(0, min(100, Int(coveragePercent.rounded()) - penalty + (frameCount >= 3 ? 5 : 0)))
    }
}

public struct MobileRunComparison: Codable, Equatable, Sendable {
    public let baselineID: UUID
    public let candidateID: UUID
    public let repeatID: UUID?
    public let baselineLambdaError: Double?
    public let candidateLambdaError: Double?
    public let repeatLambdaError: Double?
    public let improvementPercent: Double?
    public let repeatDelta: Double?
    public let repeatable: Bool?
    public let decision: Decision

    public enum Decision: String, Codable, Equatable, Sendable {
        case insufficientData
        case repeatRequired
        case improvementConfirmed
        case regression
    }

    public init(baseline: MobileRunRecord, candidate: MobileRunRecord, repeatRun: MobileRunRecord? = nil,
                targetLambda: Double = 1.0, tolerance: Double = 0.02) {
        baselineID = baseline.id
        candidateID = candidate.id
        repeatID = repeatRun?.id
        baselineLambdaError = Self.lambdaError(baseline, target: targetLambda)
        candidateLambdaError = Self.lambdaError(candidate, target: targetLambda)
        repeatLambdaError = repeatRun.flatMap { Self.lambdaError($0, target: targetLambda) }

        guard let base = baselineLambdaError, let candidateError = candidateLambdaError, base > 0 else {
            improvementPercent = nil
            repeatDelta = nil
            repeatable = nil
            decision = .insufficientData
            return
        }

        improvementPercent = max(0, (base - candidateError) / base * 100)
        guard let repeatError = repeatLambdaError else {
            repeatDelta = nil
            repeatable = nil
            decision = candidateError < base ? .repeatRequired : .regression
            return
        }

        repeatDelta = abs(repeatError - candidateError)
        repeatable = repeatDelta! <= tolerance
        if candidateError >= base { decision = .regression }
        else if repeatable! { decision = .improvementConfirmed }
        else { decision = .repeatRequired }
    }

    private static func lambdaError(_ run: MobileRunRecord, target: Double) -> Double? {
        let values = run.frames.compactMap(\.lambda)
        guard !values.isEmpty else { return nil }
        return values.reduce(0) { $0 + abs($1 - target) } / Double(values.count)
    }
}

/// Local-first persistence for baseline/candidate/repeat records.
public actor MobileRunStore {
    public let directory: URL
    private let fileManager: FileManager

    public init(directory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.directory = directory ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AhhPuck/Runs", isDirectory: true)
    }

    @discardableResult
    public func save(_ run: MobileRunRecord) throws -> URL {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        // Milliseconds are required for frame-gap and coverage analysis.
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let url = directory.appendingPathComponent("run-\(run.id.uuidString).json")
        try encoder.encode(run).write(to: url, options: .atomic)
        return url
    }

    public func loadAll() throws -> [MobileRunRecord] {
        guard fileManager.fileExists(atPath: directory.path) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(MobileRunRecord.self, from: Data(contentsOf: $0)) }
            .sorted { $0.createdAt > $1.createdAt }
    }
}
