import SwiftUI

/// S40 · First-session coach marks — three tips over the Live dashboard, shown once on the
/// first visit to Live. White 2 pt spotlight with a rgba(0,0,0,.68) scrim around it.
struct S40View: View {
    @Environment(AppModel.self) private var app
    /// Called when the tips are skipped or finished (S06 uses it to reveal the dashboard).
    var onFinish: () -> Void = {}

    private struct Mark { let t, l, w, h, tip: CGFloat; let title, body: String }
    private static let marks = [
        Mark(t: 6, l: 248, w: 128, h: 40, tip: 60, title: "Always read-only", body: "This lock means AhhPuck can't write to your ECU. It never turns off in this release."),
        Mark(t: 166, l: 14, w: 362, h: 108, tip: 288, title: "Lambda vs target", body: "The big number is the ECU's reading; the cyan number is the target. The colour shows how far off it is."),
        Mark(t: 276, l: 14, w: 362, h: 148, tip: 436, title: "Bands, not just numbers", body: "Each tile shows OK, caution and stop bands from your thresholds. The marker is where the value is now."),
    ]
    /// Header height (padding 10 + Barlow 24 + 2 + mono 11) below the status-bar band.
    private let headerH: CGFloat = 55

    var body: some View {
        let cmI = min(2, app.cm)
        let cm = Self.marks[cmI]
        PhoneScreen(tab: .live, status: "USB-C", statusStyle: .dim, scrolls: false) {
            ScreenHeader(title: "Live", subtitle: "BASELINE · RUN 03")
            ZStack(alignment: .topLeading) {
                Color.clear
                // READ-ONLY pill · top 10 · right 18 · padding 6/9 + 1 border
                HStack(spacing: 6) {
                    Circle().fill(AP.green).frame(width: 7, height: 7)
                    T(app.tr("READ-ONLY"), .mono, 11)
                }
                .apFont(.mono, 11)
                .foregroundStyle(AP.text2)
                .padding(.horizontal, 10).padding(.vertical, 7)
                .outlined(AP.control, radius: 6)
                .fixedSize()
                .frame(width: 390 - 18, alignment: .trailing)
                .offset(y: 10)

                // RPM
                VStack(alignment: .leading, spacing: 4) {
                    BMono(app.tr("RPM"), 10)
                    T("3,820", .barlow, 60, 600).apFont(.barlow, 60, 600, lineHeight: 0.9)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(AP.track)
                            RoundedRectangle(cornerRadius: 3).fill(AP.text).frame(width: g.size.width * 0.48)
                        }
                    }
                    .frame(height: 10)
                }
                .modifier(BBox(x: 18, y: 52, w: 354, h: 108))

                // Lambda
                VStack(alignment: .leading, spacing: 4) {
                    BMono(app.tr("LAMBDA · ECU O₂ · INFERRED"), 10)
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        T("0.902", .barlow, 44, 600).apFont(.barlow, 44, 600).foregroundStyle(AP.green)
                        T("→ 0.880", .mono, 14).apFont(.mono, 14).foregroundStyle(AP.cyan)
                    }
                }
                .modifier(BBox(x: 18, y: 170, w: 354, h: 100))

                // Tiles: 64 pt tall, so the band bar is squeezed to nothing (as in the design).
                ForEach(Array([("COOLANT", "97 °C"), ("INTAKE", "38 °C"), ("OIL PRESS", "3.8 bar"), ("BATTERY", "13.8 V")].enumerated()), id: \.offset) { i, x in
                    VStack(alignment: .leading, spacing: 4) {
                        BMono(app.tr(x.0), 10)
                        T(x.1, .barlow, 22, 600).apFont(.barlow, 22, 600)
                    }
                    .modifier(BBox(x: i % 2 == 0 ? 18 : 199, y: i < 2 ? 280 : 352, w: 173, h: 64))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .overlay(alignment: .topLeading) {
          GeometryReader { geo in
            // Same band height PhoneScreen reserves: max(50, the device's status bar).
            let areaTop = max(Metrics.statusBar, geo.safeAreaInsets.top) + headerH
            ZStack(alignment: .topLeading) {
                // Scrim with a rounded hole (box-shadow 0 0 0 999px), then the 2 pt white ring.
                let hole = CGRect(x: cm.l, y: areaTop + cm.t, width: cm.w + 4, height: cm.h + 4)
                Canvas { ctx, size in
                    var p = Path(CGRect(origin: .zero, size: size))
                    p.addPath(Path(roundedRect: hole, cornerRadius: 12))
                    ctx.fill(p, with: .color(.black.opacity(0.68)), style: FillStyle(eoFill: true))
                    ctx.stroke(Path(roundedRect: hole.insetBy(dx: 1, dy: 1), cornerRadius: 11), with: .color(.white), lineWidth: 2)
                }
                .allowsHitTesting(false)

                tooltip(cmI: cmI, cm: cm)
                    .padding(.horizontal, Metrics.gutter)
                    .offset(y: areaTop + cm.tip)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
          }
          .ignoresSafeArea()
        }
    }

    private func tooltip(cmI: Int, cm: Mark) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            BMono(app.tr("TIP \(cmI + 1) OF 3"), 10, 600, AP.ink)
            T(app.tr(cm.title), .barlow, 24, 700).apFont(.barlow, 24, 700, lineHeight: 1).foregroundStyle(AP.ink)
            BSans(app.tr(cm.body), 13, 400, AP.ink, lh: 1.45).fixedSize(horizontal: false, vertical: true)
            HStack {
                T(app.tr("Skip tips"), .sans, 13).apFont(.sans, 13).underline()
                    .foregroundStyle(Color.bDim2)
                    .contentShape(Rectangle())
                    .onTapGesture { app.cm = 0; onFinish() }
                Spacer(minLength: 0)
                BSans(app.tr(app.cm < 2 ? "Next" : "Done"), 13, 600, .white)
                    .padding(.vertical, 8).padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AP.ink))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if app.cm >= 2 { app.cm = 0; onFinish() } else { app.cm += 1 }
                    }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(AP.text))
    }
}

/// An absolutely positioned border-box card (`position:absolute; box-sizing:border-box;
/// padding:10px 12px; border:1px #23262a; r12`) inside a top-leading ZStack.
struct BBox: ViewModifier {
    var x, y, w, h: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 11).padding(.horizontal, 13)
            .frame(width: w, height: h, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 12).fill(AP.card))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AP.border, lineWidth: 1))
            .offset(x: x, y: y)
    }
}
