import SwiftUI

/// S20 · Gain curve — power (estimated) / accel / lambda error, the noise band and a cursor delta
/// with a verdict (port of `modes`, `gBase/gCand/gNoise`, `gVals`, `gVerdict`).
struct S20View: View {
    @Environment(AppModel.self) private var app

    struct Mode {
        let k, unit, tag: String; let tc: Color; let hi: Bool; let dp: Int; let u: String
        let b: (Double) -> Double, c: (Double) -> Double, n: (Double) -> Double
    }

    static func modes(_ lamLabel: String) -> [Mode] {
        let pb = { (x: Double) in 38 + 72 * x - 28 * x * x + 2 * sin(x * 9) }
        let pcand = { (x: Double) in pb(x) * 1.004 + (x > 0.65 ? (x - 0.65) * 6 : 0) }
        let ex = { (x: Double) in 1.4 + 3.6 * max(0, x - 0.45) * 1.8 + 0.8 * sin(x * 8) * 0.5 + 0.6 }
        return [
            Mode(k: "Power (est.)", unit: "EST. WHEEL POWER · kW", tag: "INFERRED · PHONE ACCEL ±3%", tc: AP.amber, hi: true, dp: 1, u: " kW",
                 b: pb, c: pcand, n: { pb($0) * 0.03 }),
            Mode(k: "Accel", unit: "LONGITUDINAL ACCEL · g", tag: "OBSERVED · CALIBRATED MOUNT", tc: AP.label, hi: true, dp: 3, u: " g",
                 b: { pb($0) / (95 + 120 * $0) }, c: { pcand($0) / (95 + 120 * $0) }, n: { pb($0) / (95 + 120 * $0) * 0.03 }),
            Mode(k: lamLabel == "AFR" ? "AFR err" : "λ error", unit: "ABS " + lamLabel + " ERROR · %", tag: "OBSERVED · ECU STREAM", tc: AP.label, hi: false, dp: 1, u: "%",
                 b: ex, c: { ex($0) * 0.5 }, n: { _ in 0.3 }),
        ]
    }

    var body: some View {
        let b = app.base
        let ms = S20View.modes(b.lamLabel)
        let md = ms[app.gMode]
        let GN = 80
        let gx = { (i: Int) in Double(i) / Double(GN - 1) }
        var allv: [Double] = []
        for i in 0..<GN { let x = gx(i); allv += [md.b(x) + md.n(x), md.b(x) - md.n(x), md.c(x)] }
        let mn = allv.min()!, mx = allv.max()!
        let yG = { (y: Double) in 172 - (y - mn) / (mx - mn == 0 ? 1 : mx - mn) * 164 }
        let pt = { (x: Double, y: Double) in CGPoint(x: Double(cFixed(x * 326, 1))!, y: Double(cFixed(yG(y), 1))!) }
        let base = (0..<GN).map { pt(gx($0), md.b(gx($0))) }
        let cand = (0..<GN).map { pt(gx($0), md.c(gx($0))) }
        let nUp = (0..<GN).map { pt(gx($0), md.b(gx($0)) + md.n(gx($0))) }
        let nDn = (0..<GN).map { pt(gx($0), md.b(gx($0)) - md.n(gx($0))) }
        let cx = app.gCur / 100, bv = md.b(cx), cvv = md.c(cx), dlt = cvv - bv, dp = dlt / bv * 100, nz = md.n(cx)
        let gX = Double(cFixed(cx * 326, 1))!
        let rpm = BaseVals.grouped(Int((2500 + cx * 4500).rounded()))
        let good = md.hi ? dlt > 0 : dlt < 0
        let (verdict, vc, note): (String, Color, String) = abs(dlt) < nz
            ? ("≈ WITHIN NOISE", AP.label, "Change smaller than run-to-run noise.")
            : good ? ("✓ REAL GAIN", AP.green, "Change clears the noise band here.")
            : ("! LOSS", AP.amber, "Candidate is worse at this RPM.")
        let vals: [(String, String, Color)] = [
            ("BASELINE", cFixed(bv, md.dp) + md.u, AP.text3),
            ("CANDIDATE", cFixed(cvv, md.dp) + md.u, AP.candidate),
            ("CHANGE", (dp > 0 ? "+" : "") + cFixed(dp, 1) + "%", .white),
        ]

        PhoneScreen(tab: .runs, status: "OFFLINE", statusStyle: .dim) {
            ScreenHeader(title: "Gain curve", subtitle: "3RD GEAR PULL · 2,500–7,000 RPM")

            HStack(spacing: 5) {
                ForEach(Array(ms.enumerated()), id: \.offset) { i, m in
                    let on = app.gMode == i
                    T(app.tr(m.k), .sans, 12).apFont(.sans, 12)
                        .foregroundStyle(CSel.fg(on)).lineLimit(1).fixedSize()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 8).fill(CSel.bg(on)))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(CSel.border(on), lineWidth: 1))
                        .contentShape(Rectangle())
                        .onTapGesture { app.gMode = i }
                }
            }
            .block(top: 12)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    T(app.tr(md.unit), .mono, 10).apFont(.mono, 10).foregroundStyle(AP.label)
                    Spacer(minLength: 0)
                    T(app.tr(md.tag), .mono, 9).apFont(.mono, 9).foregroundStyle(md.tc)
                }
                .frame(height: 13)
                Canvas { ctx, _ in
                    for y in [45.0, 90, 135] {
                        var l = Path(); l.move(to: CGPoint(x: 0, y: y)); l.addLine(to: CGPoint(x: 326, y: y))
                        ctx.stroke(l, with: .color(AP.track), lineWidth: 1)
                    }
                    var band = Path(polyline: nUp)
                    for p in nDn.reversed() { band.addLine(to: p) }
                    band.closeSubpath()
                    ctx.fill(band, with: .color(Color(.sRGB, red: 139 / 255, green: 143 / 255, blue: 147 / 255, opacity: 0.18)))
                    ctx.stroke(Path(polyline: base), with: .color(AP.label), lineWidth: 1.5)
                    ctx.stroke(Path(polyline: cand), with: .color(AP.candidate), lineWidth: 2)
                    var c = Path(); c.move(to: CGPoint(x: gX, y: 0)); c.addLine(to: CGPoint(x: gX, y: 180))
                    ctx.stroke(c, with: .color(AP.text), lineWidth: 1)
                }
                .frame(width: 326, height: 180)
                HStack(spacing: 0) {
                    T("2.5k", .mono, 9)
                    Spacer(minLength: 0)
                    T(app.tr("CURSOR") + " " + rpm + " " + app.tr("RPM"), .mono, 9)
                    Spacer(minLength: 0)
                    T("7k", .mono, 9)
                }
                .apFont(.mono, 9, lineHeight: 11 / 9).foregroundStyle(AP.faint)
                CRange(value: Binding(get: { app.gCur }, set: { app.gCur = $0 }))
            }
            .apCard(vertical: 10, horizontal: 14)
            .block(top: 10)

            HStack(spacing: 6) {
                ForEach(vals, id: \.0) { k, v, c in
                    VStack(alignment: .leading, spacing: 2) {
                        T(app.tr(k), .mono, 10).apFont(.mono, 10, lineHeight: 13 / 10).foregroundStyle(AP.label).lineLimit(1)
                        T(v, .barlow, 22, 600).apFont(.barlow, 22, 600, lineHeight: 26 / 22).foregroundStyle(c).lineLimit(1).fixedSize()
                    }
                    .padding(.vertical, 9).padding(.horizontal, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .outlined(AP.border, radius: 10)
                }
            }
            .block(top: 10)

            HStack {
                T(app.tr(note), .sans, 12).apFont(.sans, 12, lineHeight: 15 / 12).foregroundStyle(AP.text2)
                Spacer(minLength: 4)
                T(app.tr(verdict), .mono, 10, 600).apFont(.mono, 10, 600).foregroundStyle(vc).lineLimit(1).fixedSize()
            }
            .padding(.vertical, 11).padding(.horizontal, 13)
            .outlined(AP.control, radius: 10)
            .block(top: 8)

            Spacer(minLength: 0)
        }
    }
}
