import SwiftUI

/// S27 · Gains dashboard (Review tab root). 236 pt ring (r 96, stroke 20): share of the distance
/// to the goal — green verified, violet unproven, track #1c1f22 — easing in over ~2.2 s (cubic).
struct S27View: View {
    @Environment(AppModel.self) private var app
    @State private var ring = DRing.shared

    var body: some View {
        PhoneScreen(tab: .review, status: "OFFLINE", statusStyle: .dim) {
            ScreenHeader(title: "Gains", subtitle: app.persistedComparison == nil ? "DRIVABILITY · GOAL ≤ 1.5% AVG ERROR" : "LOCAL EVIDENCE · READ-ONLY")
            if let comparison = app.persistedComparison {
                realEvidenceView(comparison)
            } else {
                DEased { ease in
                    VStack(spacing: 0) {
                        ringView(ease)
                            .padding(.top, 4)
                            .contentShape(Rectangle())
                            .onTapGesture { ring.replay() }
                        legend.padding(.top, 2).padding(.horizontal, Metrics.gutter)
                        // Review root → the assessment screens (no buttons in the design).
                        stepCard(ease).contentShape(Rectangle()).onTapGesture { app.router.go(.S22) }.block()
                        cellsCard.contentShape(Rectangle()).onTapGesture { app.router.go(.S23) }.block()
                    }
                }
            }
            Spacer(minLength: 0)
        }
        // Tab roots are all mounted at launch, so play the ring when Review is shown.
        .onAppear { ring.replay() }
        .onChange(of: app.router.tab) { _, t in if t == .review { ring.replay() } }
    }

    private func realEvidenceView(_ comparison: MobileRunComparison) -> some View {
        let title: String
        let color: Color
        switch comparison.decision {
        case .improvementConfirmed: title = "REPEAT CONFIRMED"; color = AP.green
        case .repeatRequired: title = "REPEAT REQUIRED"; color = AP.amber
        case .regression: title = "REGRESSION"; color = AP.red
        case .insufficientData: title = "INSUFFICIENT DATA"; color = AP.label
        }
        return VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                DT("EVIDENCE ASSESSMENT", .mono, 10).foregroundStyle(AP.label)
                DT(title, .barlow, 30, 700).foregroundStyle(color)
                DT("No ECU write decision is produced. This result only describes the captured runs.", .sans, 12, lh: 1.35)
                    .foregroundStyle(AP.text2)
            }
            .apCard()

            HStack(spacing: 6) {
                realMetric("BASE ERROR", comparison.baselineLambdaError.map { String(format: "%.3f", $0) } ?? "—", AP.baseline)
                realMetric("CAND ERROR", comparison.candidateLambdaError.map { String(format: "%.3f", $0) } ?? "—", AP.candidate)
                realMetric("REPEAT Δ", comparison.repeatDelta.map { String(format: "%.3f", $0) } ?? "—", color)
            }

            VStack(alignment: .leading, spacing: 7) {
                DT("DECISION", .mono, 10).foregroundStyle(AP.label)
                DT(decisionText(comparison.decision), .sans, 14, 600)
                DT("Comparison uses only decoded, persisted telemetry frames. Unknown ECU bytes remain excluded.", .mono, 10, lh: 1.4)
                    .foregroundStyle(AP.text3)
            }
            .apCard()
            .contentShape(Rectangle())
            .onTapGesture { app.router.go(.S22) }
        }
        .block(top: 10)
    }

    private func realMetric(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            DT(value, .barlow, 21, 700).foregroundStyle(color)
            DT(label, .mono, 8).foregroundStyle(AP.label)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .outlined(AP.border, radius: 10)
    }

    private func decisionText(_ decision: MobileRunComparison.Decision) -> String {
        switch decision {
        case .improvementConfirmed: return "The candidate improvement repeated within tolerance."
        case .repeatRequired: return "The candidate changed, but the repeat did not confirm it."
        case .regression: return "The candidate is no better than baseline. Preserve evidence and investigate."
        case .insufficientData: return "More valid frames are required before comparing runs."
        }
    }

    private func ringView(_ ease: Double) -> some View {
        let C = 2 * Double.pi * 96, tot = 5.6
        var segs: [(Double, Double)] = []      // (start, length) as fractions of the circumference
        var acc = 0.0
        for L in [1.5, 0.8, 2.7] {
            let st = acc / tot * C * ease, len = max(0, L / tot * C * ease - 3)
            segs.append((st / C, len / C)); acc += L
        }
        let pct = Int((5 / 5.6 * 100 * ease).rounded())
        return ZStack {
            ZStack {
                Circle().stroke(AP.selectedRow, lineWidth: 20)
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .trim(from: segs[i].0, to: segs[i].0 + segs[i].1)
                        .stroke(i == 2 ? DC.violet.opacity(0.75) : AP.green, style: StrokeStyle(lineWidth: 20))
                        .rotationEffect(.degrees(-90))
                }
            }
            .frame(width: 192, height: 192)
            VStack(spacing: 2) {
                DT("\(pct)%", .barlow, 64, 700, lh: 0.9)
                DT(app.tr("OF THE WAY TO GOAL"), .mono, 10).foregroundStyle(AP.label)
                (T(app.tr("7.1% →") + " ", .mono, 11)
                 + T(app.tr("2.1%"), .mono, 11, 600).foregroundColor(.white)
                 + T(" " + app.tr("· GOAL 1.5%"), .mono, 11))
                    .apFont(.mono, 11)
                    .frame(height: 17)
                    .padding(.top, 4)
            }
            .fixedSize()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 236)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            DLegend(label: "VERIFIED −2.3", color: AP.green, font: 10)
            DLegend(label: "UNPROVEN −2.7", color: DC.violet, font: 10)
            DLegend(label: "LEFT 0.6", color: AP.raised, size: 12, font: 10, border: DC.hatchStripe)
        }
        .foregroundStyle(AP.text3)
        .frame(maxWidth: .infinity)
    }

    private func bar(_ label: String, _ value: String, valueColor: Color, frac: Double, color: Color) -> some View {
        VStack(spacing: 3) {
            HStack {
                DT(app.tr(label), .mono, 10)
                Spacer(minLength: 0)
                DT(value, .mono, 10).foregroundStyle(valueColor)
            }
            .foregroundStyle(AP.label)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(AP.selectedRow)
                    RoundedRectangle(cornerRadius: 3).fill(color).frame(width: g.size.width * frac)
                }
            }
            .frame(height: 10)
        }
    }

    private func stepCard(_ ease: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                DT(app.tr("THIS STEP · EXP-04"), .mono, 10).foregroundStyle(AP.label)
                Spacer(minLength: 0)
                DT(app.tr("! NEEDS REPEAT"), .mono, 10, 600).foregroundStyle(AP.ink)
                    .padding(.vertical, 3).padding(.horizontal, 7)
                    .background(RoundedRectangle(cornerRadius: 4).fill(AP.amber))
            }
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    DT("−2.7", .barlow, 52, 700, lh: 0.9).foregroundStyle(DC.violet)
                    DT(app.tr("PTS") + " " + app.tr(app.base.lamLabel) + " " + app.tr("ERROR"), .mono, 9).foregroundStyle(AP.label)
                }
                .fixedSize()
                VStack(spacing: 7) {
                    bar("BEFORE", "4.8%", valueColor: AP.label, frac: 4.8 / 8, color: AP.label)
                    bar("AFTER", "2.1%", valueColor: .white, frac: 2.1 / 8 * max(0.2, ease), color: DC.violet)
                }
            }
        }
        .apCard()
    }

    private var cellsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                DT(app.tr("CELLS ON TARGET"), .mono, 10).foregroundStyle(AP.label)
                Spacer(minLength: 0)
                (T("22 → ", .mono, 11)
                 + T("29", .mono, 11, 600).foregroundColor(.white)
                 + T(" ", .mono, 11)
                 + T("+7", .mono, 11).foregroundColor(DC.violet)
                 + T(" / 38", .mono, 11))
                    .apFont(.mono, 11)
                    .frame(height: 17)
            }
            let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: 19)
            LazyVGrid(columns: cols, spacing: 4) {
                ForEach(0..<38, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(i < 22 ? AP.label : i < 29 ? DC.violet : .clear)
                        .overlay { if i >= 29 { RoundedRectangle(cornerRadius: 3).strokeBorder(DC.hatchStripe, lineWidth: 1) } }
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            HStack(spacing: 14) {
                DLegend(label: "ALREADY ON TARGET", color: AP.label)
                DLegend(label: "GAINED THIS STEP", color: DC.violet)
            }
            .foregroundStyle(AP.label)
        }
        .apCard()
    }
}
