import SwiftUI

/// S34 · How AhhPuck works (four steps, first-run flow)
struct S34View: View {
    @Environment(AppModel.self) private var app

    private struct Step { let t, b: String; let you, app: [String]; let note: String }
    private let H: [Step] = [
        Step(t: "Your ECU is the source", b: "AhhPuck reads the FC-03 over a USB-C serial cable, and each value is labelled so you always know where a number came from.", you: ["Plug the cable into the ECU", "Ignition on, engine off"], app: ["Identifies the ECU", "Checks every frame", "Locks writes"], note: "ECU = ENGINE DATA · ADD-ONS = MISSING SENSORS"),
        Step(t: "Record a baseline", b: "Run one repeatable test on a dyno or a closed course: same gear, same RPM band. This becomes the reference and can never be edited.", you: ["Pass the preflight checks", "Run the test with an observer"], app: ["Records every frame", "Fills in map coverage", "Watches safety limits"], note: "ALERTS RUN ON FIXED RULES, EVEN OFFLINE"),
        Step(t: "Read the evidence", b: "AhhPuck shows what each run recorded and how sure it is. It is information, not tuning advice: any change to your map is yours to make, outside the app.", you: ["Review the runs", "Decide with your tuner"], app: ["Tags every value with its evidence", "Never touches ignition", "Never writes to the ECU"], note: "AHHPUCK NEVER WRITES TO THE ECU"),
        Step(t: "Compare and decide", b: "Run a candidate and a repeat under the same conditions. The safety gate checks them: accept, repeat, roll back or abort.", you: ["Run the candidate and a repeat", "Read the explanation"], app: ["Compares against noise", "Logs everything to the ledger"], note: "GAINS COUNT ONLY WHEN A REPEAT CONFIRMS THEM"),
    ]

    var body: some View {
        let hs = H[app.hiw]
        PhoneScreen(tab: nil) {
            AHeader(title: "How it works", sub: [app.tr("STEP "), String(app.hiw + 1), app.tr(" OF 4")].joined())

            AStepPills(labels: ["Connect", "Baseline", "Change", "Decide"], cur: app.hiw) { app.hiw = $0 }
                .block(top: 12)

            VStack(alignment: .leading, spacing: 10) {
                T("0" + String(app.hiw + 1), .barlow, 84, 700)
                    .apFont(.barlow, 84, 700, lineHeight: 0.8)
                    .foregroundStyle(AP.control)
                T(app.tr(hs.t), .barlow, 34, 700)
                    .apFont(.barlow, 34, 700, lineHeight: 1)
                    .fixedSize(horizontal: false, vertical: true)
                ASans(text: hs.b, size: 14, color: AP.text3, lineHeight: 1.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 20)

            HStack(alignment: .top, spacing: 12) {
                column("YOU DO", hs.you, AP.text)
                column("AHHPUCK DOES", hs.app, AP.text2)
            }
            .apCard()
            .block(top: 16)

            AMono(text: hs.note, size: 10, color: AP.text2, lineHeight: 1.5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 11).padding(.horizontal, 13)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(AP.control, style: ADash.style))
                .block(top: 12)

            Spacer(minLength: 0)

            ABackNext(next: app.hiw < 3 ? "Next" : "Get started", back: {
                if app.hiw > 0 { app.hiw -= 1 } else { app.router.back() }
            }, next: {
                if app.hiw < 3 { app.hiw += 1 }
                else if app.router.onboarding { app.router.nextInFirstRun(after: .S34) }
                else { app.router.back() }
            })
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
    }

    private func column(_ head: String, _ items: [String], _ c: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            AMono(text: head, size: 10)
            ForEach(items, id: \.self) {
                ASans(text: $0, size: 13, color: c, lineHeight: 1.35).fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
