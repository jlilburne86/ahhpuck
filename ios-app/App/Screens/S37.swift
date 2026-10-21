import SwiftUI

/// S37 · Connection errors
struct S37View: View {
    @Environment(AppModel.self) private var app

    private struct Case {
        let l, k, t: String; let bg, fg: Color; let st: [(String, String, Color)]
        let m: String; let steps: [String]; let imp: String; let ic: Color; let cta: String
    }
    private var cases: [Case] {[
        Case(l: "Cable", k: "✕ NOT RECOGNISED", t: "Cable not recognised", bg: AP.red, fg: .white,
             st: [("CHIPSET", "unknown", AP.red), ("BYTES", "0", AP.label), ("PORT", "closed", AP.label)],
             m: "The adapter isn't a supported serial chipset, or it's a charge-only cable.",
             steps: ["Use an adapter from the tested list", "Check that the cable carries data, not only charge", "Unplug, wait 5 s, plug back in"],
             imp: "Nothing is recorded until the port opens.", ic: AP.label, cta: "See tested adapters"),
        Case(l: "Wrong ECU", k: "! IDENTITY MISMATCH", t: "This isn't the ECU in your profile", bg: AP.amber, fg: AP.ink,
             st: [("EXPECTED", "Ab-1EU", AP.text2), ("FOUND", "Ab-2JP", AP.amber), ("FRAMES", "valid", AP.green)],
             m: "Data is arriving, but the ECU identity is different from the one in your vehicle profile.",
             steps: ["Check you picked the right vehicle in Garage", "Or create a new profile for this ECU", "Live view works; proposals stay locked"],
             imp: "Proposals are locked until the identity matches a profile.", ic: AP.amber, cta: "Open Garage"),
        Case(l: "Framing", k: "! FRAMES INVALID", t: "Bytes arriving, frames invalid", bg: AP.amber, fg: AP.ink,
             st: [("CHECKSUM FAIL", "92%", AP.red), ("BAUD", "9600?", AP.amber), ("BYTES/S", "960", AP.text2)],
             m: "Data is arriving, but almost every frame fails its checksum. Usually a baud-rate or wiring problem.",
             steps: ["Confirm the ECU serial output is 9600 7E1", "Reseat the connector at the ECU", "Try again; AhhPuck re-syncs automatically"],
             imp: "Bad frames are dropped and never used.", ic: AP.label, cta: "Retry connection"),
        Case(l: "Phone hot", k: "! THERMAL", t: "Phone is too hot", bg: AP.amber, fg: AP.ink,
             st: [("iOS STATE", "serious", AP.amber), ("FRAME RATE", "18 Hz", AP.amber), ("TARGET", "31 Hz", AP.text2)],
             m: "iOS is slowing the phone down to cool it. Fewer frames are captured.",
             steps: ["Move the phone out of direct sun", "Remove the case, lower the brightness", "Recording continues with lower confidence"],
             imp: "Runs below 25 Hz are flagged in Review.", ic: AP.amber, cta: "Continue anyway"),
        Case(l: "Battery", k: "! LOW BATTERY", t: "Phone battery at 9%", bg: AP.amber, fg: AP.ink,
             st: [("BATTERY", "9%", AP.amber), ("STOPS AT", "5%", AP.text2), ("RUN", "02:41", AP.text2)],
             m: "Recording stops safely at 5% so the session is saved.",
             steps: ["Keep the phone on a charger", "Turn off Low Power Mode during runs", "Saved runs are never lost"],
             imp: "At 5% the run is saved and closed automatically.", ic: AP.label, cta: "OK"),
    ]}

    var body: some View {
        let all = cases, er = all[app.err]
        PhoneScreen(tab: .live) {
            AHeader(title: "Connection problem", sub: app.tr("TAP A CASE TO PREVIEW"))
            DFlow(spacing: 6, lineSpacing: 6) {
                ForEach(Array(all.enumerated()), id: \.offset) { i, c in
                    MChip(label: c.l, on: app.err == i) { app.err = i }
                }
            }
            .block(top: 12)

            VStack(alignment: .leading, spacing: 4) {
                M(er.k, .mono, 11, 600)
                M(er.t, .barlow, 28, 700, lineHeight: 1)
            }
            .foregroundStyle(er.fg)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(er.bg))
            .block()

            HStack(spacing: 6) {
                ForEach(er.st, id: \.0) { k, v, c in
                    VStack(alignment: .leading, spacing: 2) {
                        M(k, .mono, 10, color: AP.label)
                        M(v, .mono, 14, color: c).lineLimit(1).fixedSize()
                    }
                    .padding(.vertical, 9).padding(.horizontal, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .outlined(AP.border, radius: 10)
                }
            }
            .block()

            VStack(alignment: .leading, spacing: 8) {
                M("WHAT IT MEANS", .mono, 10, color: AP.label)
                M(er.m, .sans, 13, color: AP.text2, lineHeight: 1.5)
            }
            .apCard()
            .block()

            M("TRY THIS", .mono, 10, color: AP.label).block(top: 12)
            MList {
                ForEach(Array(er.steps.enumerated()), id: \.offset) { i, s in
                    HStack(alignment: .top, spacing: 12) {
                        M("0\(i + 1)", .mono, 11, color: AP.faint)
                        M(s, .sans, 13, lineHeight: 1.35)
                    }
                    .mRow()
                }
            }
            .block(top: 6)

            M(er.imp, .sans, 12, color: er.ic, lineHeight: 1.4).block(top: 8)

            Spacer(minLength: 16)
            MButton(label: er.cta, border: AP.control, bottom: 12) {
                switch app.err {
                case 1: app.router.select(.garage)
                case 2: app.router.go(.S04)
                default: app.router.back()
                }
            }
        }
    }
}
