import SwiftUI

// Shared helpers for the group C screens (S15–S23, S41). Ports of the prototype's shared
// `metrics` / `row` (S16 expected result, S23 expected vs actual) and a few CSS layout behaviours.

/// JS `Number.prototype.toFixed`.
func cFixed(_ x: Double, _ d: Int) -> String {
    let s = String(format: "%.\(d)f", x)
    return s.hasPrefix("-") && Double(s) == 0 ? String(s.dropFirst()) : s
}

/// A row of flex items with `flex-shrink:1`: each child gets its ideal width, and when the
/// row overflows every child shrinks in proportion to its ideal width (CSS flex basis = content).
/// `align-items: baseline` is approximated with top alignment for equal-face children.
struct CFlexRow: Layout {
    var spacing: CGFloat = 0
    var justifyBetween = true

    private func widths(_ proposal: ProposedViewSize, _ subviews: Subviews) -> [CGFloat] {
        let ideal = subviews.map { $0.sizeThatFits(.unspecified).width }
        guard let avail = proposal.width else { return ideal }
        let room = avail - spacing * CGFloat(max(0, subviews.count - 1))
        let total = ideal.reduce(0, +)
        guard total > room, total > 0 else { return ideal }
        let over = total - room
        return ideal.map { $0 - over * $0 / total }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = widths(proposal, subviews)
        let h = zip(subviews, w).map { $0.sizeThatFits(ProposedViewSize(width: $1, height: nil)).height }.max() ?? 0
        return CGSize(width: proposal.width ?? (w.reduce(0, +) + spacing * CGFloat(max(0, w.count - 1))), height: h)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let w = widths(proposal, subviews)
        let used = w.reduce(0, +) + spacing * CGFloat(max(0, w.count - 1))
        let gap = justifyBetween && subviews.count > 1 ? spacing + max(0, bounds.width - used) / CGFloat(subviews.count - 1) : spacing
        var x = bounds.minX
        for (s, wi) in zip(subviews, w) {
            s.place(at: CGPoint(x: x, y: bounds.minY), proposal: ProposedViewSize(width: wi, height: nil))
            x += wi + gap
        }
    }
}

/// The prototype's selectable option (`sel()`): white when selected.
struct CSel {
    static func bg(_ on: Bool) -> Color { on ? AP.text : .clear }
    static func fg(_ on: Bool) -> Color { on ? AP.ink : AP.text2 }
    static func border(_ on: Bool) -> Color { on ? AP.text : AP.control }
}

/// Port of `metrics(inc)` and `row(m, act)` from the prototype (S16 and S23).
enum CMetrics {
    struct M {
        let k: String, u: String, cur: Double, mid: Double, w: Double, bt: Int, n: Double
        let d: (Double, Double), dp: Int
        var lim: Double? = nil
        var sg = false
    }
    struct Row {
        let k: String, cur: String, exp: String
        /// Percent positions (0–100) of the expected range, noise band, current and actual.
        let eL: Double, eW: Double, nL: Double, nW: Double, cP: Double, aP: Double
        let dir: String, verdict: String, vc: Color
    }

    static func metrics(_ inc: Double, lamLabel: String) -> [M] {
        let ov = max(0, inc - 1)
        return [
            M(k: "Avg " + lamLabel.lowercased() + " error", u: "%", cur: 4.8, mid: 4.8 - 2.4 * inc + 3 * ov, w: 0.35 + 0.25 * inc, bt: -1, n: 0.3, d: (0, 6), dp: 1),
            M(k: "Cells on target (of 38)", u: "", cur: 22, mid: 22 + 9.5 * inc - 7 * ov, w: 2 + 1.5 * inc, bt: 1, n: 1.5, d: (15, 38), dp: 0),
            M(k: "Lean cells under load", u: "", cur: 6, mid: max(0.6, 6 - 5 * inc), w: 0.8, bt: -1, n: 0.5, d: (0, 8), dp: 0),
            M(k: "Rich overshoot cells", u: "", cur: 0, mid: 0.2 + ov * 10, w: 0.5 + ov * 3, bt: -1, n: 0.5, d: (0, 8), dp: 0),
            M(k: "Peak injector duty", u: "%", cur: 86, mid: 86 + 1.1 * inc, w: 0.6, bt: -1, n: 0.4, d: (82, 92), dp: 1, lim: 88),
        ]
    }

    static func pct(_ x: Double, _ d: (Double, Double)) -> Double { max(0, min(100, (x - d.0) / (d.1 - d.0) * 100)) }

    static func fm(_ m: M, _ x: Double) -> String {
        let r = m.dp > 0 ? cFixed(x, m.dp) : String(max(0, Int(x.rounded(.toNearestOrAwayFromZero))))
        return (m.sg && x > 0 ? "+" : "") + r
    }

    static func row(_ m: M, act: Double? = nil) -> Row {
        let lo = max(m.d.0, m.mid - m.w), hi = m.mid + m.w
        let worst = m.bt > 0 ? lo - m.cur : m.cur - hi
        let midG = m.bt > 0 ? m.mid - m.cur : m.cur - m.mid
        var verdict: String, vc: Color
        if let act {
            let inR = act >= lo - 1e-9 && act <= hi + 1e-9, better = m.bt > 0 ? act > hi : act < lo
            verdict = inR ? "✓ IN RANGE" : better ? "✓ BETTER THAN EXPECTED" : "! MISSED"
            vc = inR || better ? AP.green : AP.amber
        } else if let lim = m.lim, hi >= lim { verdict = "! NEAR \(Int(lim + 2))% LIMIT"; vc = AP.amber }
        else if worst > m.n { verdict = "✓ CLEAR GAIN"; vc = AP.green }
        else if midG < -m.n / 2 { verdict = "! TRADE-OFF"; vc = AP.amber }
        else { verdict = "≈ WITHIN NOISE"; vc = AP.label }
        return Row(k: m.k, cur: fm(m, m.cur) + m.u,
                   exp: act != nil ? fm(m, act!) + m.u : fm(m, lo) + "–" + fm(m, hi) + m.u,
                   eL: pct(lo, m.d), eW: max(1.5, pct(hi, m.d) - pct(lo, m.d)),
                   nL: pct(m.cur - m.n, m.d), nW: pct(m.cur + m.n, m.d) - pct(m.cur - m.n, m.d),
                   cP: pct(m.cur, m.d), aP: act.map { pct($0, m.d) } ?? 0,
                   dir: m.bt > 0 ? "BETTER →" : "← BETTER", verdict: verdict, vc: vc)
    }
}

/// One S16/S23 metric row: label, current → expected/actual, range bar, direction and verdict.
struct CMetricRow: View {
    @Environment(AppModel.self) private var app
    let r: CMetrics.Row
    var actual = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                T(app.tr(r.k), .sans, 12).apFont(.sans, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                (T(r.cur + " → ", .mono, 11).foregroundColor(AP.label) + T(r.exp, .mono, 11, 600).foregroundColor(.white))
                    .apFont(.mono, 11).lineLimit(1).fixedSize()
            }
            .frame(height: 17)
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(AP.raised).frame(width: w, height: 2).offset(y: 5)
                    Hatch(a: AP.hatchA, b: .clear, stripe: 3)
                        .frame(width: w * r.nW / 100, height: 8).offset(x: w * r.nL / 100, y: 2)
                    RoundedRectangle(cornerRadius: 3).fill(AP.candidate.opacity(0.55))
                        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(AP.candidate, lineWidth: 1))
                        .frame(width: w * r.eW / 100 + 2, height: 12).offset(x: w * r.eL / 100, y: 1)
                    Rectangle().fill(AP.text3).frame(width: 2, height: 14).offset(x: w * r.cP / 100 - 1, y: -1)
                    if actual {
                        Circle().fill(Color.white).frame(width: 10, height: 10)
                            .overlay(Circle().strokeBorder(AP.screen, lineWidth: 2))
                            .offset(x: w * r.aP / 100 - 5, y: 1)
                    }
                }
            }
            .frame(height: 12)
            HStack {
                T(app.tr(r.dir), .mono, 9).apFont(.mono, 9).foregroundStyle(AP.faint)
                Spacer(minLength: 0)
                T(app.tr(r.verdict), .mono, 9, 600).apFont(.mono, 9, 600).foregroundStyle(r.vc).lineLimit(1)
            }
            .frame(height: 14)
        }
        .padding(.vertical, 6).padding(.horizontal, 12)
        .padding(.bottom, 1)
        .overlay(alignment: .bottom) { Rectangle().fill(AP.divider).frame(height: 1) }
    }
}

/// `<input type="range" min=0 max=100 style="accent-color:#e8e6e1">` as Chrome draws it on a dark
/// page: 16 pt tall, an 8 pt track with a 1 pt #858585 rim (accent fill left of the thumb,
/// #3b3b3b right of it) and a 15 pt accent thumb whose centre travels 7.5…w−7.5. Step 1.
struct CRange: View {
    @Binding var value: Double
    var max: Double = 100

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let cx = 7.5 + value / self.max * (w - 15)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0x3b3b3b))
                    .frame(width: w, height: 8).offset(y: 4)
                Rectangle().fill(AP.text).frame(width: cx, height: 8)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 4))
                    .offset(y: 4)
                RoundedRectangle(cornerRadius: 4).strokeBorder(Color(hex: 0x858585), lineWidth: 1)
                    .frame(width: w, height: 8).offset(y: 4)
                Circle().fill(AP.text).frame(width: 15, height: 15).offset(x: cx - 7.5, y: 0.5)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                value = (Swift.max(0, Swift.min(1, (g.location.x - 7.5) / (w - 15))) * self.max).rounded()
            })
        }
        .frame(height: 16)
    }
}

/// Group C state the foundation can't hold. `AppModel.inc` is an `Int`, but the prototype's
/// S16 step size takes 0.5 / 0.75 / 1 / 1.25 / 1.5, so the step size lives here (initial 1).
@MainActor @Observable
final class CState {
    static let shared = CState()
    var inc: Double = 1
}
