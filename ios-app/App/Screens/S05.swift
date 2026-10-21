import SwiftUI

/// S05 · Preflight checklist
struct S05View: View {
    @Environment(AppModel.self) private var app

    private let auto: [(String, String, Status)] = [
        ("Coolant ≥ 75 °C", "86 °C", .ok), ("Battery 12.5–14.8 V", "13.8 V", .ok), ("Oil pressure at idle", "1.9 bar", .ok),
        ("Lambda sensor switching", "yes", .ok), ("Frame rate", "31 Hz", .ok), ("Fuel pressure", "not measurable", .none),
    ]
    private let man: [(String, String)] = [
        ("fuel", "Fuel level and type confirmed"), ("tyres", "Tyres and brakes checked"),
        ("route", "Dyno or closed course clear"), ("observer", "Observer present"),
    ]

    var body: some View {
        let left = man.filter { app.pf[$0.0] != true }.count
        PhoneScreen(tab: nil) {
            AHeader(title: "Preflight", sub: app.tr("BASELINE 03 · AUTO + MANUAL"))
            M("AUTOMATIC", .mono, 10, color: AP.label).block(top: 12)
            MList {
                ForEach(auto, id: \.0) { label, v, st in
                    HStack(spacing: 10) {
                        T(st.glyph, .sans, 11, 700).apFont(.sans, 11, 700).foregroundStyle(AP.ink)
                            .frame(width: 18, height: 18)
                            .background(RoundedRectangle(cornerRadius: 5).fill(st == .none ? AP.faint : st.color))
                        M(label, .sans, 13).frame(maxWidth: .infinity, alignment: .leading)
                        M(v, .mono, 12, color: AP.text2)
                    }
                    .mRow()
                }
            }
            .block()
            M("CONFIRM BY HAND", .mono, 10, color: AP.label).block(top: 14)
            MList {
                ForEach(man, id: \.0) { k, label in
                    HStack(spacing: 12) {
                        ATick(on: app.pf[k] == true, size: 22, radius: 6, fontSize: 14)
                        M(label, .sans, 13, lineHeight: 1.35).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .mRow(11, 12)
                    .contentShape(Rectangle())
                    .onTapGesture { app.pf[k] = !(app.pf[k] ?? false) }
                }
            }
            .block()
            M("Fuel pressure isn't measured. That lowers confidence but doesn't block the run.", .sans, 12, color: AP.label, lineHeight: 1.45)
                .block()
            Spacer(minLength: 16)
            MButton(label: left > 0 ? "\(left) manual check\(left > 1 ? "s" : "") left" : "Start recording",
                    bg: left > 0 ? AP.disabled : AP.text, fg: left > 0 ? AP.faint : AP.ink, bottom: 28) {
                if left == 0 {
                    app.rec = true; app.recStart = app.t
                    app.router.go(.S11)
                } else {
                    app.router.go(.S41)
                }
            }
        }
    }
}
