import SwiftUI

/// S19 · Run overlay — lambda vs target for baseline / candidate / repeat, RPM and ignition,
/// a shared scrub cursor and per-run readouts (port of `runs`, `p*`, `cursor*` in `baseVals`).
struct S19View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let b = app.base
        PhoneScreen(tab: .runs, status: "OFFLINE") {
            ScreenHeader(title: "Experiment 04", subtitle: "3RD GEAR PULL · 2500–7000 · DRIVABILITY")

            VStack(spacing: 6) {
                ForEach(b.runs, id: \.name) { r in
                    HStack(spacing: 10) {
                        Rectangle().fill(r.color).frame(width: 14, height: 3)
                        T(app.tr(r.name), .sans, 13, 500).apFont(.sans, 13, 500).frame(width: 78, alignment: .leading)
                        T(r.hash, .mono, 11).apFont(.mono, 11).foregroundStyle(AP.label).frame(maxWidth: .infinity, alignment: .leading)
                        T(r.err, .mono, 12).apFont(.mono, 12)
                    }
                    .frame(height: 17)
                    .apCard(vertical: 8, horizontal: 12, radius: 10)
                }
            }
            .block(top: 12)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    T(app.tr(b.lamLabel), .mono, 10)
                    Spacer(minLength: 0)
                    T(app.tr("CURSOR") + " " + b.cursorRpm + " " + app.tr("RPM"), .mono, 10)
                }
                .apFont(.mono, 10).foregroundStyle(AP.label)
                .padding(.horizontal, 4)

                Canvas { ctx, _ in
                    for y in [42.0, 85, 128] {
                        var l = Path(); l.move(to: CGPoint(x: 0, y: y)); l.addLine(to: CGPoint(x: 332, y: y))
                        ctx.stroke(l, with: .color(AP.raised), lineWidth: 1)
                    }
                    ctx.stroke(Path(polyline: b.pTarget), with: .color(AP.cyan), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                    ctx.stroke(Path(polyline: b.pBase), with: .color(AP.baseline), lineWidth: 1.4)
                    ctx.stroke(Path(polyline: b.pRep), with: .color(AP.repeatTrace.opacity(0.7)), lineWidth: 1.2)
                    ctx.stroke(Path(polyline: b.pCand), with: .color(AP.candidate), lineWidth: 1.8)
                    var c = Path(); c.move(to: CGPoint(x: b.cursorX, y: 0)); c.addLine(to: CGPoint(x: b.cursorX, y: 170))
                    ctx.stroke(c, with: .color(AP.text), lineWidth: 1)
                }
                .frame(width: 332, height: 170)

                VStack(spacing: 0) {
                    Rectangle().fill(AP.border).frame(height: 1)
                    HStack {
                        T(app.tr("RPM"), .mono, 10)
                        Spacer(minLength: 0)
                        T(app.tr("IGN °"), .mono, 10)
                        Spacer(minLength: 0)
                        T(app.tr("KNOCK"), .mono, 10)
                    }
                    .apFont(.mono, 10, lineHeight: 13 / 10).foregroundStyle(AP.label)
                    .padding(.horizontal, 4).padding(.top, 6)
                }

                Canvas { ctx, _ in
                    ctx.stroke(Path(polyline: b.pRpm), with: .color(AP.text3), lineWidth: 1.2)
                    ctx.stroke(Path(polyline: b.pIgn), with: .color(AP.label), style: StrokeStyle(lineWidth: 1.2, dash: [3, 2]))
                    var c = Path(); c.move(to: CGPoint(x: b.cursorX, y: 0)); c.addLine(to: CGPoint(x: b.cursorX, y: 56))
                    ctx.stroke(c, with: .color(AP.text), lineWidth: 1)
                }
                .frame(width: 332, height: 56)

                CRange(value: Binding(get: { app.cursor }, set: { app.cursor = $0 }))
                    .padding(.top, 4)
            }
            .padding(.top, 12).padding(.bottom, 8).padding(.horizontal, 10)
            .padding(1)
            .background(RoundedRectangle(cornerRadius: 12).fill(AP.card))
            .outlined(AP.border, radius: 12)
            .block(top: 12)

            HStack(spacing: 8) {
                ForEach(b.cursorVals, id: \.k) { v in
                    VStack(alignment: .leading, spacing: 2) {
                        T(app.tr(v.k), .mono, 10).apFont(.mono, 10, lineHeight: 13 / 10).foregroundStyle(AP.label)
                        T(v.v, .barlow, 22, 600).apFont(.barlow, 22, 600, lineHeight: 26 / 22).foregroundStyle(v.color)
                    }
                    .padding(.vertical, 9).padding(.horizontal, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .outlined(AP.border, radius: 10)
                }
            }
            .block(top: 10)

            Spacer(minLength: 0)
        }
    }
}
