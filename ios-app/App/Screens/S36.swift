import SwiftUI

/// S36 · Hardware guide
struct S36View: View {
    @Environment(AppModel.self) private var app

    private struct Step { let t, b, ph: String; let items: [String]? }
    private let HW: [Step] = [
        Step(t: "What you need", b: "A USB-C serial adapter and the FC-03 serial lead. Charge-only cables won't work.", ph: "", items: ["USB-C to TTL serial adapter", "FC-03 serial lead from your install kit"]),
        Step(t: "Find the ECU serial port", b: "Use the FC-03 serial connector described in your install notes. Don't splice into the loom.", ph: "", items: ["Ignition off before you plug anything in", "Leave the ECU mounted; just reach the connector", "If you can't find it, ask your installer"]),
        Step(t: "Plug in and power up", b: "Connect the lead to the adapter and the adapter to the phone. Turn the ignition on and leave the engine off.", ph: "", items: ["Ignition ON, engine OFF", "Keep the cable clear of the pedals and steering column", "Do this with the vehicle stationary"]),
        Step(t: "First-connect check", b: "AhhPuck checks each step and tells you exactly where it stopped.", ph: "", items: nil),
    ]

    var body: some View {
        let hw = HW[app.hw]
        PhoneScreen(tab: nil) {
            AHeader(title: "Connect your ECU",
                    sub: [app.tr("STEP "), String(app.hw + 1), app.tr(" OF 4")].joined())

            AStepPills(labels: ["Cable", "Port", "Plug in", "Check"], cur: app.hw) { app.hw = $0 }
                .block(top: 12)


            VStack(alignment: .leading, spacing: 6) {
                T(app.tr(hw.t), .barlow, 28, 700)
                    .apFont(.barlow, 28, 700, lineHeight: 1)
                    .fixedSize(horizontal: false, vertical: true)
                ASans(text: hw.b, size: 13, color: AP.text3, lineHeight: 1.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.top, 14)

            AList {
                if let items = hw.items {
                    ForEach(items, id: \.self) { x in
                        ACheckRow(glyph: "·", fill: AP.disabled, glyphColor: AP.label, text: x, st: "")
                    }
                } else {
                    ForEach(Array(AConn.steps.enumerated()), id: \.offset) { i, x in
                        let c = i < app.conn ? AP.green : i == app.conn ? AP.amber : AP.disabled
                        let g = AGlyph.of(c)
                        ACheckRow(glyph: g.0, fill: c, glyphColor: g.1, text: x,
                                  st: i < app.conn ? "OK" : i == app.conn ? "…" : "")
                    }
                }
            }
            .block()

            Spacer(minLength: 0)

            ABackNext(next: app.hw < 3 ? "Next" : "Continue", back: {
                if app.hw > 0 { app.hw -= 1 } else { app.router.back() }
            }, next: {
                if app.hw < 3 { app.hw += 1 }
                else if app.router.onboarding { app.router.nextInFirstRun(after: .S36) }
                else { app.router.back() }
            })
            .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 24)
        }
    }
}
