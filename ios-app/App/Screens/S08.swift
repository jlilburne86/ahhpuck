import SwiftUI

/// S08 · Sensor health. FAULT (hatched, struck through, excluded) is distinct from STOP (a real reading past a limit).
struct S08View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let b = app.base
        let sens: [(n: String, v: String, u: String, st: Int, note: String, range: String)] = [
            ("Coolant", "98", "°C", 1, "A real reading above the normal band. Still under the 105 °C stop limit.", "NORMAL 75–100 · STOP 105"),
            ("Intake air temp", "−40", "°C", 3, "Pinned at the bottom of the sensor range for 42 s. That points to an open circuit, not cold air. It's excluded from assessment, and IAT checks show UNKNOWN until it's fixed.", "PLAUSIBLE −10 TO 80 · READING −40"),
            ("Battery", "11.6", "V", 2, "A real reading below the 12.0 V stop limit. A charging fault is likely. Stop and investigate.", "NORMAL 12.5–14.8 · STOP 12.0"),
            ("Oil pressure", "3.8", "bar", 0, "Within the band for this RPM.", "NORMAL 1.5–6.0 · STOP 1.0"),
            (b.lamLabel == "AFR" ? "AFR" : "Lambda", b.lamVal, "", 0, "The sensor is switching and tracking target.", "TARGET " + b.lamTarget),
            ("Knock", "0", "events", 0, "No knock events this session.", "STOP ON ANY EVENT"),
            ("Fuel pressure", "—", "", 4, "No sensor fitted. Shown as not measured, never as OK.", "NOT FITTED"),
        ]
        let cs = sens[app.sens], cd = BStDef.all[cs.st]

        PhoneScreen(tab: .live) {
            AHeader(title: "Sensors", sub: app.tr("TAP A SENSOR"))

            MList {
                ForEach(Array(sens.enumerated()), id: \.offset) { i, x in
                    let d = BStDef.all[x.st]
                    let valC = x.st >= 3 ? AP.faint : x.st == 1 ? AP.amber : x.st == 2 ? AP.red : AP.text
                    HStack(spacing: 10) {
                        M(x.n, .sans, 13).frame(maxWidth: .infinity, alignment: .leading)
                        M(app.tr(x.v) + " " + app.tr(x.u), .mono, 13, color: valC, translate: false)
                            .strikethrough(x.st == 3, color: valC)
                            .lineLimit(1).fixedSize()
                        chip(d, size: 9).frame(width: 76)
                    }
                    .padding(.vertical, 11).padding(.horizontal, 12)
                    .background(i == app.sens ? AP.selectedRow : .clear)
                    .overlay(alignment: .bottom) { Rectangle().fill(AP.divider).frame(height: 1) }
                    .padding(.bottom, 1)
                    .contentShape(Rectangle())
                    .onTapGesture { app.sens = i }
                }
            }
            .block(top: 12)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    M(cs.n, .barlow, 22, 600)
                    Spacer()
                    chip(cd, size: 10, h: 7)
                }
                M(cs.note, .sans, 13, color: AP.text2, lineHeight: 1.5)
                M(cs.range, .mono, 10, color: AP.label)
            }
            .apCard()
            .block()

            M("A fault means the sensor can't be trusted, so it's never shown as red or green. STOP means a real reading crossed a limit.", .sans, 12, color: AP.label, lineHeight: 1.45)
                .block()
            Spacer(minLength: 0)
        }
    }

    /// `padding:3px 6px; r4; border 1px #2f3336; mono 600`.
    private func chip(_ d: BStDef, size: CGFloat, h: CGFloat = 6) -> some View {
        M(d.l, .mono, size, 600, color: d.fg)
            .lineLimit(1)
            .padding(.vertical, 4).padding(.horizontal, h + 1)
            .frame(maxWidth: h == 6 ? .infinity : nil)
            .background {
                if d.hatched { Hatch().clipShape(RoundedRectangle(cornerRadius: 4)) }
                else { RoundedRectangle(cornerRadius: 4).fill(d.bg) }
            }
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(AP.control, lineWidth: 1))
    }
}
