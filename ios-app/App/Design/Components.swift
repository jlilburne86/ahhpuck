import SwiftUI

// Shared building blocks from F00 · Components. Box model note: the design's CSS uses
// content-box, so a block with `border:1px; padding:12px 14px` insets its content by 13/15.
// `apCard` adds the border width to the padding for you; everything else maps 1:1 to points.

// MARK: - Screen scaffold

/// Kept for source compatibility with screens written against the earlier design, whose status bar
/// showed the transport ("USB-C · 9600"). The current design (F02 iOS chrome) uses the system status bar.
enum StatusStyle { case label, dim }

/// The 390×844 phone screen (F02 iOS chrome): the 50 pt status-bar band, content, and the 83 pt tab bar
/// when `tab` is set. iOS draws the status bar (time, signal, Wi-Fi, battery) and the home indicator
/// itself, exactly as the design depicts them; the app only reserves their space.
/// Content scrolls only when it is taller than the space between the bars; `Spacer()` inside
/// content behaves like the design's `margin-top:auto`.
struct PhoneScreen<Content: View>: View {
    @Environment(AppModel.self) private var app
    var tab: AppTab?
    var status: String = ""
    var statusStyle: StatusStyle = .label
    var statusColor: Color? = nil
    var background: Color = AP.screen
    var foreground: Color = AP.text
    var scrolls: Bool = true
    /// The "BETA · demo data" strip; off for the disclaimer itself and the first-run flow.
    var demoStrip: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { outer in
            VStack(spacing: 0) {
                // `height:50px; box-sizing:border-box` — never less than the device's real status bar.
                Color.clear.frame(height: max(Metrics.statusBar, outer.safeAreaInsets.top))
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
                if demoStrip, !app.router.onboarding { DemoStrip() }
                if let tab, !app.router.onboarding { TabBar(active: tab) }
                else { Color.clear.frame(height: outer.safeAreaInsets.bottom) }
            }
            .ignoresSafeArea()
        }
        .foregroundStyle(foreground)
        .background(background.ignoresSafeArea())
        .environment(\.locale, Locale(identifier: app.isJA ? "ja_JP" : "en_AU"))
    }
}

/// Tab bar (F02): 83 pt incl. the home-indicator area · border-top #1f2225 · padding-top 6 ·
/// 49 pt items: 25 pt stroked icon, 2 pt gap, 10 pt label (+0.01em) · active #fff 600 (stroke 2.1),
/// inactive #8b8f93 500 (stroke 1.7).
struct TabBar: View {
    @Environment(AppModel.self) private var app
    var active: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { t in
                let on = t == active
                Button { app.router.select(t) } label: {
                    VStack(spacing: 2) {
                        TabIcon(tab: t)
                            .stroke(style: StrokeStyle(lineWidth: on ? 2.1 : 1.7, lineCap: .round, lineJoin: .round))
                            .frame(width: 25, height: 25)
                        T(app.tr(t.title), .sans, 10, on ? 600 : 500)
                            .apFont(.sans, 10, on ? 600 : 500)
                            .apTracking(0.01, size: 10)
                            .lineLimit(1)
                    }
                    .foregroundStyle(on ? Color.white : AP.label)
                    .frame(maxWidth: .infinity)
                    .frame(height: 49)
                    .contentShape(Rectangle())
                }
                .buttonStyle(APPressableStyle())
            }
        }
        .padding(.top, 6 + 1)
        .frame(height: Metrics.tabBar, alignment: .top)
        .background(AP.screen)
        .overlay(alignment: .top) { Rectangle().fill(AP.track).frame(height: 1) }
    }
}

/// The five tab glyphs from the design, in their 24×24 viewBox, scaled to the frame.
struct TabIcon: Shape {
    var tab: AppTab
    func path(in rect: CGRect) -> Path {
        var p = Path()
        switch tab {
        case .live: // M4 16a8 8 0 1 1 16 0 · M12 16l4-5
            p.addArc(center: CGPoint(x: 12, y: 16), radius: 8, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            p.move(to: CGPoint(x: 12, y: 16)); p.addLine(to: CGPoint(x: 16, y: 11))
        case .map: // rect 4,4 16×16 r2 · M4 9.5h16 M4 14.5h16 M9.5 4v16 M14.5 4v16
            p.addRoundedRect(in: CGRect(x: 4, y: 4, width: 16, height: 16), cornerSize: CGSize(width: 2, height: 2))
            for y in [9.5, 14.5] { p.move(to: CGPoint(x: 4, y: y)); p.addLine(to: CGPoint(x: 20, y: y)) }
            for x in [9.5, 14.5] { p.move(to: CGPoint(x: x, y: 4)); p.addLine(to: CGPoint(x: x, y: 20)) }
        case .runs: // M6 21V4 · M6 4h11l-2.5 4.5L17 13H6
            p.move(to: CGPoint(x: 6, y: 21)); p.addLine(to: CGPoint(x: 6, y: 4))
            p.move(to: CGPoint(x: 6, y: 4)); p.addLine(to: CGPoint(x: 17, y: 4)); p.addLine(to: CGPoint(x: 14.5, y: 8.5))
            p.addLine(to: CGPoint(x: 17, y: 13)); p.addLine(to: CGPoint(x: 6, y: 13))
        case .review: // M12 3l7 3v6c0 4.2-3 7.4-7 9-4-1.6-7-4.8-7-9V6z · M9 12.2l2.2 2.2L15.2 10
            p.move(to: CGPoint(x: 12, y: 3)); p.addLine(to: CGPoint(x: 19, y: 6)); p.addLine(to: CGPoint(x: 19, y: 12))
            p.addCurve(to: CGPoint(x: 12, y: 21), control1: CGPoint(x: 19, y: 16.2), control2: CGPoint(x: 16, y: 19.4))
            p.addCurve(to: CGPoint(x: 5, y: 12), control1: CGPoint(x: 8, y: 19.4), control2: CGPoint(x: 5, y: 16.2))
            p.addLine(to: CGPoint(x: 5, y: 6)); p.closeSubpath()
            p.move(to: CGPoint(x: 9, y: 12.2)); p.addLine(to: CGPoint(x: 11.2, y: 14.4)); p.addLine(to: CGPoint(x: 15.2, y: 10))
        case .garage: // M3.5 11L12 4.5l8.5 6.5V20h-17z · M8.5 20v-5h7v5
            p.move(to: CGPoint(x: 3.5, y: 11)); p.addLine(to: CGPoint(x: 12, y: 4.5)); p.addLine(to: CGPoint(x: 20.5, y: 11))
            p.addLine(to: CGPoint(x: 20.5, y: 20)); p.addLine(to: CGPoint(x: 3.5, y: 20)); p.closeSubpath()
            p.move(to: CGPoint(x: 8.5, y: 20)); p.addLine(to: CGPoint(x: 8.5, y: 15)); p.addLine(to: CGPoint(x: 15.5, y: 15)); p.addLine(to: CGPoint(x: 15.5, y: 20))
        }
        return p.applying(CGAffineTransform(scaleX: rect.width / 24, y: rect.height / 24).translatedBy(x: rect.minX, y: rect.minY))
    }
}

/// Screen header · `padding:10px 18px 0` · title Barlow 700 24 · mono 11 #8b8f93 subtitle.
struct ScreenHeader<Trailing: View>: View {
    @Environment(AppModel.self) private var app
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if app.router.onboarding ? !app.router.onboardingPath.isEmpty : (app.router.paths[app.router.tab]?.isEmpty == false) {
                BackRow()
            }
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

struct DemoDataPill: View {
    @Environment(AppModel.self) private var app
    var body: some View {
        Text(app.tr("DEMO DATA"))
            .apFont(.mono, 11, 600)
            .foregroundStyle(AP.amber)
            .padding(.horizontal, 9).padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(AP.amber.opacity(0.7), lineWidth: 1))
            .accessibilityLabel(app.tr("Demo data"))
    }
}

struct BackRow: View {
    @Environment(AppModel.self) private var app
    var body: some View {
        Button {
            app.router.back()
        } label: {
            HStack(spacing: 4) {
                Text("‹").font(.system(size: 25, weight: .regular))
                Text(app.tr("Back")).apFont(.sans, 13, 600)
            }
            .foregroundStyle(AP.text2)
            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(APPressableStyle())
        .padding(.horizontal, Metrics.gutter)
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
        Button { if enabled { action() } else { onGated?() } } label: {
            T(app.tr(label), .sans, 15, 600)
                .apFont(.sans, 15, 600)
                .foregroundStyle(enabled ? fg : AP.faint)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(RoundedRectangle(cornerRadius: 14).fill(enabled ? fill : AP.disabled))
                .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(APPressableStyle())
    }
}

/// Selectable chip · `padding:7px 11px; r8; 13px`, selected = inverted white (prototype `sel()`).
struct Chip: View {
    @Environment(AppModel.self) private var app
    var label: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            T(app.tr(label), .sans, 13, 400)
                .apFont(.sans, 13)
                .foregroundStyle(selected ? AP.ink : AP.text2)
                .lineLimit(1)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(selected ? AP.text : .clear))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(selected ? AP.text : AP.control, lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(APPressableStyle())
    }
}

struct APPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.62 : 1)
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

/// Real time; `-demoClock` pins it to the design's 9:41 (for screens that draw a clock, e.g. S14).
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
