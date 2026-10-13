import SwiftUI

/// S30 · Learning ledger (Runs tab root) — experiment cards with a decision stripe and filters.
/// Tuner density adds each run's hash.
struct S30View: View {
    @Environment(AppModel.self) private var app

    struct Exp { let id, title, dec, date, res, h: String }
    static let exps: [Exp] = [
        Exp(id: "EXP-04", title: "High-load fuel −1.0%", dec: "Repeat", date: "13 Oct", res: "λ err 4.8 → 2.1% · repeat unproven", h: "sha 81d0…4b07"),
        Exp(id: "EXP-03", title: "Mid-band fuel +0.8%", dec: "Accept", date: "06 Oct", res: "λ err 5.6 → 4.8% · reference", h: "sha 3f9a…c21e"),
        Exp(id: "EXP-02", title: "Idle fuel −0.5%", dec: "Rollback", date: "29 Sep", res: "Idle hunting +40 rpm", h: "sha 2c71…e0aa"),
        Exp(id: "EXP-01", title: "Cruise fuel +1.2%", dec: "Accept", date: "22 Sep", res: "λ err 7.1 → 5.6%", h: "sha 9b03…71fd"),
        Exp(id: "BASE-01", title: "Baseline captured", dec: "Baseline", date: "15 Sep", res: "18,420 frames · 31 Hz", h: "sha 1e44…0c9b"),
        Exp(id: "EXP-00", title: "Pre-check pull", dec: "Abort", date: "14 Sep", res: "Knock ×2 at 5,800 rpm", h: "sha 6d2a…b310"),
    ]

    var body: some View {
        let rows = S30View.exps.filter { app.filt == "All" || $0.dec == app.filt }
        PhoneScreen(tab: .runs, status: "OFFLINE", statusStyle: .dim) {
            ScreenHeader(title: "Ledger", subtitle: app.tr("AE86 · 4A-GE 20V BLACKTOP ·") + " " + app.tr("\(rows.count) SHOWN"))

            DFlow(spacing: 6, lineSpacing: 6) {
                ForEach(["All", "Accept", "Repeat", "Rollback", "Abort"], id: \.self) { x in
                    DOption(label: x, on: app.filt == x, fill: false) { app.filt = x }
                }
            }
            .block(top: 12)

            VStack(spacing: 6) {
                ForEach(rows, id: \.id) { r in row(r) }
            }
            .block()
            Spacer(minLength: 0)
        }
    }

    private func row(_ r: Exp) -> some View {
        let c = DDecision.color(r.dec)
        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 3)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top, spacing: 8) {
                    DT(app.tr(r.id) + " · " + app.tr(r.date), .mono, 11).foregroundStyle(AP.label).lineLimit(1)
                    Spacer(minLength: 0)
                    DT(app.tr(r.dec.uppercased()), .mono, 10).foregroundStyle(c)
                }
                DT(app.tr(r.title), .sans, 14, 500)
                DT(app.tr(r.res), .mono, 11).foregroundStyle(AP.text3)
                if app.tuner {
                    DT(r.h, .mono, 10).foregroundStyle(AP.faint)
                } else {
                    Color.clear.frame(height: 0)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .apCard(vertical: 8, horizontal: 12)
        .contentShape(Rectangle())
        .onTapGesture { app.router.go(.S31) }
        // The design has no visible links here; the run views open from a long-press menu.
        .contextMenu {
            Button(app.tr("Session detail & export")) { app.router.go(.S31) }
            Button(app.tr("Run overlay")) { app.router.go(.S19) }
            Button(app.tr("Gain curve")) { app.router.go(.S20) }
            Button(app.tr("Gain bridge")) { app.router.go(.S28) }
            Button(app.tr("Progress")) { app.router.go(.S29) }
        }
    }
}
