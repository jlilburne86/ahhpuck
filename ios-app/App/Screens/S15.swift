import SwiftUI

/// S15 · Proposal — 8×6 fuel grid (cells with ≥10 samples selectable, capped ±1.5 %),
/// stat tiles and readiness bars. Port of `propCells` / `ready` in `moreVals`.
struct S15View: View {
    @Environment(AppModel.self) private var app

    struct PCell { let key: String; let ok: Bool; let on: Bool; let label: String }

    /// Port of the prototype's proposal grid (rows load 100→50, columns rpm 2.5k→7.6k).
    static func cells(_ psel: [String: Bool]) -> [PCell] {
        var out: [PCell] = []
        for r in 0..<6 {
            for c0 in 0..<8 {
                let c = Double(c0 + 4), rr = Double(r)
                let d = abs(c / 11 - (1 - rr / 9) * 0.85 - 0.05)
                let h = (sin(c * 12.9 + rr * 78.2) * 43758.5).truncatingRemainder(dividingBy: 1)
                let hits = d < 0.28 ? Int((60 * (1 - d / 0.28) * (0.45 + 0.55 * abs(h))).rounded()) : 0
                let e = sin(c * 1.3 + rr * 0.7) * 3.2 + (c > 6 && r < 4 ? 3 : 0)
                let key = "\(r)-\(c0)", ok = hits >= 10, on = ok && (psel[key] ?? false)
                let sug = max(-1.5, min(1.5, -e * 0.4))
                let label = on ? (sug > 0 ? "+" : "") + String(format: "%.1f", sug) : ok ? String(hits) : "·"
                out.append(PCell(key: key, ok: ok, on: on, label: label))
            }
        }
        return out
    }

    var body: some View {
        let cells = S15View.cells(app.psel)
        let count = cells.filter(\.on).count
        PhoneScreen(tab: .review, status: "OFFLINE", statusStyle: .dim) {
            ScreenHeader(title: "Proposal", subtitle: "DRIVABILITY · FUEL ONLY · TAP COVERED CELLS")

            // grid with load axis (left) and rpm axis (below)
            HStack(alignment: .top, spacing: 4) {
                VStack(spacing: 0) {
                    ForEach([100, 90, 80, 70, 60, 50], id: \.self) { a in
                        T(String(a), .mono, 9).apFont(.mono, 9)
                            .frame(width: 22, alignment: .trailing)
                            .frame(maxHeight: .infinity)
                    }
                }
                .foregroundStyle(AP.faint)
                .frame(width: 22, height: 246)
                VStack(spacing: 4) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 8), spacing: 3) {
                        ForEach(cells, id: \.key) { c in
                            T(c.label, .mono, 10).apFont(.mono, 10)
                                .foregroundStyle(c.on ? AP.ink : c.ok ? AP.label : Color(hex: 0x33373b))
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(RoundedRectangle(cornerRadius: 4).fill(c.on ? AP.text : c.ok ? AP.raised : Color(hex: 0x121315)))
                                .contentShape(Rectangle())
                                .onTapGesture { if c.ok { app.psel[c.key] = !(app.psel[c.key] ?? false) } }
                        }
                    }
                    HStack(spacing: 0) {
                        ForEach(["2.5", "3", "3.5", "4", "5", "6", "7", "7.6"], id: \.self) { a in
                            T(a, .mono, 9).apFont(.mono, 9, lineHeight: 11 / 9).frame(maxWidth: .infinity)
                        }
                    }
                    .foregroundStyle(AP.faint)
                }
            }
            .padding(.leading, 8).padding(.trailing, 14).padding(.top, 12)

            HStack(spacing: 6) {
                stat("CELLS", app.tr(String(count) + " sel"))
                stat("CAP / CELL", "±1.5%")
                stat("IGNITION", app.tr("Never"), color: AP.label)
            }
            .block(top: 10)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    T(app.tr("READINESS (NOT \"PERFECTION\")"), .mono, 10).apFont(.mono, 10, lineHeight: 15 / 10).foregroundStyle(AP.label)
                    Spacer(minLength: 0)
                    T("71 / 96", .mono, 12).apFont(.mono, 12, lineHeight: 15 / 12)
                }
                ForEach(S15View.ready, id: \.0) { k, n in
                    HStack(spacing: 8) {
                        T(app.tr(k), .sans, 12).apFont(.sans, 12, lineHeight: 15 / 12).foregroundStyle(AP.text3)
                            .lineLimit(1).frame(width: 118, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(AP.raised)
                                RoundedRectangle(cornerRadius: 3).fill(n >= 80 ? AP.green : n >= 60 ? AP.amber : AP.red)
                                    .frame(width: geo.size.width * CGFloat(n) / 100)
                            }
                        }
                        .frame(height: 5)
                        T(String(n), .mono, 11).apFont(.mono, 11, lineHeight: 14 / 11).frame(width: 30, alignment: .trailing)
                    }
                }
            }
            .apCard()
            .block(top: 10)

            Spacer(minLength: 0)
            PrimaryButton(label: "Review concerns") { app.router.go(.S16) }
                .padding(.horizontal, 18).padding(.bottom, 20)
            Spacer(minLength: 0)
        }
    }

    static let ready: [(String, Int)] = [("Objective score", 82), ("Safety pass", 100), ("Map coverage", 32), ("Repeatability", 74), ("Sensor confidence", 68)]

    private func stat(_ k: String, _ v: String, color: Color = AP.text) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            T(app.tr(k), .mono, 10).apFont(.mono, 10, lineHeight: 13 / 10).foregroundStyle(AP.label).lineLimit(1)
            T(v, .barlow, 22, 600).apFont(.barlow, 22, 600, lineHeight: 26 / 22).foregroundStyle(color).lineLimit(1)
        }
        .padding(.vertical, 9).padding(.horizontal, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .outlined(AP.border, radius: 10)
    }
}
