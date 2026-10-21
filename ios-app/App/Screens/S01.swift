import SwiftUI

/// S01 · Welcome & safety boundary
struct S01View: View {
    @Environment(AppModel.self) private var app

    private let does = ["Reads live telemetry", "Compares runs", "Explains evidence", "Exports sessions"]
    private let refuses = ["Write to the ECU", "Advance ignition", "Override a critical stop", "Call an engine \"safe\""]
    private let evTags = [("DOCUMENTED", "From a manual or pinout"), ("OBSERVED", "Seen in a serial capture"),
                          ("INFERRED", "Plausible, not yet confirmed"), ("UNVERIFIED", "Never used for decisions")]

    var body: some View {
        PhoneScreen(tab: nil) {
            // padding:24px 24px 0; gap 12
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    AMono(text: "AHHPUCK · FREEDOM FC-03", size: 11, color: AP.label, tracking: 0.1)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    ALangPill()
                }
                .frame(height: 36)
                (T(app.tr("Read the engine."), .barlow, 46, 700) + Text(verbatim: "\n") + T(app.tr("Change nothing yet."), .barlow, 46, 700))
                    .apFont(.barlow, 46, 700, lineHeight: 0.95)
                    .fixedSize(horizontal: false, vertical: true)
                ASans(text: "AhhPuck records what your ECU is doing, compares controlled runs, and explains the evidence.",
                      size: 14, color: AP.text3, lineHeight: 1.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)

            // DOES / REFUSES card
            HStack(alignment: .top, spacing: 12) {
                column("DOES", does)
                column("REFUSES", refuses)
            }
            .apCard()
            .block()

            // Evidence tags card
            VStack(alignment: .leading, spacing: 8) {
                AMono(text: "EVIDENCE TAGS ON EVERY VALUE", size: 10)
                ForEach(evTags, id: \.0) { k, d in
                    HStack(spacing: 10) {
                        AMono(text: k, size: 10, color: AP.evidence(k))
                            .lineLimit(1)
                            .frame(width: 92, alignment: .leading)
                        ASans(text: d, size: 12, color: AP.text3)
                    }
                }
            }
            .apCard()
            .block()

            // Acknowledgement
            HStack(alignment: .top, spacing: 12) {
                ATick(on: app.ack, size: 24, radius: 6, fontSize: 16)
                ASans(text: "I understand a person supervises every test, and AhhPuck cannot write to the ECU.",
                      size: 13, color: AP.text2, lineHeight: 1.45)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture { app.ack.toggle() }
            .block(top: 14)

            Spacer(minLength: 0)

            AButton(label: app.ack ? "Set up vehicle →" : "Acknowledge to continue",
                    bg: app.ack ? AP.text : AP.disabled, fg: app.ack ? AP.ink : AP.faint) {
                if app.ack {
                    if app.router.onboarding { app.router.nextInFirstRun(after: .S01) } else { app.router.go(.S02) }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
    }

    private func column(_ head: String, _ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            AMono(text: head, size: 10, lineHeight: 1.45)
            ForEach(items, id: \.self) { ASans(text: $0, size: 12, lineHeight: 1.45) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
