import SwiftUI

/// S26 · Analyst explanation — read-only; explains the gate's decision, never changes it.
struct S26View: View {
    @Environment(AppModel.self) private var app

    private static let qs: [(q: String, a: String, src: [String])] = [
        ("Why repeat, not accept?", "The candidate cut lambda error from 4.8% to 2.1%. But 18% of the repeat run was in 2nd gear, so the two runs can't be compared like for like.", ["Repeatability", "Run setup · gear", "Overlay S19"]),
        ("What caused the lean cells?", "The lean error is all at 6,000–7,000 rpm above 70% load, where injector duty hit 86%. The likely cause is the fuel supply limit or a rise in intake temperature. Fuel pressure isn't measured, so this stays inferred.", ["Map S09", "IDC 86%", "Concern c4"]),
        ("What evidence is missing?", "Fuel pressure, a clean repeat run, and 82 cells the engine never reached. The analyst can't fill any of these in.", ["Preflight", "Coverage 38/120"]),
        ("Is the engine safe?", "I can't say that. The safety gate found no critical events in these runs. That describes this data, not the engine.", ["Safety gate", "Knock 0"]),
    ]

    /// Where each source chip leads (README: every claim links to the check or chart it came from).
    private static let links: [String: ScreenID] = {
        var l: [String: ScreenID] = [
            "Repeatability": .S22, "Run setup · gear": .S10, "Overlay S19": .S19, "Map S09": .S09, "IDC 86%": .S16,
            "Concern c4": .S17, "Preflight": .S05, "Coverage 38/120": .S09, "Safety gate": .S22, "Knock 0": .S22,
        ]
        // The proposal flow (S15–S18) is hidden in Release until live data drives it.
        if !Features.proposals { l["IDC 86%"] = nil; l["Concern c4"] = nil }
        return l
    }()

    var body: some View {
        let cur = S26View.qs[app.q]
        PhoneScreen(tab: .review, status: "OFFLINE", statusStyle: .dim) {
            ScreenHeader(title: "Analyst", subtitle: "ON-DEVICE · EXPLAINS, NEVER DECIDES")

            if let result = app.aiResult {
                localAssessment(result)
                    .block(top: 12)
            } else if app.runsLoaded {
                VStack(alignment: .leading, spacing: 8) {
                    DT("LOCAL EVIDENCE EXPLANATION", .mono, 10).foregroundStyle(AP.label)
                    DT("Generate a deterministic explanation from the persisted runs. No cloud account or API key is required.", .sans, 13, lh: 1.35)
                        .foregroundStyle(AP.text2)
                    PrimaryButton(label: "Explain evidence", height: 42) { app.refreshAIResult() }
                }
                .apCard()
                .block(top: 12)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    DT(app.tr("GATE DECISION"), .mono, 10).foregroundStyle(AP.label)
                    DT(app.tr("Repeat experiment"), .barlow, 22, 600)
                }
                Spacer(minLength: 0)
                DT(app.tr("LOCKED"), .mono, 10)
                    .padding(.vertical, 4).padding(.horizontal, 7)
                    .background(RoundedRectangle(cornerRadius: 5).fill(AP.disabled))
            }
            .apCard()
            .block()

            VStack(spacing: 6) {
                ForEach(Array(S26View.qs.enumerated()), id: \.offset) { i, x in
                    let s = DSel(app.q == i)
                    DT(app.tr(x.q), .sans, 13)
                        .foregroundStyle(s.fg)
                        .padding(.vertical, 11).padding(.horizontal, 13)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(s.bg))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(s.border, lineWidth: 1))
                        .contentShape(Rectangle())
                        .onTapGesture { app.q = i }
                }
            }
            .block(top: 12)

            VStack(alignment: .leading, spacing: 8) {
                DT(app.tr(cur.a), .sans, 14, lh: 1.55)
                    .fixedSize(horizontal: false, vertical: true)
                DFlow(spacing: 6, lineSpacing: 6) {
                    ForEach(cur.src, id: \.self) { x in
                        DT("↗ " + app.tr(x), .mono, 10)
                            .foregroundStyle(AP.text2)
                            .padding(.vertical, 4).padding(.horizontal, 8)
                            .frame(height: 21)
                            .outlined(AP.control, radius: 4)
                            .contentShape(Rectangle())
                            .onTapGesture { if let id = S26View.links[x] { app.router.go(id) } }
                    }
                }
            }
            .apCard()
            .block()

            DT(app.tr("Each claim links to the check or chart it came from."), .sans, 12)
                .foregroundStyle(AP.label)
                .block()

            Spacer(minLength: 0)
        }
    }

    private func localAssessment(_ result: MobileAIResult) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                DT("LOCAL ASSESSMENT", .mono, 10).foregroundStyle(AP.label)
                Spacer()
                DT(result.mode.replacingOccurrences(of: "_", with: " ").uppercased(), .mono, 9, 600)
                    .foregroundStyle(AP.green)
            }
            DT(result.summary, .barlow, 22, 700, lh: 1.05)
            DT("CONFIDENCE \(Int((result.confidence * 100).rounded()))% · \(result.sourceRunIDs.count) SOURCE RUNS", .mono, 9)
                .foregroundStyle(AP.text3)
            ForEach(result.findings.prefix(3)) { finding in
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        DT(finding.severity.rawValue.uppercased(), .mono, 9, 700)
                            .foregroundStyle(finding.severity == .critical ? AP.red : finding.severity == .warning ? AP.amber : AP.green)
                        DT(finding.title, .sans, 13, 600)
                    }
                    DT(finding.explanation, .sans, 12, lh: 1.3).foregroundStyle(AP.text2)
                    DT("NEXT · \(finding.nextCheck)", .mono, 9).foregroundStyle(AP.label)
                }
                .padding(.top, 3)
            }
            DT("NEXT ACTION · \(result.nextAction)", .sans, 12, 600, lh: 1.3).foregroundStyle(AP.ink)
            HStack {
                DT("WRITE AUTHORIZATION", .mono, 9).foregroundStyle(AP.label)
                Spacer()
                DT(result.writeAuthorization.uppercased(), .mono, 10, 700).foregroundStyle(AP.green)
            }
        }
        .apCard()
    }
}
