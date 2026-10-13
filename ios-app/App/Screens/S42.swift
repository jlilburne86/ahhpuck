import SwiftUI

/// S42 · Glossary & help — search in English or Japanese, accordion of 12 terms, "Used on Sxx" references.
struct S42View: View {
    @Environment(AppModel.self) private var app

    static let terms: [(String, String, String)] = [
        ("Lambda (λ)", "Air–fuel mixture compared with ideal. 1.00 is ideal, below is rich, above is lean.", "S06 · S09 · S19"),
        ("AFR", "The same thing as lambda, written as air-to-fuel ratio. λ 1.00 = 14.7 AFR for petrol.", "S32"),
        ("Lean / rich", "Lean means too little fuel; it runs hot and can damage the engine under load. Rich means too much fuel.", "S09 · S21"),
        ("Coverage", "How many samples a map cell has. Cells with fewer than 10 samples are never changed.", "S09 · S15"),
        ("Run-to-run noise", "How much results vary between two identical runs. A gain only counts when it's bigger than the noise.", "S16 · S20 · S23"),
        ("Evidence tag", "How sure we are about a value: documented, observed, inferred or unverified.", "S01 · S33"),
        ("Data source", "Where a number comes from: the ECU, the phone or an add-on sensor. Only the ECU and add-ons are used to decide.", "S38"),
        ("Safety gate", "Fixed rules that make every decision. The analyst explains; the gate decides.", "S22 · S25"),
        ("Baseline", "The reference run. It's never edited, so every change is compared with the same thing.", "S10 · S19"),
        ("Candidate / repeat", "The run with one change, and the same run done again to prove the result.", "S10 · S23"),
        ("Knock", "Uncontrolled combustion that can destroy an engine. Any knock event stops the run.", "S12 · S22"),
        ("Injector duty", "How much of the time the injectors are open. Near 90% there's no fuel left to add.", "S16"),
    ]

    var body: some View {
        @Bindable var app = app
        let q = app.gq.trimmingCharacters(in: .whitespaces).lowercased()
        // Matches the English text or its Japanese translation, whatever the current language.
        let rows = Self.terms.enumerated().filter { _, g in
            q.isEmpty || (g.0 + " " + g.1).lowercased().contains(q)
                || (L10n.t(g.0, .ja) + L10n.t(g.1, .ja)).lowercased().contains(q)
        }

        PhoneScreen(tab: .garage, scrolls: false) {
            AHeader(title: "Glossary", sub: app.tr("TAP A TERM · SEARCH IN EN OR 日本語"))

            TextField("", text: $app.gq, prompt: Text(app.tr("Search terms")).foregroundColor(Color(hex: 0x757575)))
                .font(APFont.font(.sans, 15))
                .foregroundStyle(AP.text)
                .tint(AP.text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 15)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(AP.card))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AP.control, lineWidth: 1))
                .block(top: 12)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(rows, id: \.offset) { i, g in
                        let open = app.gOpen == i
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                M(g.0, .sans, 14, 600)
                                Spacer()
                                M(open ? "−" : "+", .mono, 14, color: AP.label, translate: false)
                            }
                            if open {
                                M(g.1, .sans, 13, color: AP.text2, lineHeight: 1.5)
                                M("USED ON " + g.2, .mono, 10, color: AP.label)
                            }
                        }
                        .mRow(11, 12)
                        .contentShape(Rectangle())
                        .onTapGesture { app.gOpen = open ? -1 : i }
                    }
                }
                .padding(1)
            }
            .frame(maxHeight: .infinity)
            .scrollIndicators(.hidden)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AP.border, lineWidth: 1))
            .block()

            M("\(rows.count) of \(Self.terms.count) terms", .sans, 12, color: AP.label)
                .padding(.horizontal, Metrics.gutter).padding(.top, 8).padding(.bottom, 10)
        }
    }
}
