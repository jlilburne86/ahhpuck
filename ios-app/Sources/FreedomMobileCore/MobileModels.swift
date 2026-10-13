import Foundation

public enum MobileTransportState: String, Sendable {
    case disconnected, connected, readOnlyVerified, fault
}

public struct MobileDashboardSnapshot: Sendable, Equatable {
    public var transport: MobileTransportState = .disconnected
    public var telemetryAgeMs: Int = 0
    public var rpm: Double?
    public var loadKPa: Double?
    public var lambda: Double?
    public var coolantC: Double?
    public var intakeAirC: Double?
    public var oilPressureKPa: Double?
    public var fuelPressureKPa: Double?
    public var batteryV: Double?
    public var knockLevel: Double?
    public var activeCell: String?
    public var protectionState: String = "unknown"
    public var writeAuthorization: String = "never"
    public var readiness: MobileReadinessAssessment = MobileReadinessAssessor.assess(.init())

    public init() {}
}

public struct MobileTelemetryFrame: Sendable, Equatable, Codable {
    public let timestamp: Date
    public let sequence: Int?
    public let rpm: Double
    public let loadKPa: Double
    public let lambda: Double?
    public let coolantC: Double?
    public let intakeAirC: Double?
    public let oilPressureKPa: Double?
    public let fuelPressureKPa: Double?
    public let batteryV: Double?
    public let knockLevel: Double?

    public init(timestamp: Date = Date(), sequence: Int? = nil, rpm: Double, loadKPa: Double,
                lambda: Double? = nil, coolantC: Double? = nil,
                intakeAirC: Double? = nil, oilPressureKPa: Double? = nil,
                fuelPressureKPa: Double? = nil, batteryV: Double? = nil,
                knockLevel: Double? = nil) {
        self.timestamp = timestamp; self.sequence = sequence; self.rpm = rpm; self.loadKPa = loadKPa
        self.lambda = lambda; self.coolantC = coolantC
        self.intakeAirC = intakeAirC; self.oilPressureKPa = oilPressureKPa
        self.fuelPressureKPa = fuelPressureKPa; self.batteryV = batteryV
        self.knockLevel = knockLevel
    }
}

public enum MobileEvidenceSource: String, Codable, Sendable {
    case none
    case localReplay
    case ecuReadOnly

    public var badge: String {
        switch self {
        case .none: return "NO DATA"
        case .localReplay: return "LOCAL REPLAY · NO ECU"
        case .ecuReadOnly: return "READ-ONLY ECU"
        }
    }
}

public enum MobileCoverageState: String, Codable, Sendable {
    case unvisited, observed, incomplete, protectionEvent
}

public struct MobileCoverageCell: Equatable, Codable, Sendable, Identifiable {
    public let id: String
    public let rpmBand: Int
    public let loadBand: Int
    public let frameCount: Int
    public let state: MobileCoverageState

    public init(rpmBand: Int, loadBand: Int, frameCount: Int, state: MobileCoverageState) {
        self.rpmBand = rpmBand
        self.loadBand = loadBand
        self.frameCount = frameCount
        self.state = state
        self.id = "\(rpmBand)-\(loadBand)"
    }
}

public struct MobileComparisonPoint: Equatable, Codable, Sendable, Identifiable {
    public let id: Int
    public let rpm: Double
    public let baselineLambda: Double?
    public let candidateLambda: Double?
    public let repeatLambda: Double?

    public init(id: Int, rpm: Double, baselineLambda: Double?, candidateLambda: Double?, repeatLambda: Double?) {
        self.id = id; self.rpm = rpm; self.baselineLambda = baselineLambda
        self.candidateLambda = candidateLambda; self.repeatLambda = repeatLambda
    }
}

public enum MobileEvidenceAnalyzer {
    public static func coverage(frames: [MobileTelemetryFrame], rpmStep: Int = 500, loadStep: Int = 10) -> [MobileCoverageCell] {
        var counts: [String: (rpm: Int, load: Int, count: Int, protection: Bool, complete: Bool)] = [:]
        for frame in frames {
            let rpm = Int(frame.rpm / Double(rpmStep)) * rpmStep
            let load = Int(frame.loadKPa / Double(loadStep)) * loadStep
            let key = "\(rpm)-\(load)"
            var value = counts[key] ?? (rpm, load, 0, false, true)
            value.count += 1
            value.protection = value.protection || (frame.knockLevel ?? 0) > 0.15
            counts[key] = value
        }
        return counts.values.sorted { ($0.rpm, $0.load) < ($1.rpm, $1.load) }.map {
            MobileCoverageCell(rpmBand: $0.rpm, loadBand: $0.load, frameCount: $0.count,
                               state: $0.protection ? .protectionEvent : ($0.complete ? .observed : .incomplete))
        }
    }

    public static func comparison(baseline: [MobileTelemetryFrame], candidate: [MobileTelemetryFrame], repeatRun: [MobileTelemetryFrame]) -> [MobileComparisonPoint] {
        let count = max(baseline.count, candidate.count, repeatRun.count)
        return (0..<count).map { index in
            MobileComparisonPoint(id: index,
                                  rpm: baseline[safe: index]?.rpm ?? candidate[safe: index]?.rpm ?? repeatRun[safe: index]?.rpm ?? 0,
                                  baselineLambda: baseline[safe: index]?.lambda,
                                  candidateLambda: candidate[safe: index]?.lambda,
                                  repeatLambda: repeatRun[safe: index]?.lambda)
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}

public enum MobileTransportError: Error, LocalizedError, Sendable, Equatable {
    case protocolNotVerified
    case usbAccessoryUnavailable
    case writesDisabled

    public var errorDescription: String? {
        switch self {
        case .protocolNotVerified: return "FC-03 protocol is not verified for this ECU profile."
        case .usbAccessoryUnavailable: return "No supported iOS USB accessory transport is available."
        case .writesDisabled: return "ECU writes are disabled in the iOS-first build."
        }
    }
}

public protocol MobileECUTransport: Sendable {
    func connect() async throws
    func disconnect() async
    func readOnlyIdentity() async throws -> String
    func frames() -> AsyncThrowingStream<MobileTelemetryFrame, Error>
}

/// A deterministic replay transport for fixture and captured-session review.
/// It deliberately has no write operation and never claims ECU identity.
public struct MobileReplayTransport: MobileECUTransport, Sendable {
    private let replayFrames: [MobileTelemetryFrame]

    public init(frames: [MobileTelemetryFrame]) {
        self.replayFrames = frames
    }

    public func connect() async throws {}
    public func disconnect() async {}
    public func readOnlyIdentity() async throws -> String { "LOCAL REPLAY · NO ECU" }
    public func frames() -> AsyncThrowingStream<MobileTelemetryFrame, Error> {
        AsyncThrowingStream { continuation in
            for frame in replayFrames { continuation.yield(frame) }
            continuation.finish()
        }
    }
}

/// Placeholder until the exact USB bridge and FC-03 frame protocol are proven.
/// It deliberately exposes no write method.
public struct IOSUSBTransport: MobileECUTransport, Sendable {
    public init() {}

    public func connect() async throws { throw MobileTransportError.usbAccessoryUnavailable }
    public func disconnect() async {}
    public func readOnlyIdentity() async throws -> String { throw MobileTransportError.protocolNotVerified }
    public func frames() -> AsyncThrowingStream<MobileTelemetryFrame, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: MobileTransportError.protocolNotVerified)
        }
    }
}
