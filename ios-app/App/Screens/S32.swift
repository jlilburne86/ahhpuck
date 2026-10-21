import SwiftUI

/// S32 · Garage & settings. Units, density and language apply to every screen.
/// Not drawn in the design but required by README · Navigation: the vehicle row opens S02, its
/// subtitle opens the ECU capabilities (S43); in tuner mode the density note opens Raw frames (S33);
/// a threshold row opens the Glossary (S42).
struct S32View: View {
    @Environment(AppModel.self) private var app
    @State private var doc: LegalDoc?

    var body: some View {
        let afr = app.units == .afr
        let thr: [(String, String, String)] = [("Coolant max", "105 °C", "DOCUMENTED"), ("Intake temp max", "55 °C", "INFERRED"), ("Oil min above 3k", "1.0 bar", "DOCUMENTED"),
                                               ("Battery min", "12.0 V", "OBSERVED"), ("Lean limit >70% load", afr ? "14.0 AFR" : "λ 0.95", "INFERRED"), ("RPM limit", "7,600", "DOCUMENTED")]
        let two = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]

        PhoneScreen(tab: .garage) {
            AHeader(title: "Garage", sub: app.tr("1 VEHICLE · LOCAL PROFILE"))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    M("AE86 · Blacktop 20V", .barlow, 22, 600)
                    M("FC-03 Ab-1EU · ITBs · 98 RON", .mono, 11, color: AP.label, translate: false)
                        .onTapGesture { app.router.go(.S43) }
                }
                Spacer()
                M("›", .sans, 18, color: AP.label, translate: false)
            }
            .apCard()
            .contentShape(Rectangle())
            .onTapGesture { app.router.go(.S02) }
            .block()

            VStack(alignment: .leading, spacing: 8) {
                M("UNITS (APPLIES TO EVERY PAGE)", .mono, 10, color: AP.label)
                LazyVGrid(columns: two, spacing: 6) {
                    MChip(label: "Lambda", on: !afr, size: 13, v: 7, h: 11, center: true) { app.units = .lambda }
                    MChip(label: "AFR", on: afr, size: 13, v: 7, h: 11, center: true) { app.units = .afr }
                }
                M("DENSITY", .mono, 10, color: AP.label)
                LazyVGrid(columns: two, spacing: 6) {
                    MChip(label: "Owner", on: !app.tuner, size: 13, v: 7, h: 11, center: true) { app.tuner = false }
                    MChip(label: "Tuner", on: app.tuner, size: 13, v: 7, h: 11, center: true) { app.tuner = true }
                }
                M(app.tuner ? "Raw values, σ and hashes shown across pages (see Ledger)." : "Plain-language summaries first.", .sans, 12, color: AP.label)
                    .onTapGesture { if app.tuner { app.router.go(.S33) } }
                M("LANGUAGE", .mono, 10, color: AP.label)
                LazyVGrid(columns: two, spacing: 6) {
                    MChip(label: "English", on: app.lang == .en, size: 13, v: 7, h: 11, center: true) { app.lang = .en }
                    MChip(label: "日本語", on: app.lang == .ja, size: 13, v: 7, h: 11, center: true) { app.lang = .ja }
                }
            }
            .apCard()
            .block()

            M("PROTECTION THRESHOLDS", .mono, 10, color: AP.label).block(top: 12)
            MList {
                ForEach(thr, id: \.0) { k, v, tag in
                    HStack(spacing: 8) {
                        M(k, .sans, 13).frame(maxWidth: .infinity, alignment: .leading)
                        M(v, .mono, 12)
                        M(tag, .mono, 9, color: AP.evidence(tag)).frame(width: 78, alignment: .trailing)
                    }
                    .mRow(7, 12)
                    .contentShape(Rectangle())
                    .onTapGesture { app.router.go(.S42) }
                }
            }
            .block(top: 6)

            M("Loosening a threshold needs a reason, and the change is logged.", .sans, 12, color: AP.label).block(top: 8)

            // About: the legal documents (the same as wheelhave.com), permissions, and the build.
            M("ABOUT", .mono, 10, color: AP.label).block(top: 14)
            MList {
                ForEach(LegalDoc.allCases) { d in aboutRow(d.title) { doc = d } }
                aboutRow("Permissions") { app.router.go(.S35) }
                HStack(spacing: 8) {
                    M("Version", .sans, 13).frame(maxWidth: .infinity, alignment: .leading)
                    M(Self.version, .mono, 12, color: AP.label, translate: false)
                }
                .mRow(9, 12)
            }
            .block(top: 6)
            Spacer(minLength: 0)
        }
        .sheet(item: $doc) { LegalDocView(doc: $0).environment(app) }
    }

    private static let version: String = {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))"
    }()

    private func aboutRow(_ label: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            M(label, .sans, 13).frame(maxWidth: .infinity, alignment: .leading)
            M("›", .sans, 16, color: AP.label, translate: false)
        }
        .mRow(9, 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .accessibilityAddTraits(.isButton)
    }
}
