import SwiftUI

/// S22 · Assessment — the gate's decision first, then six checks, the max next increment, ignition locked.
struct S22View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let b = app.base, d = b.dec
        PhoneScreen(tab: .review) {
            AHeader(title: "Review", sub: app.tr("DETERMINISTIC GATE · AI EXPLAINS ONLY"))

            HStack(spacing: 4) {
                ForEach(Array(b.decisions.enumerated()), id: \.offset) { i, x in
                    let on = i == app.dec
                    M(x.label, .sans, 11, 600, color: on ? AP.ink : AP.text3, lineHeight: 1.2)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9).padding(.horizontal, 5)
                        .background(RoundedRectangle(cornerRadius: 8).fill(on ? AP.text : .clear))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(on ? AP.text : AP.control, lineWidth: 1))
                        .contentShape(Rectangle())
                        .onTapGesture { app.dec = i }
                }
            }
            .block(top: 12)

            VStack(alignment: .leading, spacing: 6) {
                M(d.kicker, .mono, 11, 600).apTracking(0.06, size: 11)
                M(d.title, .barlow, 32, 700, lineHeight: 1)
                M(d.body, .sans, 13, lineHeight: 1.4)
            }
            .foregroundStyle(AP.ink)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(d.bg))
            .contentShape(Rectangle())
            .onTapGesture { app.router.go(.S26) }   // "why?" → the analyst's explanation
            .block()

            MList {
                ForEach(b.checks, id: \.label) { k in
                    HStack(spacing: 10) {
                        T(k.status.glyph, .sans, 11, 700).apFont(.sans, 11, 700).foregroundStyle(AP.ink)
                            .frame(width: 18, height: 18)
                            .background(RoundedRectangle(cornerRadius: 5).fill(k.status.color))
                        M(k.label, .sans, 13).frame(maxWidth: .infinity, alignment: .leading)
                        M(k.v, .mono, 12, color: AP.text2)
                    }
                    .mRow()
                }
            }
            .block()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    M("MAX NEXT INCREMENT", .mono, 10, color: AP.label)
                    M(d.inc, .barlow, 24, 600)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    M("IGNITION", .mono, 10, color: AP.label)
                    M("Locked", .barlow, 24, 600, color: AP.label)
                }
            }
            .apCard()
            .block()

            HStack(spacing: 8) {
                M(d.cta, .sans, 15, 600, color: AP.ink)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AP.text))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        switch app.dec {
                        case 0: app.dFlow = 0; app.dDone = false; app.router.go(.S25)
                        case 1: app.rType = "Repeat"; app.router.go(.S10)
                        case 2: app.dFlow = 1; app.dDone = false; app.router.go(.S25)
                        default: app.router.go(.S13)
                        }
                    }
                M("ZIP", .mono, 11, color: AP.text3)
                    .frame(width: 50, height: 50)
                    .outlined(AP.control, radius: 12)
                    .contentShape(Rectangle())
                    .onTapGesture { app.router.go(.S31) }
            }
            .block(top: 12)
            Spacer(minLength: 0)
        }
    }
}
