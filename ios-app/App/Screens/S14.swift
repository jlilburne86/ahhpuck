import SwiftUI

/// S14 · Notifications & Live Activity — the lock-screen Live Activity and the four notification types.
struct S14View: View {
    @Environment(AppModel.self) private var app

    private let notifs: [(app: String, time: String, title: String, body: String, c: Color, a1: String, a2: String, go1: ScreenID?, go2: ScreenID?)] = [
        ("AHHPUCK · CRITICAL", "now", "Lean under load. Stop the run.", "λ 1.08 at 82% load, 5,900 rpm. Tuning is locked.", AP.red, "Open alert", "Log investigation", .S12, .S13),
        ("AHHPUCK", "2m ago", "Assessment ready · EXP-04", "Repeat recommended: repeatability not proven.", AP.amber, "Review", "Explain", .S22, .S26),
        ("AHHPUCK", "14m ago", "Telemetry gap 1.2 s", "Run 03 kept. The gap is marked in the overlay.", Color(hex: 0x5a5f64), "Open run", "Dismiss", .S19, nil),
        ("AHHPUCK", "1h ago", "Preflight waiting", "Coolant 68 °C. Warm up to 75 °C before recording.", Color(hex: 0x5a5f64), "Open preflight", "Snooze", .S05, nil),
    ]

    var body: some View {
        let b = app.base
        let el = app.rec ? app.t - app.recStart : app.recEl
        let secs = Double(el) * 0.14
        let clock = String(format: "%02d:%02d", Int(secs / 60), Int(secs) % 60)
        let filled = min(10, Int(secs / 2.5))

        PhoneScreen(tab: nil, background: Color(hex: 0x0e1012)) {
            VStack(spacing: 0) {
                M("Tuesday 13 October", .sans, 16, color: AP.text2)
                Clock().font(APFont.font(.sans, 84, 600)).apFont(.sans, 84, 600, lineHeight: 1).apTracking(-0.02, size: 84)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 14).padding(.bottom, 6)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(AP.red).frame(width: 8, height: 8)
                        M("AHHPUCK · RECORDING", .mono, 11)
                    }
                    Spacer()
                    M(clock, .mono, 13, translate: false)
                }
                HStack(alignment: .bottom) {
                    (T(b.rpm, .barlow, 40, 600) + T(" " + app.tr("rpm"), .barlow, 16, 600).foregroundColor(AP.label))
                        .apFont(.barlow, 40, 600, lineHeight: 0.9)
                    Spacer()
                    M(b.lamErr, .barlow, 28, 600, color: b.lamColor, translate: false)
                }
                HStack(spacing: 2) {
                    ForEach(0..<10, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2).fill(i < filled ? AP.text : AP.disabled).frame(height: 6)
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 22).fill(Color(hex: 0x1c1e21)))
            .padding(.horizontal, 14).padding(.top, 10)
            .onTapGesture { app.router.go(.S11) }

            VStack(spacing: 8) {
                ForEach(Array(notifs.enumerated()), id: \.offset) { i, n in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 6).fill(n.c).frame(width: 20, height: 20)
                                M(n.app, .sans, 12, color: AP.text2).apTracking(0.02, size: 12)
                            }
                            Spacer()
                            M(n.time, .sans, 12, color: AP.label)
                        }
                        M(n.title, .sans, 14, 600)
                        M(n.body, .sans, 13, color: AP.text2, lineHeight: 1.4)
                        if app.nOpen == i {
                            HStack(spacing: 6) {
                                action(n.a1, n.go1)
                                action(n.a2, n.go2)
                            }
                            .padding(.top, 6)
                        }
                    }
                    .padding(.vertical, 12).padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(red: 40 / 255, green: 43 / 255, blue: 47 / 255, opacity: 0.92)))
                    .contentShape(Rectangle())
                    .onTapGesture { app.nOpen = app.nOpen == i ? -1 : i }
                }
            }
            .padding(.horizontal, 14).padding(.top, 10)
            Spacer(minLength: 0)
        }
    }

    private func action(_ label: String, _ go: ScreenID?) -> some View {
        M(label, .sans, 13)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 10).fill(AP.hatchA))
            .contentShape(Rectangle())
            .onTapGesture { if let go { app.router.go(go) } else { app.nOpen = -1 } }
    }
}
