import SwiftUI

/// S04 · Connection & identity (also the sheet opened from the status strip)
struct S04View: View {
    @Environment(AppModel.self) private var app

    /// `((t * 31 + i * 17) ^ (i * 7)) & 255` for 48 bytes, upper-case hex.
    static func rawBytes(_ t: Int) -> String {
        var out: [String] = []
        for i in 0..<48 {
            let b: Int = ((t * 31 + i * 17) ^ (i * 7)) & 255
            out.append(String(format: "%02X", b))
        }
        return out.joined(separator: " ")
    }

    var body: some View {
        let s = app.conn, t = app.t
        let cst = app.hardwareTransportAvailable
            ? ["Cable detected", "Port open · 9600 7E1", "Bytes arriving", "Frames valid", "ECU identified"]
            : ["Replay mode", "Protocol profile loaded · 9600 7E1", "Demo bytes only", "Decoder locked", "ECU not connected"]
        let bytes = s >= 3 ? Self.rawBytes(t) : "— waiting for bytes —"
        let stats: [(String, String)] = [
            ("FRAMES", s >= 4 ? app.base.frames : "0"),
            ("DROPPED", s >= 4 ? "0.4%" : "—"),
            ("STALE", "0"),
            ("LAST RX", s >= 3 ? "\(30 + (t % 9) * 2)ms" : "—"),
        ]

        PhoneScreen(tab: .live) {
            AHeader(title: "Connection", sub: app.tr(app.hardwareTransportAvailable && s >= 5 ? "CONNECTED · IDENTITY INFERRED" : "SIMULATED · NO ECU CONNECTED"))

            VStack(spacing: 2) {
                ForEach(Array(cst.enumerated()), id: \.offset) { i, l in
                    MDotRow(label: l,
                            dot: i < s ? AP.green : i == s ? AP.text : AP.disabled,
                            fg: i <= s ? AP.text : AP.faint,
                    state: app.hardwareTransportAvailable ? (i < s ? "OK" : i == s ? "…" : "") : (i < s ? "REPLAY" : "LOCKED"))
                }
            }
            .block()

            HStack(spacing: 6) {
                ForEach(stats, id: \.0) { k, v in
                    VStack(alignment: .leading, spacing: 2) {
                        M(k, .mono, 10, color: AP.label)
                        M(v, .mono, 13)
                    }
                    .padding(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .outlined(AP.border, radius: 10)
                }
            }
            .block(top: 6)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    M("ECU IDENTITY", .mono, 10, color: AP.label)
                    Spacer()
                    M(app.hardwareTransportAvailable && s >= 5 ? "INFERRED" : "DEMO ONLY", .mono, 10, color: AP.label)
                }
                M(app.hardwareTransportAvailable ? "FC-03 · Ab-1EU · Z-J01030" : "FC-03 profile · ECU not connected", .sans, 14, translate: false)
                M(app.hardwareTransportAvailable ? "Group injection · direct ignition (from unit label)" : "Profile values are not live identity evidence.", .sans, 12, color: AP.label)
            }
            .apCard()
            .block()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    M("WRITE LOCK", .mono, 10, color: AP.label)
                    M("Locked in this release", .sans, 14)
                }
                Spacer()
                M("LOCKED", .mono, 11, color: AP.text2)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(AP.raised))
            }
            .apCard()
            .block()

            VStack(alignment: .leading, spacing: 8) {
                M(app.hardwareTransportAvailable ? "RAW BYTES · 9600 7E1" : "SIMULATED BYTES · NOT ECU DATA", .mono, 10, color: AP.label)
                M(bytes, .mono, 11, color: AP.text3, lineHeight: 1.6)
            }
            .apCard()
            .block()

            Spacer(minLength: 16)
            if app.router.onboarding {
                // Not in the design: the first-run flow needs a way on to S02 once the ECU is identified.
                MButton(label: "Continue", bottom: 8) { app.router.nextInFirstRun(after: .S04) }
            }
            #if DEBUG
            MButton(label: "Simulate unplug", bg: .clear, fg: AP.text2) { app.conn = 0 }
            #endif
        }
    }
}
