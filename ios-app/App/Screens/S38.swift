import SwiftUI

/// S38 · Data sources
struct S38View: View {
    @Environment(AppModel.self) private var app

    private struct Src {
        let kind, n, meta, st: String; let sc: Color; let gate: String; let gc: Color
        let f: [(String, String)]; let note: String
    }
    private let src: [Src] = [
        Src(kind: "ECU", n: "Freedom FC-03", meta: "USB-C · 31 Hz · 9 FIELDS", st: "✓ CONNECTED", sc: AP.green, gate: "USED BY SAFETY GATE", gc: AP.green,
            f: [("RPM", "OBSERVED"), ("TPS", "OBSERVED"), ("Coolant", "INFERRED"), ("Intake temp", "INFERRED"), ("O₂ mV", "INFERRED"), ("Ignition adv", "UNVERIFIED"), ("Battery", "OBSERVED"), ("Knock", "OBSERVED"), ("Speed", "OBSERVED")],
            note: "The main source. Ignition scaling is unverified, so it is shown but never used to decide."),
        Src(kind: "PHONE", n: "GPS", meta: "1 Hz · ±2.4 m", st: "✓ ON", sc: AP.green, gate: "NEVER USED TO DECIDE", gc: AP.label,
            f: [("Speed", "INFERRED"), ("Position", "OBSERVED")], note: "Used to cross-check ECU speed and to draw the route."),
        Src(kind: "PHONE", n: "Motion", meta: "100 Hz · MOUNT CALIBRATED", st: "✓ ON", sc: AP.green, gate: "NEVER USED TO DECIDE", gc: AP.label,
            f: [("Long g", "OBSERVED"), ("Lat g", "OBSERVED"), ("Yaw", "OBSERVED"), ("Power est.", "INFERRED")],
            note: "Used to check that runs were driven the same way, and for power estimates."),
        Src(kind: "EXT", n: "Oil pressure", meta: "ADD-ON · 10 Hz", st: "✓ CONNECTED", sc: AP.green, gate: "USED BY SAFETY GATE", gc: AP.green,
            f: [("Oil pressure", "OBSERVED")], note: "Fills a gap: the FC-03 doesn't report oil pressure."),
        Src(kind: "EXT", n: "Wideband lambda", meta: "ADD-ON · RECOMMENDED", st: "+ ADD", sc: AP.text, gate: "WOULD REPLACE ECU O₂", gc: AP.amber,
            f: [("Lambda", "OBSERVED")], note: "Strongly recommended. The ECU narrowband O₂ is only inferred, so assessments carry lower confidence without it."),
        Src(kind: "EXT", n: "Fuel pressure", meta: "ADD-ON", st: "+ ADD", sc: AP.text, gate: "WOULD BE USED BY GATE", gc: AP.label,
            f: [("Fuel pressure", "OBSERVED")], note: "Lets AhhPuck tell a fuel-supply problem apart from a map error."),
    ]
    private let checks: [(Status, String, String)] = [
        (.ok, "ECU speed vs GPS speed", "62.1 vs 61.4 km/h · 1.1% apart"),
        (.ok, "Pull consistency (phone g-force)", "Runs 03 and 04 match 94%"),
        (.caution, "Lambda source", "ECU narrowband O₂ · wideband recommended"),
    ]

    var body: some View {
        let sx = src[app.srcSel]
        PhoneScreen(tab: .garage, scrolls: false) {
            AHeader(title: "Data sources", sub: app.tr("ECU FIRST · PHONE ADDS · ADD-ONS FILL GAPS"))

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(src.enumerated()), id: \.offset) { i, x in
                        HStack(spacing: 10) {
                            M(x.kind, .mono, 9, 600, color: x.kind == "ECU" ? AP.ink : AP.text2)
                                .frame(width: 46).padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 4).fill(x.kind == "ECU" ? AP.text : x.kind == "PHONE" ? AP.disabled : .clear))
                                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(AP.control, lineWidth: 1))
                            VStack(alignment: .leading, spacing: 1) {
                                M(x.n, .sans, 13)
                                M(x.meta, .mono, 10, color: AP.label)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            M(x.st, .mono, 10, 600, color: x.sc).lineLimit(1).fixedSize()
                        }
                        .padding(.vertical, 7).padding(.horizontal, 12)
                        .background(i == app.srcSel ? AP.selectedRow : .clear)
                        .overlay(alignment: .bottom) { Rectangle().fill(AP.divider).frame(height: 1) }
                        .padding(.bottom, 1)
                        .contentShape(Rectangle())
                        .onTapGesture { app.srcSel = i }
                    }
                }
                .padding(1)
            }
            .frame(minHeight: 120, maxHeight: .infinity)
            .scrollIndicators(.hidden)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AP.border, lineWidth: 1))
            .block(top: 12)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    M(sx.n, .barlow, 20, 600)
                    Spacer()
                    M(sx.gate, .mono, 10, 600, color: sx.gc)
                }
                DFlow(spacing: 5, lineSpacing: 5) {
                    ForEach(sx.f, id: \.0) { n, e in
                        (T(app.tr(n) + " · ", .mono, 10).foregroundColor(AP.text2)
                         + T(app.tr(e), .mono, 10).foregroundColor(e == "OBSERVED" ? AP.text : e == "INFERRED" ? AP.text3 : AP.label))
                            .apFont(.mono, 10)
                            .lineLimit(1).fixedSize()
                            .padding(.vertical, 4).padding(.horizontal, 8)
                            .outlined(AP.control, radius: 4)
                    }
                }
                M(sx.note, .sans, 12, color: AP.text3, lineHeight: 1.4)
            }
            .apCard()
            .block()

            VStack(alignment: .leading, spacing: 8) {
                M("CROSS-CHECKS", .mono, 10, color: AP.label)
                ForEach(checks, id: \.1) { st, t, d in
                    HStack(spacing: 10) {
                        T(st.glyph, .sans, 11, 700).apFont(.sans, 11, 700)
                            .foregroundStyle(st == .stop ? Color.white : AP.ink)
                            .frame(width: 20, height: 20)
                            .background(RoundedRectangle(cornerRadius: 5).fill(st.color))
                        VStack(alignment: .leading, spacing: 0) {
                            M(t, .sans, 13)
                            M(d, .mono, 10, color: AP.label)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .apCard()
            .block()

            M("The safety gate uses only the ECU and add-on sensors. Phone data is never used to make a decision.", .sans, 12, color: AP.label, lineHeight: 1.4)
                .padding(.horizontal, Metrics.gutter).padding(.top, 8).padding(.bottom, 10)
        }
    }
}
