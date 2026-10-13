import SwiftUI

/// S39 · Live · phone-only mode — what Live shows with no ECU connected.
struct S39View: View {
    @Environment(AppModel.self) private var app

    private struct Tile { let k, v, src: String; let c: Color; let sub: String }

    var body: some View {
        let t = Double(app.t)
        let poSpeed = Int((62 + sin(t / 9) * 12).rounded())
        let tiles = [
            Tile(k: "LONG G", v: "+0.31 g", src: "PHONE", c: AP.text, sub: "LIVE"),
            Tile(k: "LAT G", v: "−0.08 g", src: "PHONE", c: AP.text, sub: "LIVE"),
            Tile(k: "RPM", v: "—", src: "ECU", c: .bDim2, sub: "ECU NOT CONNECTED"),
            Tile(k: "LAMBDA", v: "—", src: "ECU", c: .bDim2, sub: "ECU NOT CONNECTED"),
            Tile(k: "COOLANT", v: "—", src: "ECU", c: .bDim2, sub: "ECU NOT CONNECTED"),
            Tile(k: "OIL PRESS", v: "—", src: "EXT", c: .bDim2, sub: "VIA ECU ADAPTER"),
        ]
        PhoneScreen(tab: .live, status: "", statusStyle: .dim) {
            ScreenHeader(title: "Live", subtitle: "NO ECU · PHONE DATA ONLY")

            // Amber banner with Connect ECU
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    BSans(app.tr("! ECU not connected"), 14, 600, AP.ink)
                    BSans(app.tr("Engine values are unavailable. Speed and g-force come from the phone."), 12, 400, AP.ink, lh: 1.35)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                BSans(app.tr("Connect ECU"), 12, 600, .white)
                    .lineLimit(1)
                    .padding(.vertical, 8).padding(.horizontal, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(AP.ink))
                    .fixedSize()
                    .contentShape(Rectangle())
                    .onTapGesture { app.router.go(.S04) }
            }
            .padding(.vertical, 12).padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: 12).fill(AP.amber))
            .block(top: 12)

            // GPS speed hero
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    BMono(app.tr("SPEED"), 10)
                    Spacer(minLength: 0)
                    BMono(app.tr("PHONE · GPS · INFERRED"), 9, 400, AP.text3)
                }
                (T(String(poSpeed), .barlow, 72, 600)
                 + T(app.tr(" km/h"), .barlow, 20, 600).foregroundColor(AP.label))
                    .apFont(.barlow, 72, 600, lineHeight: 0.9)
                    .lineLimit(1)
            }
            .apCard()
            .block()

            // Phone g-force + ECU tiles
            BGrid2(items: tiles) { x in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        BMono(app.tr(x.k), 10)
                        Spacer(minLength: 0)
                        BMono(app.tr(x.src), 9, 400, AP.faint).lineLimit(1).fixedSize()
                    }
                    T(app.tr(x.v), .barlow, 26, 600).apFont(.barlow, 26, 600, lineHeight: 1)
                        .foregroundStyle(x.c).lineLimit(1)
                    BMono(app.tr(x.sub), 9, 400, AP.faint)
                }
                .apCard(vertical: 10, horizontal: 12)
            }
            .block()

            VStack(alignment: .leading, spacing: 8) {
                BMono(app.tr("RECORDING IN THIS MODE"), 10)
                BSans(app.tr("Saved as phone-only: no assessment, no proposals, no engine safety limits."), 13, 400, AP.text2, lh: 1.45)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .apCard()
            .block()

            // `margin:auto 18px 12px` on the button and `margin-top:auto` on the tab bar share the slack.
            Spacer(minLength: 0)
            BOutlineButton(label: "Record phone-only run")
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 12)
            Spacer(minLength: 0)
        }
    }
}
