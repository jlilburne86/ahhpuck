import SwiftUI

/// S33 · Raw frames (tuner). 12-column hex grid; tap a column for its field, evidence tag and note.
/// Unknown bytes are amber, kept raw, never used for assessment. Frame layout is illustrative.
struct S33View: View {
    @Environment(AppModel.self) private var app

    private let fields: [(String, String, String)] = [
        ("Header", "DOCUMENTED", "Always 0xA5. Frame start."), ("Length", "OBSERVED", "Payload length in bytes."), ("RPM high", "OBSERVED", "RPM ÷ 256."),
        ("RPM low", "OBSERVED", "RPM mod 256."), ("TPS", "OBSERVED", "Throttle 0–255 → 0–100%."), ("Coolant", "INFERRED", "Offset −40 °C, not confirmed."),
        ("Intake temp", "INFERRED", "Offset −40 °C, not confirmed."), ("O₂ mV", "INFERRED", "Narrowband voltage ×5 mV."), ("Ignition adv", "UNVERIFIED", "Scaling unknown. Not used."),
        ("Flags", "UNKNOWN", "Bitfield, still being decoded."), ("Unknown", "UNKNOWN", "Changes with load. Kept raw."), ("Checksum", "INFERRED", "XOR of bytes 1–10."),
    ]
    private let unkCols: Set<Int> = [8, 9, 10]

    var body: some View {
        let t = app.t, sel = app.rawSel, fs = fields[sel]
        let cols = [GridItem(.fixed(44), spacing: 1)] + Array(repeating: GridItem(.flexible(), spacing: 1), count: 12)

        PhoneScreen(tab: .live) {
            AHeader(title: "Raw frames", sub: app.tr("TUNER MODE · TAP A BYTE COLUMN"))

            LazyVGrid(columns: cols, spacing: 1) {
                M("SEQ", .mono, 10, color: AP.faint).frame(maxWidth: .infinity, alignment: .leading)
                ForEach(0..<12, id: \.self) { i in
                    M(String(format: "%02d", i), .mono, 10, color: i == sel ? AP.ink : unkCols.contains(i) ? AP.amber : AP.label, translate: false)
                        .frame(maxWidth: .infinity).padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 3).fill(i == sel ? AP.text : .clear))
                        .contentShape(Rectangle())
                        .onTapGesture { app.rawSel = i }
                }
            }
            .padding(.horizontal, 12).padding(.top, 12)

            VStack(spacing: 1) {
                ForEach(0..<14, id: \.self) { r in
                    let vals = Self.frame(t - r)
                    LazyVGrid(columns: cols, spacing: 1) {
                        M(String(18420 + (t - r) * 3), .mono, 9, color: AP.faint, translate: false)
                            .padding(.vertical, 4).frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(0..<12, id: \.self) { i in
                            M(String(format: "%02X", vals[i] & 255), .mono, 11,
                              color: unkCols.contains(i) ? AP.amber : r == 0 ? AP.text : AP.text3, translate: false)
                                .frame(maxWidth: .infinity).padding(.vertical, 4)
                                .background(i == sel ? AP.disabled : .clear)
                        }
                    }
                }
            }
            .padding(.horizontal, 12).padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    M("BYTE " + String(format: "%02d", sel), .mono, 10, color: AP.label, translate: false)
                    Spacer()
                    M(fs.1, .mono, 10, color: AP.evidence(fs.1))
                }
                M(fs.0, .barlow, 24, 600)
                M(fs.2, .sans, 12, color: AP.text3)
            }
            .apCard()
            .block()

            M("Unknown bytes shown in amber are kept in the raw capture and never used for assessment.", .sans, 12, color: AP.label).block(top: 8)
            Spacer(minLength: 0)
        }
    }

    /// The prototype's demo frame for tick `tt`: header, length, RPM, TPS, temps, O₂, ignition,
    /// two unknown bytes and an XOR checksum over bytes 1–10.
    static func frame(_ tt: Int) -> [Int] {
        let rp = Int((3820 + sin(Double(tt) / 9) * 1100).rounded())
        let tps = Int(((54 + sin(Double(tt) / 9 + 0.6) * 26) * 2.55).rounded())
        let m7 = ((tt * 7) % 60 + 60) % 60, m9 = ((tt % 9) + 9) % 9
        var v = [0xA5, 0x0C, rp >> 8, rp & 255, tps, 126, 78, 90 + m7, 40 + m9, (tt * 13) & 255, (tt * 29 + 7) & 255, 0]
        v[11] = v[1...10].reduce(0, ^)
        return v
    }
}
