import Foundation

/// UI-facing controller for the iOS dashboard. It accepts only normalized,
/// read-only frames and delegates all protection decisions to the safety core.
public actor MobileDashboardController {
    public private(set) var snapshot = MobileDashboardSnapshot()
    private let monitor: LiveSafetyMonitorAdapter

    public init(monitor: LiveSafetyMonitorAdapter = .init()) {
        self.monitor = monitor
    }

    public func setReadOnlyVerified() {
        snapshot.transport = .readOnlyVerified
        snapshot.writeAuthorization = "never"
    }

    public func ingest(_ frame: MobileTelemetryFrame) {
        let alerts = monitor.evaluate(frame)
        snapshot.rpm = frame.rpm; snapshot.loadKPa = frame.loadKPa
        snapshot.lambda = frame.lambda; snapshot.coolantC = frame.coolantC
        snapshot.intakeAirC = frame.intakeAirC
        snapshot.oilPressureKPa = frame.oilPressureKPa
        snapshot.fuelPressureKPa = frame.fuelPressureKPa
        snapshot.batteryV = frame.batteryV; snapshot.knockLevel = frame.knockLevel
        snapshot.telemetryAgeMs = 0
        snapshot.protectionState = alerts.isEmpty ? "healthy" : "aborted"
    }
}

public struct LiveSafetyMonitorAdapter: Sendable {
    public var maxRPM: Double = 7800
    public var maxCoolantC: Double = 105
    public var maxKnockLevel: Double = 0.15
    public var maxLambdaUnderLoad: Double = 1.05

    public init() {}

    public func evaluate(_ frame: MobileTelemetryFrame) -> [String] {
        var alerts: [String] = []
        if frame.rpm > maxRPM { alerts.append("rpm_limit") }
        if let value = frame.coolantC, value >= maxCoolantC { alerts.append("coolant_high") }
        if let value = frame.knockLevel, value > maxKnockLevel { alerts.append("knock") }
        if frame.loadKPa >= 80, let value = frame.lambda, value > maxLambdaUnderLoad { alerts.append("lambda_lean") }
        return alerts
    }
}
