import SwiftUI

/// S28 · Gain bridge — waterfall from baseline to now, the projected next step, a dashed cyan
/// goal line, gain-per-step columns and a steps-to-goal track.
struct S28View: View {
    @Environment(AppModel.self) private var app

    private enum Fill { case solid(Color), hatch, none }
    private struct WF { let id: String; let l, w: Double; let wPx: CGFloat?; let fill: Fill; let border: Color?; let dashed: Bool; let v: String; let vc: Color; let lc: Color }

    /// `X(x) = x / 8 · 100 %` of the track.
    private static let rows: [WF] = [
        WF(id: "BASE", l: 0, w: 7.1 / 8, wPx: nil, fill: .solid(DC.hatchStripe), border: nil, dashed: false, v: "7.1%", vc: AP.text3, lc: AP.label),
        WF(id: "EXP-01", l: 5.6 / 8, w: 1.5 / 8, wPx: nil, fill: .solid(AP.green), border: nil, dashed: false, v: "−1.5", vc: AP.green, lc: AP.label),
        WF(id: "EXP-02", l: 5.6 / 8, w: 0, wPx: 3, fill: .solid(AP.rollback), border: nil, dashed: false, v: "0 ↺", vc: AP.rollback, lc: AP.label),
        WF(id: "EXP-03", l: 4.8 / 8, w: 0.8 / 8, wPx: nil, fill: .solid(AP.green), border: nil, dashed: false, v: "−0.8", vc: AP.green, lc: AP.label),
        WF(id: "EXP-04", l: 2.1 / 8, w: 2.7 / 8, wPx: nil, fill: .hatch, border: DC.violet, dashed: false, v: "−2.7 ?", vc: DC.violet, lc: AP.label),
        WF(id: "NOW", l: 0, w: 2.1 / 8, wPx: nil, fill: .solid(AP.text), border: nil, dashed: false, v: "2.1%", vc: .white, lc: .white),
        WF(id: "NEXT", l: 1.4 / 8, w: 0.5 / 8, wPx: nil, fill: .solid(DC.violet(0.35)), border: DC.violet, dashed: true, v: "1.4–1.9", vc: DC.violet, lc: AP.label),
    ]

    var body: some View {
        PhoneScreen(tab: .runs, status: "OFFLINE", statusStyle: .dim) {
            ScreenHeader(title: "Gain bridge", subtitle: app.tr("AVG") + " " + app.tr(app.base.lamLabel) + " " + app.tr("ERROR · LOWER IS BETTER"))
            waterfall.block()
            gainPerStep.block()
            stepsToGoal.block()
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private func barFill(_ f: Fill) -> some View {
        switch f {
        case .solid(let c): RoundedRectangle(cornerRadius: 3).fill(c)
        case .hatch: Hatch(a: DC.violet(0.6), b: .clear, stripe: 4).clipShape(RoundedRectangle(cornerRadius: 3))
        case .none: Color.clear
        }
    }

    private var waterfall: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 0) {
                ForEach(S28View.rows, id: \.id) { r in
                    HStack(spacing: 8) {
                        DT(app.tr(r.id), .mono, 10).foregroundStyle(r.lc).frame(width: 50, alignment: .leading)
                        GeometryReader { g in
                            let W = g.size.width
                            let b: CGFloat = r.border == nil ? 0 : 1
                            ZStack(alignment: .topLeading) {
                                // goal line: border-left 1px dashed cyan at X(1.5)
                                Path { p in p.move(to: CGPoint(x: 0.5, y: 0)); p.addLine(to: CGPoint(x: 0.5, y: 38)) }
                                    .stroke(AP.cyan, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                    .frame(width: 1, height: 38)
                                    .offset(x: W * 1.5 / 8)
                                barFill(r.fill)
                                    .overlay {
                                        if let c = r.border {
                                            RoundedRectangle(cornerRadius: 3)
                                                .strokeBorder(c, style: StrokeStyle(lineWidth: 1, dash: r.dashed ? [3, 3] : []))
                                        }
                                    }
                                    .frame(width: (r.wPx ?? W * r.w) + 2 * b, height: 20 + 2 * b)
                                    .offset(x: W * r.l, y: 9)
                            }
                        }
                        .frame(height: 38)
                        DT(app.tr(r.v), .mono, 11).foregroundStyle(r.vc).lineLimit(1).fixedSize()
                            .frame(width: 52, alignment: .trailing)
                    }
                    .frame(height: 38)
                    .padding(.bottom, 1)
                    .overlay(alignment: .bottom) { DDivider(color: Color(hex: 0x1a1c1f)) }
                }
            }
            HStack(spacing: 8) {
                Color.clear.frame(width: 50, height: 1)
                HStack(spacing: 0) {
                    ForEach(Array(["0", "2", "4", "6", "8%"].enumerated()), id: \.offset) { i, s in
                        if i > 0 { Spacer(minLength: 0) }
                        DT(s, .mono, 9)
                    }
                }
                .foregroundStyle(AP.faint)
                DT(app.tr("┆ GOAL"), .mono, 9).foregroundStyle(AP.cyan).lineLimit(1).fixedSize()
                    .frame(width: 52, alignment: .trailing)
            }
            .frame(height: 14)
        }
        .apCard()
    }

    private var gainPerStep: some View {
        // (id, pts, fill, border, dashed)
        let gps: [(String, Double, Fill, Color?, Bool)] = [
            ("01", 1.5, .solid(AP.green), nil, false), ("02", 0, .solid(AP.rollback), nil, false), ("03", 0.8, .solid(AP.green), nil, false),
            ("04", 2.7, .hatch, DC.violet, false), ("NEXT", 0.45, .solid(DC.violet(0.35)), DC.violet, true),
        ]
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                DT(app.tr("GAIN PER STEP"), .mono, 10)
                Spacer(minLength: 0)
                DT(app.tr("PTS"), .mono, 10)
            }
            .foregroundStyle(AP.label)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(gps, id: \.0) { id, x, f, bd, dashed in
                    let b: CGFloat = bd == nil ? 0 : 1
                    VStack(spacing: 4) {
                        DT(x != 0 ? String(format: "%.1f", x) : "0", .mono, 10)
                            .foregroundStyle(id == "04" || id == "NEXT" ? DC.violet : AP.text3)
                        barFill(f)
                            .overlay {
                                if let bd { RoundedRectangle(cornerRadius: 3).strokeBorder(bd, style: StrokeStyle(lineWidth: 1, dash: dashed ? [3, 3] : [])) }
                            }
                            .frame(height: max(3, x / 3 * 72) + 2 * b)
                            .padding(.horizontal, -b)
                        DT(app.tr(id), .mono, 8).foregroundStyle(AP.faint)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 96, alignment: .bottom)
        }
        .apCard()
    }

    private var stepsToGoal: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                DT(app.tr("STEPS TO GOAL"), .mono, 10).foregroundStyle(AP.label)
                Spacer(minLength: 0)
                DT(app.tr("~1–2 MORE"), .mono, 11)
            }
            // flex:1 segments; the bordered ones are content-box, so they are 2 pt wider and taller.
            GeometryReader { g in
                let w = (g.size.width - 30 - 6) / 6
                HStack(alignment: .top, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4).fill(AP.green).frame(width: w, height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(AP.rollback).frame(width: w, height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(AP.green).frame(width: w, height: 8)
                    Hatch(a: DC.violet, b: .clear, stripe: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(DC.violet, lineWidth: 1))
                        .frame(width: w + 2, height: 10)
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 4).strokeBorder(DC.dimValue, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .frame(width: w + 2, height: 10)
                    }
                }
            }
            .frame(height: 10)
        }
        .apCard()
    }
}
