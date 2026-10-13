import SwiftUI

/// S29 · Progress bars (the alternative to S28) — tap a bar for its step.
struct S29View: View {
    @Environment(AppModel.self) private var app

    private struct PG { let id: String; let v: Double; let lo: Double; let hi: Double; let dec: String; let c: Color; let pend: Bool; let proj: Bool; let body: String }
    private static let pg: [PG] = [
        PG(id: "BASE", v: 7.1, lo: 0, hi: 0, dec: "BASELINE", c: AP.label, pend: false, proj: false, body: "Starting point: 7.1% average lambda error across 38 covered cells."),
        PG(id: "EXP-01", v: 5.6, lo: 0, hi: 0, dec: "✓ ACCEPTED", c: AP.green, pend: false, proj: false, body: "Cruise fuel +1.2%. Gain 1.5 points, confirmed by a repeat."),
        PG(id: "EXP-02", v: 5.6, lo: 0, hi: 0, dec: "↺ ROLLED BACK", c: AP.rollback, pend: false, proj: false, body: "Idle fuel −0.5% caused idle hunting. Rolled back, so no change to the reference."),
        PG(id: "EXP-03", v: 4.8, lo: 0, hi: 0, dec: "✓ ACCEPTED", c: AP.green, pend: false, proj: false, body: "Mid-band fuel +0.8%. Gain 0.8 points, confirmed by a repeat."),
        PG(id: "EXP-04", v: 2.1, lo: 0, hi: 0, dec: "! REPEAT NEEDED", c: AP.amber, pend: true, proj: false, body: "High-load fuel −1.0%. Gain 2.7 points, but the repeat was unclean. Not counted until it passes."),
        PG(id: "NEXT", v: 0, lo: 1.4, hi: 1.9, dec: "PROJECTED", c: DC.violet, pend: false, proj: true, body: "If EXP-04 holds, one more ±1.0% step on 6 cells should reach 1.4–1.9%, which overlaps the goal."),
    ]
    private static let sc: CGFloat = 150 / 8

    var body: some View {
        let ps = S29View.pg[app.pgSel]
        PhoneScreen(tab: .runs, status: "OFFLINE", statusStyle: .dim) {
            ScreenHeader(title: "Progress", subtitle: "DRIVABILITY · GOAL ≤ 1.5% AVG ERROR")
            chart.block()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    DT(ps.id + (ps.proj ? " · \(fmt(ps.lo))–\(fmt(ps.hi))%" : " · " + String(format: "%.1f%%", ps.v)), .barlow, 22, 600)
                    Spacer(minLength: 0)
                    DT(app.tr(ps.dec), .mono, 10, 600).foregroundStyle(ps.c)
                }
                DT(app.tr(ps.body), .sans, 13, lh: 1.45).foregroundStyle(AP.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .apCard()
            .block()

            HStack(spacing: 6) {
                tile("IMPROVED", "7.1 → 2.1%")
                tile("TO GOAL", "0.6 pts")
                tile("EST. STEPS", "1–2 more")
            }
            .fixedSize(horizontal: false, vertical: true)
            .block()

            DT(app.tr("Each step is capped at ±1.5% per cell, so gains come in small, verified steps. Bars outlined in violet are not yet proven by a repeat."), .sans, 12, lh: 1.45)
                .foregroundStyle(AP.label)
                .fixedSize(horizontal: false, vertical: true)
                .block()
            Spacer(minLength: 0)
        }
    }

    private func fmt(_ x: Double) -> String { x == x.rounded() ? String(Int(x)) : String(x) }

    private func tile(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            DT(app.tr(k), .mono, 10).foregroundStyle(AP.label)
            DT(app.tr(v), .barlow, 19, 600).lineLimit(1).fixedSize()
        }
        .padding(.vertical, 9).padding(.horizontal, 11)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .outlined(AP.border, radius: 10)
    }

    @ViewBuilder private func barBg(_ i: Int, _ x: PG) -> some View {
        if x.proj { RoundedRectangle(cornerRadius: 4).fill(DC.violet(0.35)) }
        else if x.pend { Hatch(a: DC.violet(0.5), b: .clear, stripe: 4).clipShape(RoundedRectangle(cornerRadius: 4)) }
        else { RoundedRectangle(cornerRadius: 4).fill(i == 0 ? DC.hatchStripe : x.dec.contains("ROLLED") ? AP.disabled : AP.label) }
    }

    private var chart: some View {
        let sc = S29View.sc
        let goalB = 1.5 * sc
        return VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                // goal line: bottom:goalB; border-top 1px dashed cyan
                Path { p in p.move(to: CGPoint(x: 0, y: 0.5)); p.addLine(to: CGPoint(x: 324, y: 0.5)) }
                    .stroke(AP.cyan, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .frame(height: 1)
                    .offset(y: -goalB)
                DT(app.tr("GOAL 1.5%"), .mono, 9).foregroundStyle(AP.cyan)
                    .padding(.bottom, 2)
                    .offset(y: -goalB)
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(S29View.pg.enumerated()), id: \.offset) { i, x in
                        let selected = i == app.pgSel
                        let bordered = x.proj || x.pend
                        VStack(spacing: 3) {
                            DT(x.proj ? "\(fmt(x.lo))–\(fmt(x.hi))" : String(format: "%.1f", x.v), .mono, 10)
                                .foregroundStyle(selected ? Color.white : AP.label)
                            barBg(i, x)
                                .overlay { if bordered { RoundedRectangle(cornerRadius: 4).strokeBorder(DC.violet, lineWidth: 1) } }
                                .overlay {
                                    if selected { RoundedRectangle(cornerRadius: 7).strokeBorder(Color.white, lineWidth: 1).padding(-3) }
                                }
                                .frame(height: (x.proj ? (x.hi - x.lo) * sc : x.v * sc) + 2)
                                .padding(.horizontal, -1)
                                .padding(.bottom, x.proj ? x.lo * sc : 0)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { app.pgSel = i }
                    }
                }
                .padding(.horizontal, 2)
            }
            .frame(height: 190, alignment: .bottom)

            HStack(spacing: 8) {
                ForEach(S29View.pg, id: \.id) { x in
                    DT(app.tr(x.id), .mono, 8).foregroundStyle(AP.label).frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 2)
        }
        .apCard()
    }
}
