import SwiftUI
import UniformTypeIdentifiers

/// S30 · Learning ledger (Runs tab root) — experiment cards with a decision stripe and filters.
/// Tuner density adds each run's hash.
struct S30View: View {
    @Environment(AppModel.self) private var app
    @State private var importPresented = false

    struct Exp { let id, title, dec, date, res, h: String }
    static let exps: [Exp] = [
        Exp(id: "EXP-04", title: "High-load fuel −1.0%", dec: "Repeat", date: "13 Oct", res: "λ err 4.8 → 2.1% · repeat unproven", h: "sha 81d0…4b07"),
        Exp(id: "EXP-03", title: "Mid-band fuel +0.8%", dec: "Accept", date: "06 Oct", res: "λ err 5.6 → 4.8% · reference", h: "sha 3f9a…c21e"),
        Exp(id: "EXP-02", title: "Idle fuel −0.5%", dec: "Rollback", date: "29 Sep", res: "Idle hunting +40 rpm", h: "sha 2c71…e0aa"),
        Exp(id: "EXP-01", title: "Cruise fuel +1.2%", dec: "Accept", date: "22 Sep", res: "λ err 7.1 → 5.6%", h: "sha 9b03…71fd"),
        Exp(id: "BASE-01", title: "Baseline captured", dec: "Baseline", date: "15 Sep", res: "18,420 frames · 31 Hz", h: "sha 1e44…0c9b"),
        Exp(id: "EXP-00", title: "Pre-check pull", dec: "Abort", date: "14 Sep", res: "Knock ×2 at 5,800 rpm", h: "sha 6d2a…b310"),
    ]

    var body: some View {
        let rows = S30View.exps.filter { app.filt == "All" || $0.dec == app.filt }
        PhoneScreen(tab: .runs, status: "OFFLINE", statusStyle: .dim) {
            ScreenHeader(title: "Ledger", subtitle: app.tr("AE86 · 4A-GE 20V BLACKTOP ·") + " " + app.tr(app.runsLoaded && !app.persistedRuns.isEmpty ? "REAL CAPTURES" : "DEMO REPLAY"))

            HStack(spacing: 8) {
                PrimaryButton(label: "Import run JSON", height: 44) { importPresented = true }
                PrimaryButton(label: "Capture baseline", fill: AP.raised, fg: AP.text, height: 44) { app.router.go(.S04) }
            }
            .block(top: 10)

            if let runImportError = app.runImportError {
                DT(runImportError, .mono, 10).foregroundStyle(AP.red).block(top: 6)
            }

            if let comparison = app.persistedComparison {
                evidenceSummary(comparison)
                    .block(top: 12)
            } else if app.runsLoaded && app.persistedRuns.isEmpty {
                emptyEvidenceCard.block(top: 12)
            }

            DFlow(spacing: 6, lineSpacing: 6) {
                ForEach(["All", "Accept", "Repeat", "Rollback", "Abort"], id: \.self) { x in
                    DOption(label: x, on: app.filt == x, fill: false) { app.filt = x }
                }
            }
            .block(top: 12)

            VStack(spacing: 6) {
                if app.runsLoaded && !app.persistedRuns.isEmpty {
                    ForEach(app.persistedRuns) { run in persistedRow(run) }
                } else {
                    ForEach(rows, id: \.id) { r in row(r) }
                }
            }
            .block()
            Spacer(minLength: 0)
        }
        .fileImporter(isPresented: $importPresented, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            Task { await app.importRun(from: url) }
        }
    }

    private var emptyEvidenceCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            DT("BASELINE WORKSPACE", .mono, 10).foregroundStyle(AP.label)
            DT("Capture or import a baseline to replace the demo ledger with local evidence.", .sans, 13, lh: 1.35)
                .foregroundStyle(AP.text2)
            HStack(spacing: 8) {
                DT("READ-ONLY", .mono, 10, 600).foregroundStyle(AP.ink)
                    .padding(.vertical, 4).padding(.horizontal, 7)
                    .background(RoundedRectangle(cornerRadius: 4).fill(AP.green))
                DT("NO ECU WRITES", .mono, 10).foregroundStyle(AP.label)
            }
        }
        .apCard()
    }

    private func evidenceSummary(_ comparison: MobileRunComparison) -> some View {
        let title: String
        let color: Color
        switch comparison.decision {
        case .improvementConfirmed: title = "REPEAT CONFIRMED"; color = AP.green
        case .repeatRequired: title = "REPEAT REQUIRED"; color = AP.amber
        case .regression: title = "REGRESSION"; color = AP.red
        case .insufficientData: title = "INSUFFICIENT DATA"; color = AP.label
        }
        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                DT("EVIDENCE ASSESSMENT", .mono, 10).foregroundStyle(AP.label)
                Spacer()
                DT(title, .mono, 10, 600).foregroundStyle(color)
            }
            HStack(spacing: 16) {
                metric("IMPROVEMENT", comparison.improvementPercent.map { String(format: "%.1f%%", $0) } ?? "—")
                metric("REPEAT Δ", comparison.repeatDelta.map { String(format: "%.3f", $0) } ?? "—")
                metric("WRITE", "NEVER")
            }
        }
        .apCard()
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            DT(value, .barlow, 20, 700, lh: 0.95)
            DT(label, .mono, 8).foregroundStyle(AP.label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func persistedRow(_ run: MobileRunRecord) -> some View {
        let summary = MobileBaselineSummary(run: run)
        let kind = run.kind == .repeatRun ? "REPEAT" : run.kind.rawValue.uppercased()
        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2).fill(run.kind == .baseline ? AP.baseline : AP.candidate).frame(width: 3)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    DT(kind + " · " + run.title, .sans, 14, 500).lineLimit(1)
                    Spacer()
                    DT("QUALITY \(summary.qualityScore)%", .mono, 9, 600).foregroundStyle(summary.isUsable ? AP.green : AP.amber)
                }
                DT("\(summary.frameCount) frames · \(String(format: "%.1f", summary.durationSeconds))s · \(summary.coveragePercent.rounded())% coverage", .mono, 10).foregroundStyle(AP.text3)
                if let issue = summary.issues.first {
                    DT(issue.rawValue.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression).uppercased(), .mono, 9).foregroundStyle(AP.amber)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .apCard(vertical: 8, horizontal: 12)
    }

    private func row(_ r: Exp) -> some View {
        let c = DDecision.color(r.dec)
        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 3)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top, spacing: 8) {
                    DT(app.tr(r.id) + " · " + app.tr(r.date), .mono, 11).foregroundStyle(AP.label).lineLimit(1)
                    Spacer(minLength: 0)
                    DT(app.tr(r.dec.uppercased()), .mono, 10).foregroundStyle(c)
                }
                DT(app.tr(r.title), .sans, 14, 500)
                DT(app.tr(r.res), .mono, 11).foregroundStyle(AP.text3)
                if app.tuner {
                    DT(r.h, .mono, 10).foregroundStyle(AP.faint)
                } else {
                    Color.clear.frame(height: 0)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .apCard(vertical: 8, horizontal: 12)
        .contentShape(Rectangle())
        .onTapGesture { app.router.go(.S31) }
        // The design has no visible links here; the run views open from a long-press menu.
        .contextMenu {
            Button(app.tr("Session detail & export")) { app.router.go(.S31) }
            Button(app.tr("Run overlay")) { app.router.go(.S19) }
            Button(app.tr("Gain curve")) { app.router.go(.S20) }
            Button(app.tr("Gain bridge")) { app.router.go(.S28) }
            Button(app.tr("Progress")) { app.router.go(.S29) }
        }
    }
}
