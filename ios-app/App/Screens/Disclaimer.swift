import SwiftUI

/// The beta disclaimer. Shown before anything else on first launch (and again whenever its
/// version changes), must be accepted with "I understand", and can be read again from
/// Garage › Disclaimer and Permissions › Disclaimer. The same text is in TERMS-OF-USE.md and
/// the AhhPuck section of wheelhave.com/terms.
enum Disclaimer {
    /// Bump when the text changes so everyone reads and accepts the new version.
    static let version = "beta-2026-10-21"
    private static let key = "disclaimerAccepted"

    static var accepted: Bool { UserDefaults.standard.string(forKey: key) == version }
    static func accept() { UserDefaults.standard.set(version, forKey: key) }

    static let title = "Before you use AhhPuck"
    static let points: [String] = [
        "AhhPuck is beta software. It is unfinished, may contain errors, and can change or stop working at any time.",
        "This build is read-only. It never writes to your ECU, changes a calibration or ignition timing, or controls your engine.",
        "Until the FC-03 connection is verified, the engine numbers you see are demo data, not readings from your engine. Imported captures show what is in the file.",
        "Everything AhhPuck shows is information only. It is not tuning advice, and it does not tell you that an engine, a map or a change is safe.",
        "Use it only with the vehicle stationary, on a bench or a closed course. Never use it on a public road or while driving.",
        "You are responsible for your vehicle, engine and ECU, for every change you make, and for complying with road, roadworthiness and emissions laws where you live.",
        "AhhPuck is provided “as is”, without any warranty. To the extent the law allows, Wheel Have is not liable for damage to engines, vehicles, ECUs or other property, or for any injury, loss or cost, arising from using AhhPuck or acting on what it shows.",
        "Nothing in this disclaimer excludes, restricts or modifies any right or remedy you have under the Australian Consumer Law or other law that cannot lawfully be excluded.",
    ]
}

/// The numbered disclaimer text, shared by the first-run gate and the read-again sheet.
struct DisclaimerText: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(Disclaimer.points.enumerated()), id: \.offset) { i, p in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    AMono(text: String(format: "%02d", i + 1), size: 10, color: AP.label)
                        .frame(width: 18, alignment: .leading)
                    ASans(text: p, size: 13, color: AP.text2, lineHeight: 1.45)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// "BETA" tag, amber like the demo-data pill.
struct BetaTag: View {
    @Environment(AppModel.self) private var app
    var body: some View {
        Text(app.tr("BETA"))
            .apFont(.mono, 10, 600)
            .foregroundStyle(AP.amber)
            .padding(.horizontal, 7).padding(.vertical, 4)
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(AP.amber.opacity(0.7), lineWidth: 1))
            .accessibilityLabel(app.tr("Beta"))
    }
}

/// First launch: read and accept the disclaimer before anything else.
struct DisclaimerGate: View {
    @Environment(AppModel.self) private var app
    var onAccept: () -> Void
    @State private var agreed = false

    var body: some View {
        PhoneScreen(tab: nil, demoStrip: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    AMono(text: "AHHPUCK", size: 11, color: AP.label, tracking: 0.1)
                    BetaTag()
                    Spacer(minLength: 0)
                    ALangPill()
                }
                .frame(height: 36)
                T(app.tr(Disclaimer.title), .barlow, 36, 700)
                    .apFont(.barlow, 36, 700, lineHeight: 0.95)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            DisclaimerText()
                .apCard()
                .block(top: 14)

            HStack(alignment: .top, spacing: 12) {
                ATick(on: agreed, size: 24, radius: 6, fontSize: 16)
                ASans(text: "I have read this and accept it. I use AhhPuck at my own risk.",
                      size: 13, color: AP.text2, lineHeight: 1.45)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture { agreed.toggle() }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(agreed ? [.isButton, .isSelected] : .isButton)
            .block(top: 14)

            Spacer(minLength: 0)

            AButton(label: agreed ? "I understand" : "Tick the box to continue",
                    bg: agreed ? AP.text : AP.disabled, fg: agreed ? AP.ink : AP.faint) {
                guard agreed else { return }
                Disclaimer.accept()
                onAccept()
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
    }
}

/// Read the disclaimer again (Garage and Permissions).
struct DisclaimerSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    BetaTag()
                    Spacer(minLength: 0)
                    Button(app.tr("Done")) { dismiss() }
                        .apFont(.sans, 15, 600)
                        .foregroundStyle(AP.cyan)
                }
                T(app.tr(Disclaimer.title), .barlow, 30, 700).apFont(.barlow, 30, 700)
                DisclaimerText()
                AMono(text: app.tr("You accepted this disclaimer on first launch."), size: 10, color: AP.faint)
            }
            .padding(20)
        }
        .background(AP.screen.ignoresSafeArea())
        .foregroundStyle(AP.text)
    }
}

/// The strip under every in-app screen: this build's engine numbers are demo data.
struct DemoStrip: View {
    @Environment(AppModel.self) private var app
    var body: some View {
        HStack(spacing: 8) {
            BetaTag()
            ASans(text: "Demo data until the FC-03 connection is verified. Information only.", size: 11, color: AP.text3)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Metrics.gutter)
        .frame(height: 30)
        .background(AP.screen)
        .overlay(alignment: .top) { Rectangle().fill(AP.track).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }
}
