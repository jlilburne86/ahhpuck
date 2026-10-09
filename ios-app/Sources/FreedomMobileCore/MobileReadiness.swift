import Foundation

/// The small set of evidence gates shown to the user. The backend keeps the
/// detailed provenance; the UI only needs to know whether the next action is
/// safe, paused, or stopped.
public struct MobileReadinessEvidence: Codable, Equatable, Sendable {
    public var ecuIdentityVerified = false
    public var protocolVerified = false
    public var originalMapBackup = false
    public var engineProfileVerified = false
    public var injectorDataVerified = false
    public var fuelPressureVerified = false
    public var widebandCalibrated = false
    public var ignitionOffsetVerified = false
    public var sensorPlausibilityPassed = false
    public var protectionConfigured = false
    public var repeatableLogEvidence = false

    public init() {}
}

public enum MobileReadinessState: String, Codable, Sendable {
    case readyForLowLoadTest
    case paused
    case stop
}

public struct MobileReadinessAssessment: Codable, Equatable, Sendable {
    public let state: MobileReadinessState
    public let title: String
    public let explanation: String
    public let missingEvidence: [String]
    public let nextAction: String
    public let criticalReasons: [String]
    public let writeAuthorization: String

    public var canTest: Bool { state == .readyForLowLoadTest }

    public init(state: MobileReadinessState, title: String, explanation: String,
                missingEvidence: [String], nextAction: String,
                criticalReasons: [String] = [], writeAuthorization: String = "never") {
        self.state = state
        self.title = title
        self.explanation = explanation
        self.missingEvidence = missingEvidence
        self.nextAction = nextAction
        self.criticalReasons = criticalReasons
        self.writeAuthorization = writeAuthorization
    }
}

public enum MobileReadinessAssessor {
    public static func assess(_ evidence: MobileReadinessEvidence,
                              criticalReasons: [String] = []) -> MobileReadinessAssessment {
        if !criticalReasons.isEmpty {
            return .init(
                state: .stop,
                title: "Stop and investigate",
                explanation: "A protection or data-integrity fault makes the current evidence unsafe for testing.",
                missingEvidence: [],
                nextAction: "Remove load, preserve the capture, and investigate the listed fault before another run.",
                criticalReasons: criticalReasons
            )
        }

        let missing: [(String, Bool, String)] = [
            ("ECU identity", evidence.ecuIdentityVerified, "Verify the FC-03 identity and option configuration."),
            ("FC-03 protocol", evidence.protocolVerified, "Confirm the serial framing and read-only protocol."),
            ("Original map backup", evidence.originalMapBackup, "Save and hash an immutable original calibration backup."),
            ("Engine profile", evidence.engineProfileVerified, "Confirm engine code, hardware, fuel, ignition, and modifications."),
            ("Injector data", evidence.injectorDataVerified, "Verify injector flow and compensation data."),
            ("Fuel pressure", evidence.fuelPressureVerified, "Measure differential fuel pressure under the intended test condition."),
            ("Wideband calibration", evidence.widebandCalibrated, "Verify the lambda sensor, controller, wiring, and calibration."),
            ("Ignition reference", evidence.ignitionOffsetVerified, "Verify commanded versus physical ignition timing."),
            ("Sensor plausibility", evidence.sensorPlausibilityPassed, "Compare critical sensors against independent references."),
            ("Protection setup", evidence.protectionConfigured, "Configure and function-test ECU protection on the actual vehicle."),
            ("Repeatable baseline", evidence.repeatableLogEvidence, "Capture a repeatable healthy baseline with synchronized channels.")
        ]
        let unresolved = missing.filter { !$0.1 }
        guard let first = unresolved.first else {
            return .init(
                state: .readyForLowLoadTest,
                title: "Ready for a low-load test",
                explanation: "Required identity, calibration, sensor, protection, and baseline evidence is present.",
                missingEvidence: [],
                nextAction: "Run one bounded test and stop if any protection or data-quality alert appears."
            )
        }

        return .init(
            state: .paused,
            title: "Optimization paused",
            explanation: "The current evidence is insufficient to distinguish a calibration issue from a hardware or sensor issue.",
            missingEvidence: unresolved.map { $0.0 },
            nextAction: first.2
        )
    }
}
