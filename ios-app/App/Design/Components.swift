import SwiftUI

// Shared building blocks from F00 · Components. Box model note: the design's CSS uses
// content-box, so a block with `border:1px; padding:12px 14px` insets its content by 13/15.
// `apCard` adds the border width to the padding for you; everything else maps 1:1 to points.

// MARK: - Screen scaffold

/// Right side of the 50 pt status bar. Most screens show the transport in mono 12 #8b8f93;
/// v1.2 screens use mono 12 at 70% opacity of the screen's text colour.
enum StatusStyle { case label, dim }

/// The 390×844 phone screen: 50 pt status bar, content, and the 82 pt tab bar when `tab` is set.
/// The system status bar is hidden; this bar replaces it, exactly as the design draws it.
/// Content scrolls only when it is taller than the space between the bars; `Spacer()` inside
/// content behaves like the design's `margin-top:auto`.
struct PhoneScreen<Content: View>: View {
    @Environment(AppModel.self) private var app
    var tab: AppTab?
    var status: String = "USB-C · 9600"
    var statusStyle: StatusStyle = .label
    var statusColor: Color? = nil
    var background: Color = AP.screen
    var foreground: Color = AP.text
    var scrolls: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            StatusBar(right: status, style: statusStyle, color: statusColor, foreground: foreground)
            GeometryReader { geo in
                if scrolls {
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 0) { content() }
                            .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .topLeading)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollIndicators(.hidden)
                } else {
                    VStack(alignment: .leading, spacing: 0) { content() }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            if let tab { TabBar(active: tab) }
        }
        .foregroundStyle(foreground)
        .background(background)
        .ignoresSafeArea()
        .environment(\.locale, Locale(identifier: app.isJA ? "ja_JP" : "en_AU"))
    }
}

struct StatusBar: View {
    @Environment(AppModel.self) private var app
    var right: String
    var style: StatusStyle = .label
    var color: Color? = nil
    var foreground: Color = AP.text

    var body: some View {
        HStack(alignment: .bottom) {
            Clock().apFont(.sans, 15, 600)
            Spacer()
            T(app.tr(right), .mono, 12, 400)
                .apFont(.mono, 12)
                .foregroundStyle(color ?? (style == .label ? AP.label : foreground))
                .opacity(style == .dim ? 0.7 : 1)
                .contentShape(Rectangle())
                .onTapGesture { app.router.go(.S04) }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 6)
        .frame(height: Metrics.statusBar, alignment: .bottom)
    }
}

/// Real time in the app; `-demoClock` pins it to the design's 9:41 for screenshots.
struct Clock: View {
    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-demoClock") {
            Text(verbatim: "9:41")
        } else {
            TimelineView(.everyMinute) { ctx in
                Text(verbatim: ctx.date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute()))
            }
        }
    }
}

/// AppTab bar · h82 · active #fff 600 · inactive #6f7377, 11 px, top border #1f2225, padding-top 10.
struct TabBar: View {
    @Environment(AppModel.self) private var app
    var active: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { t in
                T(app.tr(t.title), .sans, 11, t == active ? 600 : 400)
                    .apFont(.sans, 11, t == active ? 600 : 400)
                    .foregroundStyle(t == active ? Color.white : AP.faint)
                    .frame(maxWidth: .infinity)
                    .frame(height: Metrics.tabBar - 10, alignment: .top)
                    .contentShape(Rectangle())
                    .onTapGesture { app.router.select(t) }
            }
        }
        .padding(.top, 10)
        .frame(height: Metrics.tabBar, alignment: .top)
        .overlay(alignment: .top) { Rectangle().fill(AP.track).frame(height: 1) }
    }
}

/// Screen header · `padding:10px 18px 0` · title Barlow 700 24 · mono 11 #8b8f93 subtitle.
struct ScreenHeader<Trailing: View>: View {
    @Environment(AppModel.self) private var app
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                T(app.tr(title), .barlow, 24, 700).apFont(.barlow, 24, 700)
                if let subtitle { T(app.tr(subtitle), .mono, 11, 400).apFont(.mono, 11).foregroundStyle(AP.label) }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 10)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// The READ-ONLY pill from the Live header.
struct ReadOnlyPill: View {
    @Environment(AppModel.self) private var app
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(AP.green).frame(width: 7, height: 7)
            Text(app.tr("READ-ONLY"))
        }
        .apFont(.mono, 11)
        .foregroundStyle(AP.text2)
        .padding(.horizontal, 9).padding(.vertical, 6)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(AP.control, lineWidth: 1))
    }
}

// MARK: - Surfaces

extension View {
    /// Card · surface #151719 · border #23262a · r12 · pad 12/14 (CSS padding; border is added).
    func apCard(vertical: CGFloat = 12, horizontal: CGFloat = 14, radius: CGFloat = 12,
                fill: Color = AP.card, stroke: Color = AP.border, lineWidth: CGFloat = 1) -> some View {
        self
            .padding(.vertical, vertical + lineWidth)
            .padding(.horizontal, horizontal + lineWidth)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: radius).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(stroke, lineWidth: lineWidth))
    }

    /// `margin:10px 18px 0` — the standard block spacing on a screen.
    func block(top: CGFloat = 10) -> some View {
        self.padding(.horizontal, Metrics.gutter).padding(.top, top)
    }

    /// Bordered box (no fill) — `border:1px solid c; border-radius:r`.
    func outlined(_ color: Color = AP.control, radius: CGFloat = 6, lineWidth: CGFloat = 1) -> some View {
        overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(color, lineWidth: lineWidth))
    }
}

// MARK: - Text pieces

/// Evidence / source tag · mono 10 · 1×5 padding · r4 · border #2f3336.
struct Tag: View {
    @Environment(AppModel.self) private var app
    var text: String
    var color: Color = AP.label
    var border: Color = AP.control
    var fill: Color = .clear

    var body: some View {
        T(app.tr(text), .mono, 10, 400)
            .apFont(.mono, 10)
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(border, lineWidth: 1))
            .fixedSize()
    }
}

/// Status chip · mono 10/600 · r4 (F00: ✓ OK / ! CAUTION / ✕ STOP / ⌀ FAULT / – NOT FITTED).
struct StatusChip: View {
    @Environment(AppModel.self) private var app
    var text: String
    var fill: Color
    var fg: Color = AP.ink
    var hatched = false
    var outlined = false

    var body: some View {
        T(app.tr(text), .mono, 10, 600)
            .apFont(.mono, 10, 600)
            .foregroundStyle(fg)
            .lineLimit(1)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background {
                if hatched { Hatch().clipShape(RoundedRectangle(cornerRadius: 4)) }
                else { RoundedRectangle(cornerRadius: 4).fill(fill) }
            }
            .overlay { if outlined { RoundedRectangle(cornerRadius: 4).strokeBorder(AP.control, lineWidth: 1) } }
            .fixedSize()
    }
}

// MARK: - Controls

/// Primary button · h52 · r14 · 15/600 · #e8e6e1 on #111. Gated: #2a2d30 / #6f7377, and the label
/// says what is missing. A gated tap opens `onGated` (normally the S41 "Why is this locked?" sheet).
struct PrimaryButton: View {
    @Environment(AppModel.self) private var app
    var label: String
    var enabled = true
    var fill: Color = AP.text
    var fg: Color = AP.ink
    var height: CGFloat = 52
    var action: () -> Void = {}
    var onGated: (() -> Void)? = nil

    var body: some View {
        T(app.tr(label), .sans, 15, 600)
            .apFont(.sans, 15, 600)
            .foregroundStyle(enabled ? fg : AP.faint)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(RoundedRectangle(cornerRadius: 14).fill(enabled ? fill : AP.disabled))
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .onTapGesture { if enabled { action() } else { onGated?() } }
            .accessibilityAddTraits(.isButton)
    }
}

/// Selectable chip · `padding:7px 11px; r8; 13px`, selected = inverted white (prototype `sel()`).
struct Chip: View {
    @Environment(AppModel.self) private var app
    var label: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        T(app.tr(label), .sans, 13, 400)
            .apFont(.sans, 13)
            .foregroundStyle(selected ? AP.ink : AP.text2)
            .lineLimit(1)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(selected ? AP.text : .clear))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(selected ? AP.text : AP.control, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture(perform: action)
    }
}

/// Glyph square used for checks (✓ ! ✕ –): a filled square in the status colour with the glyph.
struct GlyphSquare: View {
    var status: Status
    var size: CGFloat = 18
    var radius: CGFloat = 4
    var fontSize: CGFloat = 11

    var body: some View {
        T(status.glyph, .mono, fontSize, 600)
            .apFont(.mono, fontSize, 600)
            .foregroundStyle(status == .none ? AP.label : (status == .stop ? Color.white : AP.ink))
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: radius).fill(status == .none ? AP.disabled : status.color))
    }
}

/// Tick box: white when ticked (selection is never a status colour).
struct CheckBox: View {
    var on: Bool
    var size: CGFloat = 20
    var radius: CGFloat = 5

    var body: some View {
        T(on ? "✓" : "", .sans, size * 0.6, 700)
            .apFont(.sans, size * 0.6, 700)
            .foregroundStyle(AP.ink)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: radius).fill(on ? AP.text : .clear))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(on ? AP.text : AP.control, lineWidth: 1.5))
    }
}

// MARK: - Patterns & charts

/// `repeating-linear-gradient(135deg, a 0 w, b w 2w)` — the fault hatch (#3a3e42 / #24272a, 4 px)
/// and the hatched red-line zone. `b = .clear` gives the transparent variant.
struct Hatch: View {
    var a: Color = AP.hatchA
    var b: Color = AP.raised
    var stripe: CGFloat = 4

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(b))
            // 135deg CSS gradient: offset = (x + y) / √2 from the top-left corner, so stripes are
            // the bands x + y ∈ [c, c + w√2) — they run bottom-left to top-right ("/").
            let band = stripe * sqrt(2), period = band * 2
            var c: CGFloat = 0
            while c < size.width + size.height {
                var p = Path()
                p.move(to: CGPoint(x: c, y: 0))
                p.addLine(to: CGPoint(x: c + band, y: 0))
                p.addLine(to: CGPoint(x: c + band - size.height, y: size.height))
                p.addLine(to: CGPoint(x: c - size.height, y: size.height))
                p.closeSubpath()
                ctx.fill(p, with: .color(a))
                c += period
            }
        }
    }
}

extension Path {
    /// Polyline through points (the prototype's `M x y L x y …` strings).
    init(polyline pts: [CGPoint]) {
        self.init()
        guard let first = pts.first else { return }
        move(to: first)
        for p in pts.dropFirst() { addLine(to: p) }
    }
}

/// Draws a fixed-size SVG-like viewBox scaled to the frame, like `<svg viewBox>` with default
/// `preserveAspectRatio` when the aspect matches.
struct ViewBox<Content: View>: View {
    var width: CGFloat
    var height: CGFloat
    @ViewBuilder var content: () -> Content
    var body: some View {
        GeometryReader { geo in
            content()
                .frame(width: width, height: height, alignment: .topLeading)
                .scaleEffect(x: geo.size.width / width, y: geo.size.height / height, anchor: .topLeading)
        }
        .aspectRatio(width / height, contentMode: .fit)
    }
}
