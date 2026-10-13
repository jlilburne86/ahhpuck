import SwiftUI

/// S10 · Run setup — conditions EDITABLE (baseline), FROM BASELINE (candidate) or LOCKED (repeat).
struct S10View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let rt = app.rType
        let lt = rt == "Repeat" ? "LOCKED" : rt == "Candidate" ? "FROM BASELINE" : "EDITABLE"
        let tc = rt == "Repeat" ? AP.text : rt == "Candidate" ? AP.text3 : AP.faint
        let fields: [(String, String)] = [("Objective", "Drivability"), ("Gear", "3rd"), ("RPM band", "2,500–7,000"), ("Load band", "40–100 %"),
                                          ("Context", "Route · Lakeside loop"), ("Fuel", "98 RON"), ("Ambient", "22 °C · 1012 hPa")]
        let ref = rt == "Baseline" ? "Creates a new baseline. It can never be edited." : rt == "Candidate" ? "Compared against Baseline 03 · sha 3f9a…c21e" : "Repeats Candidate 04 · sha 81d0…4b07"
        let note = rt == "Repeat" ? "Every condition must match the candidate. Any change is flagged in Review." : "Conditions are copied from the baseline so the comparison is fair."

        PhoneScreen(tab: .runs) {
            AHeader(title: "New run", sub: app.tr("EXPERIMENT 04"))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(["Baseline", "Candidate", "Repeat"], id: \.self) { x in
                    MChip(label: x, on: rt == x, size: 13, v: 7, h: 11, center: true) { app.rType = x }
                }
            }
            .block(top: 12)

            M(ref, .sans, 13, color: AP.text3).block()

            MList {
                ForEach(fields, id: \.0) { k, v in
                    HStack(spacing: 8) {
                        M(k, .sans, 12, color: AP.label).frame(width: 84, alignment: .leading)
                        M(v, .sans, 14).frame(maxWidth: .infinity, alignment: .leading)
                        M(lt, .mono, 9, color: tc)
                    }
                    .mRow(11, 12)
                }
            }
            .block()

            VStack(alignment: .leading, spacing: 8) {
                M("OPERATOR NOTES", .mono, 10, color: AP.label)
                M("Same loop as baseline. Two pulls, 3 min apart.", .sans, 13, color: AP.text2)
            }
            .apCard()
            .block()

            M(note, .sans, 12, color: AP.label, lineHeight: 1.45).block()

            Spacer(minLength: 16)
            MButton(label: "Continue to preflight", bottom: 28) { app.router.go(.S05) }
        }
    }
}
