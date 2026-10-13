import SwiftUI

/// S43 · ECU capabilities — limits come from the ECU, not the app.
/// Each field, setting and map has one capability state (README · ECU capability profiles).
struct S43View: View {
    @Environment(AppModel.self) private var app

    private enum Cap: String { case ver, unv, ecu, app, unk, pol }
    private struct StyleDef { let st: String; let bg: Color; let fg: Color; let bd: Color; var hatched = false }
    private static let styles: [Cap: StyleDef] = [
        .ver: StyleDef(st: "✓ READ · VERIFIED", bg: AP.green, fg: AP.ink, bd: AP.green),
        .unv: StyleDef(st: "◐ READ · NOT VERIFIED", bg: .clear, fg: AP.amber, bd: AP.amber),
        .ecu: StyleDef(st: "⌀ NOT IN THIS ECU", bg: .clear, fg: AP.text, bd: AP.control, hatched: true),
        .app: StyleDef(st: "… NOT DECODED YET", bg: .clear, fg: AP.text2, bd: AP.hatchA),
        .unk: StyleDef(st: "? UNKNOWN", bg: .clear, fg: AP.label, bd: AP.control),
        .pol: StyleDef(st: "■ SET BY POLICY", bg: AP.disabled, fg: AP.text2, bd: AP.disabled),
    ]
    private struct Profile { let label, name, tag, meta: String; let o: [String: Cap]; var all: Cap? = nil }
    private static let profiles: [Profile] = [
        Profile(label: "FC-03 · AE111", name: "Freedom FC-03 · AE111 coupler", tag: "TRIAL UNIT", meta: "4A-GE 20V · BATCH FIRE · DIRECT IGNITION · LABEL Z-J01030 · SERIAL 9600 7E1", o: [:]),
        Profile(label: "FC-03 · AE86 20V", name: "Freedom FC-03 · AE86 coupler", tag: "EXAMPLE", meta: "4A-GE 20V SWAP · AE86 LOOM · LABEL CODE DIFFERS · SERIAL 9600 7E1", o: ["coupler": .unv]),
        Profile(label: "Freedom · 16V AFM", name: "Freedom · 4A-GE 16V", tag: "EXAMPLE", meta: "AIR-FLOW METER LOAD · OLDER FIRMWARE · SERIAL TO CONFIRM", o: ["map": .ecu, "afm": .unv, "vvt": .ecu, "serial": .unk]),
        Profile(label: "Unknown unit", name: "Unidentified Freedom unit", tag: "IDENTIFY", meta: "READ THE SILVER LABEL, THEN CAPTURE ONE SESSION TO BUILD A PROFILE", o: [:], all: .unk),
    ]
    private typealias Row = (k: String, n: String, def: Cap, d: String)
    private static let rows: [[Row]] = [
        [("rpm", "RPM", .unv, "Seen in captures; scaling waits for a verified export mapping."), ("tps", "Throttle (TPS)", .unv, "0–255 raw; scaling inferred."), ("map", "Manifold pressure (MAP)", .unv, "Present on D-jetro (MAP) setups."), ("afm", "Air-flow meter", .ecu, "This unit runs MAP or throttle load, not AFM."), ("clt", "Coolant temp", .unv, "Offset −40 °C not confirmed."), ("iat", "Intake temp", .unv, "Offset not confirmed."), ("o2", "O₂ (narrowband)", .unv, "Millivolts only; no wideband input."), ("ign", "Ignition advance", .app, "Bytes seen; scaling not decoded yet."), ("inj", "Injector pulse width", .app, "In the reply; not decoded yet."), ("knock", "Knock", .unk, "No knock channel found so far. Confirm with the manual."), ("vvt", "VVT state", .unv, "On/off only on this engine."), ("oil", "Oil pressure", .ecu, "Not an ECU input. Use an add-on sensor.")],
        [("prog", "Program channel (dial 1–4)", .unv, "Which of the stored maps is active."), ("loadt", "Load control type", .unv, "D-jetro (MAP) or throttle (Alpha-N)."), ("learn", "Self-learning modes", .unv, "O₂, MAP/AFM and water-temp learning, each on or off."), ("rev", "Rev limit", .unv, "Read from settings."), ("coupler", "Coupler / vehicle family", .ver, "From the silver label code."), ("serial", "Serial format", .ver, "9600 bps, 7E1, from the bench.")],
        [("fuel", "Fuel base map", .ver, "Parsed from the map file (FCP parser)."), ("ignm", "Ignition map", .ver, "Parsed from file; live values not decoded."), ("live", "Map read live from the ECU", .app, "Next gate: verified live capture."), ("axes", "Map axes and units", .unv, "RPM × load; units inferred."), ("write", "Write a map to the ECU", .pol, "Locked by AhhPuck in this release, whatever the ECU supports.")],
        [("l1", "Ignition proposals", .ecu, "Unavailable: this ECU's ignition scaling is unverified and no knock signal is confirmed."), ("l2", "Self-learning during tests", .ecu, "Must be OFF: ECU learning would change the map under test."), ("l3", "Assessment confidence", .ecu, "Lower: narrowband O₂ only. A wideband add-on raises it."), ("l4", "Program channel", .ecu, "Baseline and candidate must use the same dial position."), ("l5", "Max RPM 7,800", .pol, "From the engine passport and policy 0.2."), ("l6", "Fuel step ≤ 2.0% per cell", .pol, "Safety policy 0.2, provisional.")],
    ]

    var body: some View {
        let p = Self.profiles[app.capP]
        let rows = Self.rows[app.capT].map { r -> (n: String, d: String, s: StyleDef) in
            let key: Cap = (p.all != nil && r.def != .pol) ? p.all! : (p.o[r.k] ?? r.def)
            return (r.n, (p.all != nil && r.def != .pol) ? "Identify the unit first." : r.d, Self.styles[key]!)
        }
        let all: [Cap] = (0...2).flatMap { ti in Self.rows[ti].map { r in p.all != nil ? .unk : (p.o[r.k] ?? r.def) } }
        let cnt = { (c: Cap) in all.filter { $0 == c }.count }
        let sum: [(Int, String, Color)] = [(cnt(.ver) + cnt(.unv), "READABLE", AP.green), (cnt(.ecu), "NOT IN ECU", AP.text), (cnt(.app), "TO DECODE", AP.text2), (cnt(.unk), "UNKNOWN", AP.label)]
        let grid2 = [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)]
        let grid4 = Array(repeating: GridItem(.flexible(), spacing: 5), count: 4)

        PhoneScreen(tab: .garage, scrolls: false) {
            AHeader(title: "ECU capabilities", sub: app.tr("WHAT THIS UNIT EXPOSES · NOT WHAT THE APP CAN DO"))

            LazyVGrid(columns: grid2, spacing: 5) {
                ForEach(Array(Self.profiles.enumerated()), id: \.offset) { i, x in
                    MChip(label: x.label, on: app.capP == i, v: 6, h: 8, center: true) { app.capP = i }
                }
            }
            .block()

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    M(p.name, .sans, 14, 600)
                    Spacer(minLength: 0)
                    M(p.tag, .mono, 9, color: AP.label).lineLimit(1).fixedSize()
                }
                M(p.meta, .mono, 10, color: AP.text3, lineHeight: 1.5)
            }
            .apCard(vertical: 10, horizontal: 12)
            .block(top: 8)

            LazyVGrid(columns: grid4, spacing: 5) {
                ForEach(Array(["Live", "Settings", "Maps", "Limits"].enumerated()), id: \.offset) { i, x in
                    MChip(label: x, on: app.capT == i, v: 6, h: 8, center: true) { app.capT = i }
                }
            }
            .block(top: 8)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, k in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                M(k.n, .sans, 13).frame(maxWidth: .infinity, alignment: .leading)
                                M(k.s.st, .mono, 9, 600, color: k.s.fg).lineLimit(1).fixedSize()
                                    .padding(.vertical, 4).padding(.horizontal, 7)
                                    .background {
                                        if k.s.hatched { Hatch().clipShape(RoundedRectangle(cornerRadius: 4)) }
                                        else { RoundedRectangle(cornerRadius: 4).fill(k.s.bg) }
                                    }
                                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(k.s.bd, lineWidth: 1))
                            }
                            M(k.d, .mono, 10, color: AP.label, lineHeight: 1.4)
                        }
                        .mRow(8, 12)
                    }
                }
                .padding(1)
            }
            .frame(maxHeight: .infinity)
            .scrollIndicators(.hidden)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AP.border, lineWidth: 1))
            .block(top: 8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
                ForEach(sum, id: \.1) { n, l, c in
                    VStack(spacing: 1) {
                        M(String(n), .barlow, 20, 700, color: c, lineHeight: 1, translate: false)
                        M(l, .mono, 8, color: c, lineHeight: 1.2).multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 7).padding(.horizontal, 5)
                    .frame(maxWidth: .infinity)
                    .outlined(AP.border, radius: 8)
                }
            }
            .block(top: 8)

            M("Example profile data. Community-maintained, and every row needs a verified capture before it counts.", .sans, 11, color: AP.label, lineHeight: 1.4)
                .padding(.horizontal, Metrics.gutter).padding(.top, 6).padding(.bottom, 8)
        }
    }
}
