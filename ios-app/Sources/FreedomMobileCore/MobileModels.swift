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
