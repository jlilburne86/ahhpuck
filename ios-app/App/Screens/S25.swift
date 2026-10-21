import SwiftUI

/// S25 · Decision flows — Accept / Rollback / Abort, what happens next, confirm, recorded state.
struct S25View: View {
    @Environment(AppModel.self) private var app

    private struct Flow {
        let k: String, col: Color, fg: Color, kick, title, body, btn, done: String
        let steps: [(String, String)]
    }
    private static let flows: [Flow] = [
        Flow(k: "Accept", col: AP.green, fg: AP.ink, kick: "✓ ACCEPT", title: "Make the candidate the reference",
             body: "Lambda error fell 56% and the repeat landed within tolerance.", btn: "Accept candidate",
             done: "EXP-04 accepted · next proposal capped at ±1.5%",
             steps: [("Candidate becomes the accepted reference", "sha 81d0…4b07"), ("Baseline 03 archived, never deleted", "sha 3f9a…c21e"),
                     ("Next proposal capped", "Fuel ±1.5% per cell · ignition locked"), ("Ledger entry written and signed", "EXP-04 → ACCEPT")]),
        Flow(k: "Rollback", col: AP.rollback, fg: AP.ink, kick: "↺ ROLLBACK", title: "Return to the last accepted state",
             body: "The candidate made things worse. Undo it, then prove the car is back where it was.", btn: "Start rollback",
             done: "Rollback started · verification run required",
             steps: [("Restore EXP-03 by hand", "sha 3f9a…c21e · verified backup"), ("Record a verification run", "Must match EXP-03 within 1%"),
                     ("EXP-04 evidence kept", "Marked as a regression in the ledger"), ("Proposals paused", "Until the verification run passes")]),
        Flow(k: "Abort", col: AP.red, fg: .white, kick: "✕ ABORT", title: "Stop and lock tuning",
             body: "A critical event happened. Nothing continues until a person investigates.", btn: "Abort and lock",
             done: "Session sealed · investigation log opened",
             steps: [("Session sealed", "No further runs in this session"), ("Tuning locked app-wide", "Proposals disabled everywhere"),
                     ("Investigation required", "Opens the investigation log (S13)")]),
    ]

    var body: some View {
        let f = S25View.flows[app.dFlow]
        PhoneScreen(tab: .review, status: "OFFLINE", statusStyle: .dim) {
            ScreenHeader(title: "Decide", subtitle: "EXP-04 · ALL THREE SHOWN FOR REVIEW")

            HStack(spacing: 6) {
                ForEach(Array(S25View.flows.enumerated()), id: \.offset) { i, x in
                    DOption(label: x.k, on: app.dFlow == i) { app.dFlow = i; app.dDone = false }
                }
            }
            .block(top: 12)

            VStack(alignment: .leading, spacing: 6) {
                DT(app.tr(f.kick), .mono, 11, 600).apTracking(0.06, size: 11)
                DT(app.tr(f.title), .barlow, 30, 700, lh: 1)
                DT(app.tr(f.body), .sans, 13, lh: 1.4)
            }
            .foregroundStyle(f.fg)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(f.col))
            .block()

            DT(app.tr("WHAT HAPPENS NEXT"), .mono, 10).foregroundStyle(AP.label)
                .padding(.top, 6).frame(height: 20, alignment: .top)
                .block(top: 14)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(f.steps.enumerated()), id: \.offset) { i, s in
                    HStack(alignment: .top, spacing: 12) {
                        DT("0\(i + 1)", .mono, 11).foregroundStyle(AP.faint).padding(.top, 2)
                        VStack(alignment: .leading, spacing: 2) {
                            DT(app.tr(s.0), .sans, 13)
                            DT(app.tr(s.1), .mono, 10).foregroundStyle(AP.label)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 10).padding(.horizontal, 12)
                    .overlay(alignment: .bottom) { DDivider() }
                }
            }
            .padding(1)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .outlined(AP.border, radius: 12)
            .block(top: 6)

            if app.dDone {
                DT(app.tr("Recorded · ") + app.tr(f.done), .sans, 13, lh: 1.4)
                    .fixedSize(horizontal: false, vertical: true)
                    .apCard(vertical: 11, horizontal: 14, radius: 12, stroke: AP.control)
                    .block()
            }

            Spacer(minLength: 0)
            PrimaryButton(label: app.dDone ? (Features.prototypeControls ? "Undo (demo)" : "Recorded") : f.btn,
                          fill: app.dDone ? .clear : f.col,
                          fg: app.dDone ? AP.text2 : f.fg,
                          height: 54) {
                if app.dDone && !Features.prototypeControls { return }
                app.dDone.toggle()
                // Abort seals the session and opens the investigation log (S13).
                if app.dDone && f.k == "Abort" { app.router.go(.S13) }
            }
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AP.control, lineWidth: 1))
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 14)
            Spacer(minLength: 0)
        }
    }
}
