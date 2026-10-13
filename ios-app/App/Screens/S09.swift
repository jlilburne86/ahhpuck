import SwiftUI

/// S09 · Map trace — 12×10 RPM × load grid, white 2 pt outline on the current cell, error / coverage toggle.
struct S09View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let b = app.base, err = app.mode == "err"
        let legend: [Gradient.Stop] = err
            ? [.init(color: .oklch(0.58, 0.16, 245), location: 0), .init(color: AP.mapOnTarget, location: 0.38),
               .init(color: AP.mapOnTarget, location: 0.55), .init(color: AP.mapLean, location: 0.72), .init(color: AP.mapVeryLean, location: 1)]
            : [.init(color: .oklch(0.24, 0.01, 250), location: 0), .init(color: .oklch(0.86, 0.01, 250), location: 1)]
        let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 12)

        PhoneScreen(tab: .map) {
            AHeader(title: "Fuel table trace", sub: app.tr("AXES INFERRED · TABLE VALUES NOT READ"))

            HStack(spacing: 0) {
                seg(app.tr(b.lamLabel + " error"), on: err) { app.mode = "err" }
                seg(app.tr("Coverage (hits)"), on: !err) { app.mode = "cov" }
            }
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 8).fill(AP.card))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(AP.border, lineWidth: 1))
            .block(top: 12)

            HStack(alignment: .top, spacing: 4) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(Array(b.loadAxis.enumerated()), id: \.offset) { i, a in
                        if i > 0 { Spacer(minLength: 0) }
                        M(String(a), .mono, 9, color: AP.faint, translate: false)
                    }
                }
                .padding(.vertical, 4)
                .frame(width: 22, height: 10 * 30 + 9 * 2, alignment: .trailing)
                VStack(spacing: 4) {
                    LazyVGrid(columns: cols, spacing: 2) {
                        ForEach(Array(b.cells.enumerated()), id: \.offset) { _, c in
                            M(c.label, .mono, 9, color: c.fg, translate: false)
                                .frame(maxWidth: .infinity).frame(height: 30)
                                .background(RoundedRectangle(cornerRadius: 3).fill(c.bg))
                                .overlay { if c.current { RoundedRectangle(cornerRadius: 3).stroke(Color.white, lineWidth: 2) } }
                                .zIndex(c.current ? 1 : 0)
                        }
                    }
                    HStack(spacing: 0) {
                        ForEach(Array(b.rpmAxis.enumerated()), id: \.offset) { _, a in
                            M(a, .mono, 9, color: AP.faint, translate: false).frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.leading, 6).padding(.trailing, 10).padding(.top, 12)

            HStack {
                M("↑ LOAD %", .mono, 10, color: AP.faint)
                Spacer()
                M("RPM ×1000 →", .mono, 10, color: AP.faint)
            }
            .block(top: 4)

            HStack(spacing: 8) {
                M(b.legendL, .mono, 10, color: AP.label)
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(stops: legend, startPoint: .leading, endPoint: .trailing))
                    .frame(height: 6)
                M(b.legendR, .mono, 10, color: AP.label)
            }
            .block()

            HStack(alignment: .top, spacing: 8) {
                readout("CELL", b.cellName, AP.text)
                readout("HITS", String(b.cellHits), AP.text)
                readout("MEAN ERR", b.lamErr, b.lamColor)
            }
            .apCard()
            .contentShape(Rectangle())
            .onTapGesture { app.router.go(.S21) }   // → map before / after
            .block(top: 12)

            M("38 of 120 cells have ≥10 samples. Upper-right cells are unvisited — no claim is made about them.", .sans, 13, color: AP.text3, lineHeight: 1.45)
                .block()
            Spacer(minLength: 0)
        }
    }

    private func seg(_ label: String, on: Bool, action: @escaping () -> Void) -> some View {
        M(label, .sans, 13, color: on ? AP.text : AP.label, translate: false)
            .frame(maxWidth: .infinity)
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 6).fill(on ? AP.disabled : .clear))
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }

    private func readout(_ k: String, _ v: String, _ c: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            M(k, .mono, 10, color: AP.label)
            M(v, .barlow, 22, 600, color: c, translate: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
