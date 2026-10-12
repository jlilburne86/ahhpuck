import Foundation

/// Live telemetry consumed by the monitor. Values are normalized before entry;
/// the monitor does not guess units or decode unknown FC-03 frames.
public struct LiveTelemetry: Sendable, Equatable {
    public let timestamp: Date
    public let rpm: Double
    public let loadKPa: Double
    public let lambda: Double?
    public let coolantC: Double?
    public let intakeAirC: Double?
    public let oilPressureKPa: Double?
    public let fuelPressureKPa: Double?
    public let voltageV: Double?
    public let knockLevel: Double?

    public init(timestamp: Date = Date(), rpm: Double, loadKPa: Double,
                lambda: Double? = nil, coolantC: Double? = nil,
                intakeAirC: Double? = nil, oilPressureKPa: Double? = nil,
                fuelPressureKPa: Double? = nil, voltageV: Double? = nil,
                knockLevel: Double? = nil) {
        self.timestamp = timestamp
        self.rpm = rpm
        self.loadKPa = loadKPa
        self.lambda = lambda
        self.coolantC = coolantC
        self.intakeAirC = intakeAirC
        self.oilPressureKPa = oilPressureKPa
        self.fuelPressureKPa = fuelPressureKPa
        self.voltageV = voltageV
        self.knockLevel = knockLevel
    }
}

public struct LiveSafetyLimits: Sendable, Equatable {
    public var maxRPM: Double = 7800
    public var maxCoolantC: Double = 105
    public var maxIntakeAirC: Double = 65
    public var minVoltageV: Double = 12
    public var minOilPressureKPaUnderLoad: Double = 180
    public var maxKnockLevel: Double = 0.15
    public var maxLambdaUnderLoad: Double = 1.05
    public var watchdogSeconds: TimeInterval = 0.5

    public init() {}
}

public enum LiveSafetySeverity: String, Sendable { case warning, critical }

public struct LiveSafetyAlert: Sendable, Equatable {
    public let timestamp: Date
    public let code: String
    public let message: String
    public let severity: LiveSafetySeverity

    public init(timestamp: Date = Date(), code: String, message: String,
                severity: LiveSafetySeverity) {
        self.timestamp = timestamp
        self.code = code
        self.message = message
        self.severity = severity
    }
}

public enum LiveTestState: String, Sendable { case idle, armed, running, aborted, completed }

/// Software failsafe for a test session. It aborts the test and prevents any
/// proposal/write action; it cannot create an ECU limp mode by itself.
public final class LiveSafetyMonitor: @unchecked Sendable {
    private let lock = NSLock()
    public let limits: LiveSafetyLimits
    public private(set) var state: LiveTestState = .idle
    public private(set) var lastTelemetry: LiveTelemetry?
    public private(set) var alerts: [LiveSafetyAlert] = []
    /// When the test started; lets the watchdog fire even if no frame ever arrives.
    public private(set) var startedAt: Date?
    /// Channels already reported as unmonitored this test, so each is noted once.
    private var notedMissing: Set<String> = []

    public init(limits: LiveSafetyLimits = .init()) { self.limits = limits }

    public func arm() {
        lock.lock(); defer { lock.unlock() }
        guard state == .idle || state == .completed else { return }
        state = .armed
        alerts.removeAll(keepingCapacity: true)
        notedMissing.removeAll()
        startedAt = nil
        lastTelemetry = nil
    }

    public func start(now: Date = Date()) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard state == .armed else { return false }
        state = .running
        startedAt = now
        return true
    }

    @discardableResult
    public func ingest(_ sample: LiveTelemetry) -> [LiveSafetyAlert] {
        lock.lock(); defer { lock.unlock() }
        guard state == .running else { return [] }
        lastTelemetry = sample
        let generated = evaluate(sample)
        alerts.append(contentsOf: generated)
        if generated.contains(where: { $0.severity == .critical }) { state = .aborted }
        return generated
    }

    @discardableResult
    public func watchdog(now: Date = Date()) -> LiveSafetyAlert? {
        lock.lock(); defer { lock.unlock() }
        guard state == .running else { return nil }
        // Previously the watchdog needed one frame first, so a test started with a dead
        // link never timed out. Fall back to the start time when nothing has arrived.
        guard let reference = lastTelemetry?.timestamp ?? startedAt else { return nil }
        guard now.timeIntervalSince(reference) > limits.watchdogSeconds else { return nil }
        let alert = LiveSafetyAlert(timestamp: now, code: "telemetry_timeout",
                                    message: "Telemetry stream stopped; abort test and remove load.", severity: .critical)
        alerts.append(alert)
        state = .aborted
        return alert
    }

    public func complete() {
        lock.lock(); defer { lock.unlock() }
        if state == .running || state == .armed { state = .completed }
    }

    private func evaluate(_ sample: LiveTelemetry) -> [LiveSafetyAlert] {
        var result: [LiveSafetyAlert] = []
        func add(_ code: String, _ message: String) {
            result.append(.init(code: code, message: message, severity: .critical))
        }
        if sample.rpm > limits.maxRPM { add("rpm_limit", "RPM limit exceeded; remove load.") }
        if let value = sample.coolantC, value >= limits.maxCoolantC { add("coolant_high", "Coolant temperature limit exceeded.") }
        if let value = sample.intakeAirC, value >= limits.maxIntakeAirC { add("iat_high", "Intake-air temperature limit exceeded.") }
        if let value = sample.voltageV, value < limits.minVoltageV { add("voltage_low", "System voltage is below the test limit.") }
        if let value = sample.knockLevel, value > limits.maxKnockLevel { add("knock", "Knock threshold exceeded; remove load immediately.") }
        if sample.loadKPa >= 80, let value = sample.oilPressureKPa, value < limits.minOilPressureKPaUnderLoad {
            add("oil_pressure_low", "Oil pressure is low under load; abort test.")
        }
        if sample.loadKPa >= 80, let value = sample.lambda, value > limits.maxLambdaUnderLoad {
            add("lambda_lean", "Lambda is lean under load; abort test.")
        }
        // Unknown is not safe. A missing channel was previously skipped silently.
        // Lambda under load is required to continue; other gaps are named once as warnings
        // so the operator knows what is NOT being watched.
        if sample.loadKPa >= 80, sample.lambda == nil {
            add("lambda_unavailable_under_load", "No lambda reading under load; abort test until a wideband is logged.")
        }
        func noteMissing(_ code: String, _ message: String) {
            guard !notedMissing.contains(code) else { return }
            notedMissing.insert(code)
            result.append(.init(code: code, message: message, severity: .warning))
        }
        if sample.knockLevel == nil { noteMissing("knock_not_monitored", "Knock is not being monitored on this setup.") }
        if sample.oilPressureKPa == nil { noteMissing("oil_pressure_not_monitored", "Oil pressure is not being monitored on this setup.") }
        if sample.coolantC == nil { noteMissing("coolant_not_monitored", "Coolant temperature is not being monitored.") }
        if sample.voltageV == nil { noteMissing("voltage_not_monitored", "System voltage is not being monitored.") }
        return result
    }
}
