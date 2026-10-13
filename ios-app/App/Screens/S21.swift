import SwiftUI

/// S21 · Map before / after — drag the wipe divider (columns left of it show EXP-04, right show
/// EXP-03) or switch to "What changed" (▼ improved / ▲ worse), plus the stacked count bar.
/// Port of `wModes`, `wCells`, `wImp/wSame/wWorse`, `wipe*`.
struct S21View: View {
    @Environment(AppModel.self) private var app

    struct WCell { let bg: Color; let fg: Color; let label: String }

    static func errBg(_ e: Double) -> (Color, Color) {
        let m = abs(e)
        if m <= 1.5 { return (.oklch(0.45, 0.08, 150), .white) }
        if e < 0 { let a = min(1, (m - 1.5) / 4.5); return (.oklch(0.40 + a * 0.18, 0.07 + a * 0.10, 245), .white) }
        if e <= 3.5 { return (.oklch(0.72, 0.14, 65), AP.ink) }
        return (.oklch(0.60, 0.19, 27), .white)
    }

    static func cells(mode: Int, wipe: Double) -> (cells: [WCell], imp: Int, same: Int, worse: Int) {
        var out: [WCell] = []
        var imp = 0, same = 0, worse = 0
        for r in 0..<6 {
            for c0 in 0..<8 {
                let c = Double(c0 + 4), rr = Double(r)
                let d = abs(c / 11 - (1 - rr / 9) * 0.85 - 0.05)
                let hh = (sin(c * 12.9 + rr * 78.2) * 43758.5).truncatingRemainder(dividingBy: 1)
                let hits = d < 0.28 ? Int((60 * (1 - d / 0.28) * (0.45 + 0.55 * abs(hh))).rounded()) : 0
                let e = sin(c * 1.3 + rr * 0.7) * 3.2 + (c0 > 3 && r < 3 ? 3 : 0)
                var e2 = c0 > 3 && r < 3 ? e * 0.2 : e * 0.85
                if (r == 4 && c0 == 2) || (r == 5 && c0 == 1) { e2 = e + (e >= 0 ? 1.3 : -1.3) }
                if hits < 10 { out.append(WCell(bg: Color(hex: 0x121315), fg: Color(hex: 0x33373b), label: "·")); continue }
                let dd = abs(e2) - abs(e)
                if dd < -0.5 { imp += 1 } else if dd > 0.5 { worse += 1 } else { same += 1 }
                if mode == 0 {
                    let ev = Double(c0) < wipe ? e2 : e, cc = errBg(ev)
                    out.append(WCell(bg: cc.0, fg: cc.1, label: (ev > 0 ? "+" : "") + cFixed(ev, 1)))
                } else if dd < -0.5 {
                    out.append(WCell(bg: .oklch(0.45, 0.08, 150), fg: .white, label: "▼" + cFixed(abs(dd), 1)))
                } else if dd > 0.5 {
                    out.append(WCell(bg: .oklch(0.72, 0.14, 65), fg: AP.ink, label: "▲" + cFixed(dd, 1)))
                } else {
                    out.append(WCell(bg: AP.raised, fg: AP.label, label: "·"))
                }
            }
        }
        return (out, imp, same, worse)
    }

    var body: some View {
        let b = app.base
        let mode = app.wMode
        let w = S21View.cells(mode: mode, wipe: app.wipe)
        let nv = Double(w.imp + w.same + w.worse)
        let wipeOp: Double = mode == 0 ? 1 : 0
        let left = mode == 0 ? "◀ AFTER (EXP-04)" : "▼ IMPROVED  ▲ WORSE"
        let right = mode == 0 ? "BEFORE (EXP-03) ▶" : "ABS ERROR CHANGE, PTS"

        PhoneScreen(tab: .map) {
            ScreenHeader(title: "Map change", subtitle: app.tr("EXP-04 ·") + " " + app.tr(b.lamLabel) + " " + app.tr("ERROR BY CELL"))

            HStack(spacing: 5) {
                ForEach([(0, "Before / after"), (1, "What changed")], id: \.0) { i, label in
                    let on = mode == i
                    T(app.tr(label), .sans, 12).apFont(.sans, 12)
                        .foregroundStyle(CSel.fg(on)).lineLimit(1).fixedSize()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(CSel.bg(on)))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(CSel.border(on), lineWidth: 1))
                        .contentShape(Rectangle())
                        .onTapGesture { app.wMode = i }
                }
            }
            .block(top: 12)

            HStack {
                T(collapse(app.tr(left)), .mono, 10)
                Spacer(minLength: 0)
                T(collapse(app.tr(right)), .mono, 10)
            }
            .apFont(.mono, 10, lineHeight: 13 / 10).foregroundStyle(AP.text3)
            .block(top: 10)

            HStack(alignment: .top, spacing: 4) {
                VStack(spacing: 0) {
                    ForEach([100, 90, 80, 70, 60, 50], id: \.self) { a in
                        T(String(a), .mono, 9).apFont(.mono, 9, lineHeight: 11 / 9)
                            .frame(width: 22, alignment: .trailing)
                            .frame(maxHeight: .infinity)
                    }
                }
                .foregroundStyle(AP.faint)
                .frame(width: 22, height: 270)
                VStack(spacing: 4) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 8), spacing: 3) {
                        ForEach(Array(w.cells.enumerated()), id: \.offset) { _, c in
                            T(c.label, .mono, 10).apFont(.mono, 10)
                                .foregroundStyle(c.fg)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(RoundedRectangle(cornerRadius: 4).fill(c.bg))
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2).fill(Color.white)
                                .frame(width: 3, height: geo.size.height + 12)
                                .background(RoundedRectangle(cornerRadius: 4).fill(AP.screen).padding(-2))
                                .offset(x: geo.size.width * app.wipe / 8 - 1.5, y: -6)
                                .opacity(wipeOp)
                        }
                    }
                    HStack(spacing: 0) {
                        ForEach(["2.5", "3", "3.5", "4", "5", "6", "7", "7.6"], id: \.self) { a in
                            T(a, .mono, 9).apFont(.mono, 9, lineHeight: 11 / 9).frame(maxWidth: .infinity)
                        }
                    }
                    .foregroundStyle(AP.faint)
                }
            }
            .padding(.leading, 8).padding(.trailing, 14).padding(.top, 4)

            CRange(value: Binding(get: { app.wipe }, set: { app.wipe = $0 }), max: 8)
                .opacity(wipeOp)
                .allowsHitTesting(mode == 0)
                .block(top: 6)

            VStack(alignment: .leading, spacing: 8) {
                T(app.tr("CELL CHANGES · VISITED CELLS ONLY"), .mono, 10).apFont(.mono, 10, lineHeight: 13 / 10).foregroundStyle(AP.label)
                GeometryReader { geo in
                    let room = geo.size.width - 4
                    HStack(spacing: 2) {
                        Rectangle().fill(Color.oklch(0.45, 0.08, 150)).frame(width: room * Double(w.imp) / nv)
                        Rectangle().fill(AP.disabled).frame(width: room * Double(w.same) / nv)
                        Rectangle().fill(Color.oklch(0.72, 0.14, 65)).frame(width: room * Double(w.worse) / nv)
                    }
                }
                .frame(height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                HStack {
                    T("▼ \(w.imp) " + app.tr("IMPROVED"), .mono, 11).foregroundStyle(AP.green)
                    Spacer(minLength: 0)
                    T("\(w.same) " + app.tr("SAME"), .mono, 11).foregroundStyle(AP.label)
                    Spacer(minLength: 0)
                    T("▲ \(w.worse) " + app.tr("WORSE"), .mono, 11).foregroundStyle(AP.amber)
                }
                .apFont(.mono, 11)
                .frame(height: 17)
            }
            .apCard()
            .block(top: 10)

            VStack(alignment: .leading, spacing: 8) {
                T(app.tr("BIGGEST CHANGE"), .mono, 10).apFont(.mono, 10, lineHeight: 13 / 10).foregroundStyle(AP.label)
                T(app.tr("6k rpm / 80% load: +5.1% lean → +0.9%. The two worse cells are at low load and haven't been touched. That's noise, not this change."), .sans, 13)
                    .apFont(.sans, 13, lineHeight: 1.45).foregroundStyle(AP.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .apCard()
            .block(top: 10)

            Spacer(minLength: 0)
        }
    }

    /// HTML collapses runs of spaces.
    private func collapse(_ s: String) -> String {
        s.replacingOccurrences(of: "  ", with: " ")
    }
}
