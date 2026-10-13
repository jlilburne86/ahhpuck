import SwiftUI

/// S24 · Result dial & objective radar
struct S24View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: .review, status: "OFFLINE", statusStyle: .dim) {
            ScreenHeader(title: "Result", subtitle: "EXP-04 · PREDICTION CHECK")
            DEased { ease in
                VStack(spacing: 0) {
                    dialCard(ease).block()
                    radarCard(ease).block()
                }
            }
            Spacer(minLength: 0)
        }
        .onAppear { DRing.shared.replay() }
    }

    // MARK: dial — semicircle from 8 % (left) to 0 % (right)
    private static let cx = 163.0, cy = 138.0, R = 118.0
    private static func ang(_ v: Double) -> Double { .pi - (8 - v) / 8 * .pi }
    private static func pt(_ v: Double, _ r: Double) -> CGPoint {
        CGPoint(x: cx + r * cos(ang(v)), y: cy - r * sin(ang(v)))
    }

    private func dialCard(_ ease: Double) -> some View {
        let actNow = 4.8 - (4.8 - 2.1) * ease
        return VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in
                    typealias S = S24View
                    ctx.stroke(dArc(cx: S.cx, cy: S.cy, r: S.R, from: S.ang(8), to: S.ang(0)),
                               with: .color(AP.track), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    ctx.stroke(dArc(cx: S.cx, cy: S.cy, r: S.R, from: S.ang(3.0), to: S.ang(1.8)),
                               with: .color(DC.violet(0.55)), style: StrokeStyle(lineWidth: 16))
                    func tick(_ v: Double, _ c: Color) {
                        ctx.stroke(Path(polyline: [S.pt(v, S.R - 14), S.pt(v, S.R + 14)]), with: .color(c), lineWidth: 3)
                    }
                    tick(4.8, AP.label)
                    tick(1.5, AP.cyan)
                    ctx.stroke(Path(polyline: [CGPoint(x: S.cx, y: S.cy), S.pt(actNow, S.R - 26)]),
                               with: .color(.white), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    ctx.fill(Path(ellipseIn: CGRect(x: S.cx - 6, y: S.cy - 6, width: 12, height: 12)), with: .color(.white))
                }
                .frame(width: 326, height: 150)
                DT(app.tr("8% WORSE"), .mono, 9).foregroundStyle(AP.faint)
                    .frame(maxHeight: .infinity, alignment: .bottom).padding(.leading, 6)
                DT(app.tr("0% BETTER"), .mono, 9).foregroundStyle(AP.faint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).padding(.trailing, 6)
            }
            .frame(width: 324, height: 150, alignment: .topLeading)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    DT(String(format: "%.1f%%", actNow), .barlow, 40, 700, lh: 0.9)
                    DT(app.tr("ACTUAL · EXPECTED") + " " + "1.8–3.0%", .mono, 9).foregroundStyle(AP.label)
                }
                Spacer(minLength: 0)
                DT(app.tr("✓ INSIDE PREDICTION"), .mono, 10, 600).foregroundStyle(AP.green)
            }

            HStack(spacing: 12) {
                DLegend(label: "BEFORE 4.8", color: AP.label)
                DLegend(label: "EXPECTED", color: DC.violet)
                DLegend(label: "ACTUAL", color: .white)
                DLegend(label: "GOAL", color: AP.cyan)
            }
            .foregroundStyle(AP.label)
        }
        .apCard(vertical: 10)
    }

    // MARK: radar — 6 objective axes, before / expected / actual
    private static let axes = ["Fuel accuracy", "Coverage", "Repeatability", "Throttle", "Safety margin", "Thermal"]
    private static let rb: [Double] = [55, 32, 70, 60, 62, 74], re: [Double] = [78, 60, 72, 66, 75, 73], ra: [Double] = [80, 55, 58, 68, 76, 72]
    private static func rp(_ i: Int, _ v: Double) -> CGPoint {
        let a = -Double.pi / 2 + Double(i) * .pi / 3
        // the prototype rounds polygon coordinates to 0.1
        return CGPoint(x: ((163 + 82 * v / 100 * cos(a)) * 10).rounded() / 10, y: ((125 + 82 * v / 100 * sin(a)) * 10).rounded() / 10)
    }
    private static func poly(_ arr: [Double]) -> Path {
        var p = Path(polyline: arr.enumerated().map { rp($0.offset, $0.element) }); p.closeSubpath(); return p
    }

    private func radarCard(_ ease: Double) -> some View {
        let opts: [(String, String)] = [("b", "Before"), ("e", "Expected"), ("a", "Actual")]
        return VStack(alignment: .leading, spacing: 8) {
            DT(app.tr("OBJECTIVE SCORES · 0–100"), .mono, 10).foregroundStyle(AP.label)
            HStack(spacing: 5) {
                ForEach(opts, id: \.0) { k, l in
                    let on = app.rad[k] ?? false
                    DOption(label: (on ? "● " : "○ ") + l, on: on, size: 12, hPad: 4, height: 34) {
                        app.rad[k] = !on
                    }
                }
            }
            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in
                    typealias S = S24View
                    var grid = Path()
                    for g in [25.0, 50, 75, 100] { grid.addPath(S.poly(Array(repeating: g, count: 6))) }
                    ctx.stroke(grid, with: .color(AP.raised), lineWidth: 1)
                    var axes = Path()
                    for i in 0..<6 { axes.move(to: CGPoint(x: 163, y: 125)); axes.addLine(to: S.rp(i, 100)) }
                    ctx.stroke(axes, with: .color(AP.raised), lineWidth: 1)
                    if app.rad["b"] == true {
                        let p = S.poly(S.rb)
                        ctx.fill(p, with: .color(Color(.sRGB, red: 139 / 255, green: 143 / 255, blue: 147 / 255, opacity: 0.15)))
                        ctx.stroke(p, with: .color(AP.label), lineWidth: 1.5)
                    }
                    if app.rad["e"] == true {
                        ctx.stroke(S.poly(S.re), with: .color(DC.violet), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    }
                    if app.rad["a"] == true {
                        let p = S.poly(S.ra.map { $0 * max(0.3, ease) })
                        ctx.fill(p, with: .color(DC.violet(0.28)))
                        ctx.stroke(p, with: .color(DC.violet), lineWidth: 2)
                    }
                }
                .frame(width: 326, height: 250)
                ForEach(0..<6, id: \.self) { i in
                    let p = S24View.rp(i, 128)
                    let d = S24View.ra[i] - S24View.rb[i]
                    let c = d > 3 ? AP.green : d < -3 ? AP.amber : AP.label
                    let txt = "\(Int(S24View.rb[i])) → \(Int(S24View.ra[i]))" + (d >= 0 ? " ▲" : " ▼") + "\(Int(abs(d)))"
                    VStack(spacing: 0) {
                        DT(app.tr(S24View.axes[i]), .sans, 11).foregroundStyle(AP.text2).frame(height: 14)
                        DT(app.tr(txt), .mono, 10).foregroundStyle(c).frame(height: 15)
                    }
                    .fixedSize()
                    .position(x: 163 + 82 * 128 / 100 * cos(-Double.pi / 2 + Double(i) * .pi / 3),
                              y: 125 + 82 * 128 / 100 * sin(-Double.pi / 2 + Double(i) * .pi / 3))
                }
            }
            .frame(width: 324, height: 250, alignment: .topLeading)
        }
        .apCard(vertical: 10)
    }
}
