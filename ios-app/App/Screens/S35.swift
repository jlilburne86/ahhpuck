import SwiftUI

/// S35 · Permissions
struct S35View: View {
    @Environment(AppModel.self) private var app

    private let P: [(k: String, t: String, lvl: String, d: String, used: String)] = [
        ("notif", "Notifications", "RECOMMENDED", "Critical alerts reach you even when the screen is locked.", "USED BY S12 · S14"),
        ("la", "Live Activities", "RECOMMENDED", "Shows the run on the lock screen while you drive.", "USED BY S11 · S14"),
        ("loc", "Location", "OPTIONAL", "GPS speed and a route trace. Never used to decide.", "USED BY S20 · S39"),
        ("mot", "Motion", "OPTIONAL", "G-force and run consistency checks. Never used to decide.", "USED BY S03 · S20"),
    ]

    var body: some View {
        PhoneScreen(tab: nil) {
            AHeader(title: "Permissions", sub: app.tr("ALL OPTIONAL FOR READING THE ECU"))

            AList {
                ForEach(P, id: \.k) { p in row(p) }
            }
            .block(top: 12)

            VStack(alignment: .leading, spacing: 8) {
                AMono(text: "PRIVACY", size: 10)
                ASans(text: "Everything stays on this phone. No account, no cloud. You can change these in iOS Settings at any time.",
                      size: 13, color: AP.text2, lineHeight: 1.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .apCard()
            .block()

            Spacer(minLength: 0)

            AButton(label: "Continue", border: AP.control) {
                if app.router.onboarding { app.router.nextInFirstRun(after: .S35) } else { app.router.back() }
            }
            .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 24)
        }
    }

    private func row(_ p: (k: String, t: String, lvl: String, d: String, used: String)) -> some View {
        let on = app.perm[p.k] ?? false
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    ASans(text: p.t, size: 14, weight: 600)
                    AMono(text: p.lvl, size: 9, color: p.lvl == "RECOMMENDED" ? AP.text2 : AP.label)
                }
                ASans(text: p.d, size: 12, color: AP.text3, lineHeight: 1.4)
                    .fixedSize(horizontal: false, vertical: true)
                AMono(text: p.used, size: 9, color: AP.faint)
                    // "USED BY … S14" previews the notifications and Live Activity screen (not drawn as a link).
                    .onTapGesture { if p.used.contains("S14") && !app.router.onboarding { app.router.go(.S14) } }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            T(app.tr(on ? "✓ Allowed" : "Allow"), .sans, 13, 600)
                .apFont(.sans, 13, 600)
                .foregroundStyle(on ? AP.green : AP.ink)
                .lineLimit(1)
                .fixedSize()
                .padding(.vertical, 9).padding(.horizontal, 13)
                .background(RoundedRectangle(cornerRadius: 8).fill(on ? Color.clear : AP.text))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(on ? AP.control : AP.text, lineWidth: 1))
                .contentShape(Rectangle())
                .onTapGesture { app.perm[p.k] = !on }
        }
        .padding(12)
        .aRowDivider()
    }
}
