import SwiftUI

// Helpers shared by the group A screens (onboarding + connect: S01–S05, S34–S38, S43).
// Every helper is built to the design markup it replaces; sizes are CSS content-box (+ border).

/// The prototype's `sel(on)` colours: selected = inverted white.
struct ASel {
    let bg: Color, fg: Color, border: Color
    init(_ on: Bool) {
        bg = on ? AP.text : .clear
        fg = on ? AP.ink : AP.text2
        border = on ? AP.text : AP.control
    }
}

/// EN / 日本語 pill: `padding:3px; gap:4px; border:1px #2f3336; r8`, options `padding:5px 10px; r6; 12/600`.
struct ALangPill: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        HStack(spacing: 4) {
            opt(.en, "English")
            opt(.ja, "日本語")
        }
        .padding(4)
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(AP.control, lineWidth: 1))
    }

    private func opt(_ l: L10n.Language, _ label: String) -> some View {
        let s = ASel(app.lang == l)
        return Button { app.chooseLanguage(l) } label: {
            T(app.tr(label), .sans, 12, 600)
                .apFont(.sans, 12, 600)
                .foregroundStyle(s.fg)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(s.bg))
                .contentShape(Rectangle())
        }
        .buttonStyle(APPressableStyle())
    }
}

/// A full-width 52 pt button with arbitrary fill / text / border (the many inline CTA variants).
struct AButton: View {
    @Environment(AppModel.self) private var app
    var label: String
    var bg: Color = AP.text
    var fg: Color = AP.ink
    var border: Color? = nil
    var size: CGFloat = 15
    var weight: Int = 600
    var height: CGFloat = 52
    var radius: CGFloat = 14
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            T(app.tr(label), .sans, size, weight)
                .apFont(.sans, size, weight)
                .foregroundStyle(fg)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: height + (border == nil ? 0 : 2))
                .background(RoundedRectangle(cornerRadius: radius).fill(bg))
                .overlay {
                    if let border { RoundedRectangle(cornerRadius: radius).strokeBorder(border, lineWidth: 1) }
                }
                .contentShape(RoundedRectangle(cornerRadius: radius))
        }
        .buttonStyle(APPressableStyle())
    }
}

/// Tick box `width:N;height:N;border:1.5px solid c;r` with a bold ✓ (Chrome draws the 1.5 px border at 1⅓ px at 3×).
struct ATick: View {
    var on: Bool
    var size: CGFloat = 22
    var radius: CGFloat = 6
    var border: Color = Color(hex: 0x4a4f54)
    var fontSize: CGFloat = 16

    var body: some View {
        let lw: CGFloat = 4.0 / 3.0
        T(on ? "✓" : "", .sans, fontSize, 700)
            .apFont(.sans, fontSize, 700)
            .foregroundStyle(AP.ink)
            .frame(width: size + 2 * lw, height: size + 2 * lw)
            .background(RoundedRectangle(cornerRadius: radius).fill(on ? AP.text : .clear))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(border, lineWidth: lw))
    }
}

/// Mono label run with the given size/colour (most of the design's small caps labels).
struct AMono: View {
    @Environment(AppModel.self) private var app
    var text: String
    var size: CGFloat = 10
    var weight: Int = 400
    var color: Color = AP.label
    var tracking: CGFloat = 0
    var lineHeight: CGFloat? = nil

    var body: some View {
        T(app.tr(text), .mono, size, weight)
            .apFont(.mono, size, weight, lineHeight: lineHeight)
            .apTracking(tracking, size: size)
            .foregroundStyle(color)
    }
}

/// Sans text run.
struct ASans: View {
    @Environment(AppModel.self) private var app
    var text: String
    var size: CGFloat = 13
    var weight: Int = 400
    var color: Color = AP.text
    var lineHeight: CGFloat? = nil

    var body: some View {
        T(app.tr(text), .sans, size, weight)
            .apFont(.sans, size, weight, lineHeight: lineHeight)
            .foregroundStyle(color)
    }
}

/// Screen header `padding:10px 18px 0; gap:2px` — Barlow 24/700 title + mono 11 #8b8f93 sub (already translated).
struct AHeader<Trailing: View>: View {
    @Environment(AppModel.self) private var app
    var title: String
    var sub: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if app.router.onboarding ? !app.router.onboardingPath.isEmpty : (app.router.paths[app.router.tab]?.isEmpty == false) {
                BackRow()
            }
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    T(app.tr(title), .barlow, 24, 700).apFont(.barlow, 24, 700)
                    if let sub { T(sub, .mono, 11).apFont(.mono, 11).foregroundStyle(AP.label) }
                }
                Spacer(minLength: 0)
                trailing()
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 10)
        }
    }
}

extension AHeader where Trailing == EmptyView {
    init(title: String, sub: String? = nil) { self.init(title: title, sub: sub) { EmptyView() } }
}

/// Chrome's 1 px dashed border: 3 px dashes, 3 px gaps.
enum ADash {
    static let style = StrokeStyle(lineWidth: 1, dash: [3, 3])
}

/// Step pills (`pillsOf`): 4-column grid, gap 4, `padding:7px 0; r6; 11/600`.
/// Current = white, done = #2a2d30 / #cfd2d4, ahead = transparent / #6f7377.
struct AStepPills: View {
    @Environment(AppModel.self) private var app
    var labels: [String]
    var cur: Int
    var go: (Int) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(labels.enumerated()), id: \.offset) { i, l in
                Button { go(i) } label: {
                    T(app.tr(l), .sans, 11, 600)
                        .apFont(.sans, 11, 600)
                        .lineLimit(1)
                        .foregroundStyle(i == cur ? AP.ink : i < cur ? AP.text2 : AP.faint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 6).fill(i == cur ? AP.text : i < cur ? AP.disabled : .clear))
                        .contentShape(Rectangle())
                }
                .buttonStyle(APPressableStyle())
            }
        }
    }
}

/// Back (flex 1, outlined, 54 tall incl. border) + primary (flex 2, 52) row, gap 8.
struct ABackNext: View {
    var backLabel = "Back"
    var next: String
    var nextBg: Color = AP.text
    var nextFg: Color = AP.ink
    var back: () -> Void
    var next_: () -> Void

    init(backLabel: String = "Back", next: String, nextBg: Color = AP.text, nextFg: Color = AP.ink,
         back: @escaping () -> Void, next nextAction: @escaping () -> Void) {
        self.backLabel = backLabel; self.next = next; self.nextBg = nextBg; self.nextFg = nextFg
        self.back = back; self.next_ = nextAction
    }

    var body: some View {
        GeometryReader { geo in
            let free = geo.size.width - 8 - 2
            HStack(alignment: .top, spacing: 8) {
                AButton(label: backLabel, bg: .clear, fg: AP.text2, border: AP.control, action: back)
                    .frame(width: free / 3 + 2)
                AButton(label: next, bg: nextBg, fg: nextFg, action: next_)
            }
        }
        .frame(height: 54)
    }
}

/// The connection state machine labels (`cst` in the prototype).
enum AConn {
    static let steps = ["Cable detected", "Port open · 9600 7E1", "Bytes arriving", "Frames valid", "ECU identified"]
}

/// `glyphOf(c)`: green ✓ / amber ! / red ✕ (white) / anything else – (#cfd2d4).
enum AGlyph {
    static func of(_ c: Color) -> (String, Color) {
        if c == AP.green { return ("✓", AP.ink) }
        if c == AP.amber { return ("!", AP.ink) }
        if c == AP.red { return ("✕", .white) }
        return ("–", AP.text2)
    }
}

/// Photo placeholder · h170 (+1 px dashed #3a3e42 border) · r12 · 135° stripes #121315/#151719 10 px · mono 11 centred.
struct APhotoPlaceholder: View {
    @Environment(AppModel.self) private var app
    var text: String
    var body: some View {
        T(app.tr(text), .mono, 11).apFont(.mono, 11)
            .foregroundStyle(AP.label)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 25)
            .frame(maxWidth: .infinity)
            .frame(height: 172)
            .background(Hatch(a: Color(hex: 0x121315), b: AP.card, stripe: 10).clipShape(RoundedRectangle(cornerRadius: 12)))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AP.hatchA, style: ADash.style))
    }
}

/// Bordered list container: `border:1px #23262a; r12; overflow:hidden`; rows draw their own bottom divider.
struct AList<Content: View>: View {
    var radius: CGFloat = 12
    var stroke: Color = AP.border
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(spacing: 0) { content() }
            .clipShape(RoundedRectangle(cornerRadius: max(0, radius - 1)))
            .padding(1)
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(stroke, lineWidth: 1))
    }
}

extension View {
    /// `border-bottom:1px solid #1d2023` on a list row (content-box: the line adds 1 pt).
    func aRowDivider(_ c: Color = AP.divider) -> some View {
        self.padding(.bottom, 1)
            .overlay(alignment: .bottom) { Rectangle().fill(c).frame(height: 1) }
    }
}

/// Check row · `padding:10px 12px; gap:10px` · 20 pt glyph square r5 11/700 · 13/1.35 text · mono 10 status.
struct ACheckRow: View {
    @Environment(AppModel.self) private var app
    var glyph: String
    var fill: Color
    var glyphColor: Color
    var text: String
    var st: String

    var body: some View {
        HStack(spacing: 10) {
            T(glyph, .sans, 11, 700).apFont(.sans, 11, 700)
                .foregroundStyle(glyphColor)
                .frame(width: 20, height: 20)
                .background(RoundedRectangle(cornerRadius: 5).fill(fill))
            ASans(text: text, size: 13, lineHeight: 1.35)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if !st.isEmpty { AMono(text: st, size: 10) }
        }
        .padding(.vertical, 10).padding(.horizontal, 12)
        .aRowDivider()
    }
}
