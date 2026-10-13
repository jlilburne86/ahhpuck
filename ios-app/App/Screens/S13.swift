import SwiftUI

/// S13 · Investigation log. Cause, then at least 2 checks, then sign. "Unknown" keeps tuning locked.
struct S13View: View {
    @Environment(AppModel.self) private var app

    private let causes = ["Fuel supply", "Sensor / wiring", "Map error", "Vacuum leak", "Unknown"]
    private let acts = ["Reviewed the trace in the overlay", "Checked fuel pump and pressure", "Checked lambda sensor and wiring", "Inspected intake for leaks"]

    var body: some View {
        let b = app.base, t = Double(app.t), afr = app.units == .afr
        let lam = afr ? jsFixed((1.08 + sin(t / 2) * 0.01) * 14.7, 1) : jsFixed(1.08 + sin(t / 2) * 0.01, 2)
        let signed = app.invSigned, cause = app.invCause
        let nAct = acts.indices.filter { app.invAct["\($0)"] == true }.count
        let canInv = cause != nil && cause != "Unknown" && nAct >= 2
        let note = signed ? "Next experiment must start with a fresh baseline."
            : cause == "Unknown" ? "An unknown cause keeps tuning locked. Record a baseline repeat to gather evidence first."
            : cause == nil ? "Choose a likely cause." : nAct < 2 ? "Tick at least 2 checks (\(nAct)/2)." : "Ready to sign."
        let btnOn = signed || canInv

        PhoneScreen(tab: .review) {
            AHeader(title: "Investigation", sub: app.tr("EVT-0413-01 · FROM ALERT S12"))

            M(signed ? "✓ INV-07 logged · tuning unlocked" : "✕ Tuning locked · investigation required", .sans, 14, 600, color: signed ? AP.ink : .white)
                .padding(.vertical, 11).padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(signed ? AP.green : AP.red))
                .block(top: 12)

            VStack(alignment: .leading, spacing: 8) {
                M("EVENT", .mono, 10, color: AP.label)
                M("Lean under load", .barlow, 22, 600)
                M(b.lamLabel + " " + lam + app.tr(" · 82% LOAD · 5,900 RPM · 3.2 S"), .mono, 11, color: AP.text3, translate: false)
                M("↗ Overlay at 01:42 · ↗ Map cell 6k/80%", .mono, 10, color: AP.text2)
                    .contentShape(Rectangle())
                    .onTapGesture { app.router.go(.S19) }
            }
            .apCard()
            .block()

            VStack(alignment: .leading, spacing: 8) {
                M("LIKELY CAUSE", .mono, 10, color: AP.label)
                DFlow(spacing: 6, lineSpacing: 6) {
                    ForEach(causes, id: \.self) { x in
                        MChip(label: x, on: cause == x, size: 13, v: 7, h: 11) { if !app.invSigned { app.invCause = x } }
                    }
                }
            }
            .apCard()
            .block()

            M("CHECKS DONE · AT LEAST 2", .mono, 10, color: AP.label).block(top: 12)
            MList {
                ForEach(Array(acts.enumerated()), id: \.offset) { i, l in
                    HStack(spacing: 12) {
                        ATick(on: app.invAct["\(i)"] == true, size: 22, radius: 6, fontSize: 14)
                        M(l, .sans, 13, lineHeight: 1.35).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .mRow(8, 12)
                    .contentShape(Rectangle())
                    .onTapGesture { if !app.invSigned { app.invAct["\(i)"] = !(app.invAct["\(i)"] ?? false) } }
                }
            }
            .block(top: 6)

            M(note, .sans, 12, color: cause == "Unknown" && !signed ? AP.amber : AP.text3, lineHeight: 1.4).block(top: 6)

            Spacer(minLength: 16)
            M(signed ? "Reset demo" : "Sign and unlock tuning", .sans, 15, 600, color: btnOn ? AP.ink : AP.faint)
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 14).fill(btnOn ? AP.text : AP.disabled))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AP.control, lineWidth: 1))
                .contentShape(Rectangle())
                .onTapGesture {
                    if app.invSigned { app.invSigned = false; app.invCause = nil; app.invAct = [:] }
                    else if canInv { app.invSigned = true; app.alertAck = false; app.alertActive = false }
                    else { app.router.go(.S41) }
                }
                .padding(.horizontal, Metrics.gutter).padding(.bottom, 8)
        }
    }
}
