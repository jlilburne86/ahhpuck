import SwiftUI

/// S16 · Expected result — step-size picker recalculates the headline range, the error-by-RPM
/// chart and the seven range-bar metrics (port of `incOpts`, `mExp`, `hCur/hExp`, `pNow/pMid/pBand`).
struct S16View: View {
    @Environment(AppModel.self) private var app

    /// Chart series in the prototype's 326×96 viewBox.
    static func chart(_ inc: Double) -> (now: [CGPoint], mid: [CGPoint], up: [CGPoint], dn: [CGPoint]) {
        let NN = 60
        let ex = { (x: Double) in 1.4 + 3.6 * max(0, x - 0.45) * 1.8 + 0.8 * sin(x * 8) * 0.5 + 0.6 }
        let yE = { (e: Double) in 90 - min(8, max(0, e)) / 8 * 86 }
        let ov = max(0, inc - 1)
        let pm = { (x: Double) in ex(x) * (1 - 0.5 * inc) + ov * (1.5 + x * 2) }
        let pw = 0.3 + 0.25 * inc
        func P(_ fn: (Double) -> Double) -> [CGPoint] {
            (0..<NN).map { i in
                let x = Double(i) / Double(NN - 1)
                return CGPoint(x: Double(cFixed(Double(i) * 326 / Double(NN - 1), 1))!, y: Double(cFixed(yE(fn(x)), 1))!)
            }
        }
        return (P(ex), P(pm), P { pm($0) + pw }, P { pm($0) - pw })
    }

    var body: some View {
        let b = app.base
        let inc = CState.shared.inc
        let ms = CMetrics.metrics(inc, lamLabel: b.lamLabel)
        let h0 = ms[0]
        let hCur = cFixed(h0.cur, 1) + "%"
        let hExp = cFixed(max(0, h0.mid - h0.w), 1) + "–" + cFixed(h0.mid + h0.w, 1) + "%"
        let confL = inc > 1 ? "! LOW CONFIDENCE · UNTESTED STEP SIZE" : "MEDIUM CONFIDENCE · 7/9 PAST HITS"
        let confC = inc > 1 ? AP.amber : AP.label
        let ch = S16View.chart(inc)

        PhoneScreen(tab: .review, status: "OFFLINE", statusStyle: .dim, scrolls: false) {
            ScreenHeader(title: "Expected result", subtitle: "EXP-05 PROPOSAL · FUEL ONLY")

            VStack(alignment: .leading, spacing: 6) {
                T(app.tr("STEP SIZE PER CELL · CAP ±1.5%"), .mono, 10).apFont(.mono, 10).foregroundStyle(AP.label)
                HStack(spacing: 5) {
                    ForEach([0.5, 0.75, 1, 1.25, 1.5], id: \.self) { x in
                        let on = CState.shared.inc == x
                        T("±" + S16View.js(x) + "%", .sans, 12).apFont(.sans, 12)
                            .foregroundStyle(CSel.fg(on)).lineLimit(1).fixedSize()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 8).fill(CSel.bg(on)))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(CSel.border(on), lineWidth: 1))
                            .contentShape(Rectangle())
                            .onTapGesture { CState.shared.inc = x }
                    }
                }
            }
            .block(top: 10)

            VStack(alignment: .leading, spacing: 8) {
                CFlexRow {
                    T(app.tr("HEADLINE · AVG ") + app.tr(b.lamLabel) + app.tr(" ERROR"), .mono, 10).apFont(.mono, 10).foregroundStyle(AP.label)
                        .fixedSize(horizontal: false, vertical: true)
                    T(app.tr(confL), .mono, 10).apFont(.mono, 10).foregroundStyle(confC)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    T(hCur, .barlow, 26, 600).apFont(.barlow, 26, 600).foregroundStyle(AP.label)
                    T("→", .sans, 16).apFont(.sans, 16).foregroundStyle(AP.faint)
                    T(hExp, .barlow, 40, 700).apFont(.barlow, 40, 700, lineHeight: 1).foregroundStyle(.white)
                }
                Canvas { ctx, _ in
                    ctx.scaleBy(x: 1, y: 64.0 / 96.0)
                    var tgt = Path(); tgt.move(to: CGPoint(x: 0, y: 90)); tgt.addLine(to: CGPoint(x: 326, y: 90))
                    ctx.stroke(tgt, with: .color(AP.cyan), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    var band = Path(polyline: ch.up)
                    for p in ch.dn.reversed() { band.addLine(to: p) }
                    band.closeSubpath()
                    ctx.fill(band, with: .color(AP.candidate.opacity(0.35)))
                    ctx.stroke(Path(polyline: ch.now), with: .color(AP.label), lineWidth: 1.5)
                    ctx.stroke(Path(polyline: ch.mid), with: .color(AP.candidate), style: StrokeStyle(lineWidth: 1.6, dash: [4, 2]))
                }
                .frame(width: 326, height: 64)
                HStack(spacing: 0) {
                    T("2.5k", .mono, 9)
                    Spacer(minLength: 0)
                    T(app.tr("ERROR BY RPM · 0 = ON TARGET"), .mono, 9)
                    Spacer(minLength: 0)
                    T("7k", .mono, 9)
                }
                .apFont(.mono, 9).foregroundStyle(AP.faint)
            }
            .apCard(vertical: 10, horizontal: 14)
            .block(top: 10)

            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Rectangle().fill(AP.text3).frame(width: 2, height: 10)
                    T(app.tr("NOW"), .mono, 9)
                }
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2).fill(AP.candidate.opacity(0.55))
                        .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(AP.candidate, lineWidth: 1))
                        .frame(width: 16, height: 10)
                    T(app.tr("EXPECTED RANGE"), .mono, 9)
                }
                HStack(spacing: 5) {
                    Hatch(a: Color(hex: 0x4a4f54), b: .clear, stripe: 3).frame(width: 14, height: 8)
                    T(app.tr("RUN-TO-RUN NOISE"), .mono, 9)
                }
            }
            .apFont(.mono, 9).foregroundStyle(AP.label)
            .block(top: 8)

            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(ms.map { CMetrics.row($0) }, id: \.k) { CMetricRow(r: $0) }
                }
            }
            .scrollIndicators(.hidden)
            .padding(1)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .outlined(AP.border, radius: 12)
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 10)
        }
    }

    /// JS number → string for the step options (0.75 → "0.75", 1 → "1").
    static func js(_ x: Double) -> String {
        x == x.rounded() ? String(Int(x)) : String(x)
    }
}
