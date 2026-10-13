import SwiftUI

/// S23 · Expected vs actual — the S16 range bars plus a white "actual" dot, and the prediction track record.
struct S23View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let b = app.base
        let actVals: [Double] = [2.1, 29, 1, 0, 86.9, 0.8, 6.44]
        let rows = CMetrics.metrics(1, lamLabel: b.lamLabel).enumerated().map { CMetrics.row($1, act: actVals[$0]) }
        let nIn = rows.filter { $0.vc == AP.green }.count
        let tr = [1, 1, 0, 1, 1, 1, 0, 1, 1, 1]

        PhoneScreen(tab: .review, scrolls: false) {
            AHeader(title: "Expected vs actual", sub: app.tr("EXP-04 · PREDICTED AT ±1.0% STEP"))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        M("PREDICTION CHECK", .mono, 10, color: AP.label)
                        M("\(nIn) of 7 landed in range", .barlow, 26, 700, lineHeight: 1)
                    }
                    Spacer()
                    M("! 1 MISSED", .mono, 10, 600, color: AP.ink).lineLimit(1).fixedSize()
                        .padding(.vertical, 4).padding(.horizontal, 7)
                        .background(RoundedRectangle(cornerRadius: 4).fill(AP.amber))
                }
                M("The 60–120 time missed because the repeat ran partly in 2nd gear. That's why the gate asks for another repeat.", .sans, 12, color: AP.text3, lineHeight: 1.45)
            }
            .apCard()
            .block()

            DFlow(spacing: 12, lineSpacing: 6) {
                legend("NOW") { Rectangle().fill(AP.text3).frame(width: 2, height: 10) }
                legend("EXPECTED RANGE") {
                    RoundedRectangle(cornerRadius: 2).fill(AP.candidate.opacity(0.55))
                        .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(AP.candidate, lineWidth: 1))
                        .frame(width: 16, height: 10)
                }
                legend("RUN-TO-RUN NOISE") { Hatch(a: Color(hex: 0x4a4f54), b: .clear, stripe: 3).frame(width: 14, height: 8) }
                legend("ACTUAL") { Circle().fill(Color.white).frame(width: 9, height: 9) }
            }
            .block(top: 8)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, r in CMetricRow(r: r, actual: true) }
                }
                .padding(1)
            }
            .frame(maxHeight: .infinity)
            .scrollIndicators(.hidden)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AP.border, lineWidth: 1))
            .block(top: 8)
            .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    M("PREDICTION TRACK RECORD", .mono, 10, color: AP.label)
                    Spacer()
                    M("8 / 10 IN RANGE", .mono, 11)
                }
                HStack(spacing: 5) {
                    ForEach(Array(tr.enumerated()), id: \.offset) { _, x in
                        T(x == 1 ? "✓" : "!", .sans, 10, 700).apFont(.sans, 10, 700).foregroundStyle(AP.ink)
                            .frame(maxWidth: .infinity).frame(height: 20)
                            .background(RoundedRectangle(cornerRadius: 4).fill(x == 1 ? AP.green : AP.amber))
                    }
                }
            }
            .apCard()
            .padding(.horizontal, Metrics.gutter)
        }
    }

    private func legend<S: View>(_ label: String, @ViewBuilder _ swatch: () -> S) -> some View {
        HStack(spacing: 5) {
            swatch()
            M(label, .mono, 9, color: AP.label)
        }
        .fixedSize()
    }
}
