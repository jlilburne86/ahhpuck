import XCTest
@testable import FreedomCore

final class FreedomCoreTests: XCTestCase {
    func testRecoveredSettings() throws {
        let settings = FCSTSettings()
        XCTAssertEqual(settings.learningRate, 40)
        XCTAssertEqual(settings.switchThresholdRPM, 740)
        XCTAssertEqual(settings.latency, 0)
        XCTAssertEqual(settings.stableGain, 0.03)
        XCTAssertEqual(settings.accelerationStableGain, 0.8)
    }

    func testWriteIsBlockedInReadOnlyMode() throws {
        let transport = DarwinSerialTransport(configuration: .init(path: "/dev/does-not-exist", baud: 9600))
        XCTAssertThrowsError(try transport.send([0x00], mode: .readOnly)) { error in
            XCTAssertTrue(error is FreedomError)
        }
    }

    func testLiveMonitorAbortsOnKnock() {
        let monitor = LiveSafetyMonitor()
        monitor.arm()
        XCTAssertTrue(monitor.start())
        let alerts = monitor.ingest(.init(rpm: 5000, loadKPa: 95, lambda: 0.88,
                                          oilPressureKPa: 350, voltageV: 13.8, knockLevel: 0.2))
        XCTAssertTrue(alerts.contains { $0.code == "knock" })
        XCTAssertEqual(monitor.state, .aborted)
    }

    func testLiveMonitorWatchdogAborts() {
        var limits = LiveSafetyLimits()
        limits.watchdogSeconds = 0.1
        let monitor = LiveSafetyMonitor(limits: limits)
        monitor.arm()
        XCTAssertTrue(monitor.start())
        let old = Date(timeIntervalSinceNow: -1)
        _ = monitor.ingest(.init(timestamp: old, rpm: 1000, loadKPa: 20))
        XCTAssertEqual(monitor.watchdog()?.code, "telemetry_timeout")
    }
}
