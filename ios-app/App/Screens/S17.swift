import SwiftUI

/// S17 · Concerns & rollback plan — accordion of concerns (each must be opened before Continue),
/// stop criteria and the rollback target (port of `concerns` / `concBtn`).
struct S17View: View {
    @Environment(AppModel.self) private var app

    struct Concern { let id, sev, title, body: String }
    static let concerns: [Concern] = [
        Concern(id: "c1", sev: "HIGH", title: "Lean drift above 6,000 rpm", body: "Baseline showed +4.1% lean in two high-load cells. Stop if λ exceeds 0.95 above 70% load."),
        Concern(id: "c2", sev: "MED", title: "Intake temp rising across pulls", body: "IAT reached 48 °C on pull 3. Space pulls 3 min apart; stop above 55 °C."),
        Concern(id: "c3", sev: "MED", title: "Sparse coverage at 7,000 rpm", body: "Only 6 samples. Those cells are excluded from the proposal."),
        Concern(id: "c4", sev: "LOW", title: "Fuel pressure not measured", body: "A pump drop-off can't be told apart from a map error. Confidence lowered."),
    ]

    var body: some View {
        let seen = S17View.concerns.filter { app.opened[$0.id] ?? false }.count
        let done = seen >= 4
        PhoneScreen(tab: .review, status: "OFFLINE", statusStyle: .dim) {
            ScreenHeader(title: "Concerns", subtitle: app.tr(String(seen)) + " " + app.tr("OF 4 REVIEWED"))

            VStack(spacing: 0) {
                ForEach(S17View.concerns, id: \.id) { c in
                    let open = app.openC == c.id
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 10) {
                            T(app.tr(c.sev), .mono, 9).apFont(.mono, 9).foregroundStyle(AP.ink)
                                .padding(.vertical, 2).padding(.horizontal, 5)
                                .background(RoundedRectangle(cornerRadius: 3).fill(c.sev == "HIGH" ? AP.red : c.sev == "MED" ? AP.amber : AP.label))
                                .fixedSize()
                            T(app.tr(c.title), .sans, 13).apFont(.sans, 13)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Circle().fill((app.opened[c.id] ?? false) ? AP.green : AP.disabled).frame(width: 7, height: 7)
                            T(open ? "−" : "+", .mono, 14).apFont(.mono, 14).foregroundStyle(AP.label)
                        }
                        .padding(.vertical, 11).padding(.horizontal, 12)
                        if open {
                            T(app.tr(c.body), .sans, 13).apFont(.sans, 13, lineHeight: 1.45).foregroundStyle(AP.text3)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 12).padding(.bottom, 12)
                        }
                    }
                    .padding(.bottom, 1)
                    .overlay(alignment: .bottom) { Rectangle().fill(AP.divider).frame(height: 1) }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        app.openC = app.openC == c.id ? nil : c.id
                        app.opened[c.id] = true
                    }
                }
            }
            .padding(1)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .outlined(AP.border, radius: 12)
            .block(top: 12)

            VStack(alignment: .leading, spacing: 8) {
                T(app.tr("STOP CRITERIA"), .mono, 10).apFont(.mono, 10).foregroundStyle(AP.label)
                T([app.tr("λ > 0.95 above 70% load"), app.tr("IAT > 55 °C · coolant > 105 °C"), app.tr("Any knock event · oil < 1.0 bar above 3k")].joined(separator: "\n"), .mono, 12)
                    .apFont(.mono, 12, lineHeight: 1.6).foregroundStyle(AP.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .apCard()
            .block(top: 10)

            VStack(alignment: .leading, spacing: 8) {
                T(app.tr("ROLLBACK TO"), .mono, 10).apFont(.mono, 10).foregroundStyle(AP.label)
                T(app.tr("EXP-03 · accepted 06 Oct"), .sans, 14).apFont(.sans, 14)
                T(app.tr("sha 3f9a…c21e · verified backup"), .mono, 11).apFont(.mono, 11).foregroundStyle(AP.label)
            }
            .apCard()
            .block(top: 10)

            Spacer(minLength: 10)
            PrimaryButton(label: done ? "Continue to approval" : "Open each concern to continue (\(seen)/4)", enabled: done,
                          action: { app.router.go(.S18) }, onGated: { app.router.go(.S41) })
                .padding(.horizontal, 18).padding(.bottom, 20)
            Spacer(minLength: 0)
        }
    }
}
