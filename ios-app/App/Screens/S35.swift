import SwiftUI

/// S35 · Permissions and legal information.
struct S35View: View {
    @Environment(AppModel.self) private var app
    @State private var doc: LegalDoc?

    private let P: [(k: String, t: String, lvl: String, d: String, used: String)] = [
        ("notif", "Notifications", "NOT ENABLED", "This build does not request notification access. Critical events remain in the app.", "READ-ONLY BUILD"),
        ("la", "Live Activities", "NOT ENABLED", "This build does not publish lock-screen activities. Recording stays inside the app.", "READ-ONLY BUILD"),
        ("loc", "Location", "NOT ENABLED", "This build does not request location access.", "READ-ONLY BUILD"),
        ("mot", "Motion", "NOT ENABLED", "This build does not request motion access. ECU replay and raw capture do not need it.", "READ-ONLY BUILD"),
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
                ASans(text: "This build stores replay and capture data locally. It does not request system permissions, create an account, or upload data.",
                      size: 13, color: AP.text2, lineHeight: 1.5)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 16) {
                    Button(app.tr("Privacy Policy")) { doc = .privacy }
                    Button(app.tr("Terms of Service")) { doc = .terms }
                    Button(app.tr("Disclaimer")) { doc = .disclaimer }
                }
                .apFont(.sans, 13, 600)
                .foregroundStyle(AP.cyan)
                .padding(.top, 4)
            }
            .apCard()
            .block()

            Spacer(minLength: 0)

            AButton(label: "Continue", border: AP.control) {
                if app.router.onboarding { app.router.nextInFirstRun(after: .S35) } else { app.router.back() }
            }
            .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 24)
        }
        .sheet(item: $doc) { LegalDocView(doc: $0).environment(app) }
    }

    private func row(_ p: (k: String, t: String, lvl: String, d: String, used: String)) -> some View {
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    ASans(text: p.t, size: 14, weight: 600)
                    AMono(text: p.lvl, size: 9, color: p.lvl == "RECOMMENDED" ? AP.text2 : AP.label)
                }
                ASans(text: p.d, size: 12, color: AP.text3, lineHeight: 1.4)
                    .fixedSize(horizontal: false, vertical: true)
                AMono(text: p.used, size: 9, color: AP.faint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            T(app.tr("Not requested"), .sans, 13, 600)
                .apFont(.sans, 13, 600)
                .foregroundStyle(AP.label)
                .lineLimit(1)
                .fixedSize()
                .padding(.vertical, 9).padding(.horizontal, 10)
                .background(RoundedRectangle(cornerRadius: 8).fill(AP.disabled))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(AP.control, lineWidth: 1))
        }
        .padding(12)
        .aRowDivider()
    }
}
