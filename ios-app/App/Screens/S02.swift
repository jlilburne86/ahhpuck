import SwiftUI

/// S02 · Vehicle profile ("Engine passport") — 7-step chip form; Unknown is a valid answer that blocks S15.
struct S02View: View {
    @Environment(AppModel.self) private var app

    static let steps: [(k: String, label: String, opts: [String])] = [
        ("chassis", "Chassis", ["AE86", "AE101", "AE111", "Other", "Unknown"]),
        ("engine", "Engine", ["4A-GE 20V Blacktop", "4A-GE 20V Silvertop", "4A-GE 16V", "4A-GZE", "Unknown"]),
        ("ecu", "ECU label", ["FC-03 Ab-1EU", "FC-03 other", "Unknown"]),
        ("load", "Load strategy", ["MAP", "Alpha-N / TPS", "Blended", "MAF", "Unknown"]),
        ("inj", "Injection", ["Sequential", "Group", "Batch", "Unknown"]),
        ("ign", "Ignition", ["Direct", "Distributor", "Wasted spark", "Unknown"]),
        ("obj", "Objective", ["Drivability", "Grip", "Drift", "0–100", "Top speed", "Reliability"]),
    ]

    var body: some View {
        let steps = Self.steps, ps = app.pStep, cur = steps[ps]
        let unk = steps.filter { app.prof[$0.k] == "Unknown" }.count
        PhoneScreen(tab: .garage) {
            AHeader(title: "Engine passport", sub: app.tr("STEP \(ps + 1) OF 7") + " · " + app.tr("\(7 - unk)/7 KNOWN"))

            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(i == ps ? AP.text : i < ps ? AP.label : AP.disabled)
                        .frame(height: 5)
                        .contentShape(Rectangle().inset(by: -8))
                        .onTapGesture { app.pStep = i }
                }
            }
            .block(top: 12)

            VStack(alignment: .leading, spacing: 8) {
                M(cur.label.uppercased(), .mono, 10, color: AP.label)
                DFlow(spacing: 6, lineSpacing: 6) {
                    ForEach(cur.opts, id: \.self) { o in
                        MChip(label: o, on: app.prof[cur.k] == o, size: 13, v: 7, h: 11) { app.prof[cur.k] = o }
                    }
                }
                HStack {
                    M("← Back", .sans, 13, color: AP.text3).padding(.vertical, 6)
                        .contentShape(Rectangle()).onTapGesture { app.pStep = max(0, ps - 1) }
                    Spacer()
                    M("Next →", .sans, 13, 600).padding(.vertical, 6)
                        .contentShape(Rectangle()).onTapGesture {
                            if ps == 6 && app.router.onboarding { app.router.nextInFirstRun(after: .S02) }
                            else { app.pStep = min(6, ps + 1) }
                        }
                }
                .padding(.top, 4)
            }
            .apCard()
            .block()

            MList {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, x in
                    let v = app.prof[x.k] ?? "—", u = v == "Unknown"
                    HStack(spacing: 8) {
                        M(x.label, .sans, 12, color: AP.label).frame(width: 96, alignment: .leading)
                        M(v, .sans, 13, color: u ? AP.amber : AP.text).frame(maxWidth: .infinity, alignment: .leading)
                        if u { M("BLOCKS PROPOSAL", .mono, 9, color: AP.amber) }
                    }
                    .mRow()
                    .contentShape(Rectangle())
                    .onTapGesture { app.pStep = i }
                }
            }
            .block()

            M(unk > 0 ? "\(unk) unknown field\(unk > 1 ? "s" : "") block proposals until confirmed." : "Profile complete. Proposals unlocked.",
              .sans, 13, color: unk > 0 ? AP.amber : AP.green, lineHeight: 1.45)
                .block()
            Spacer(minLength: 0)
        }
    }
}
