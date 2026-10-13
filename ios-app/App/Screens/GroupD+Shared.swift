import SwiftUI

// Helpers shared by the group-D screens (S24–S33, S42). Ports of small prototype helpers.

/// The prototype's literal colours used across group D.
enum DC {
    static let violet = AP.candidate                       // oklch(0.72 0.17 305)
    static func violet(_ a: Double) -> Color { Color.oklch(0.72, 0.17, 305, opacity: a) }
    static let hatchStripe = Color(hex: 0x3a3e42)
    static let dimValue = Color(hex: 0x4a4f54)
}

/// A design text run with its CSS box: `T(...)` plus `.apFont` (same face/size/weight).
func DT(_ s: String, _ face: Face, _ size: CGFloat, _ weight: Int = 400, lh: CGFloat? = nil) -> some View {
    T(s, face, size, weight).apFont(face, size, weight, lineHeight: lh)
}

/// Prototype `sel(on)`: inverted white when selected, outlined otherwise.
struct DSel {
    let bg: Color, fg: Color, border: Color
    init(_ on: Bool) {
        bg = on ? AP.text : .clear
        fg = on ? AP.ink : AP.text2
        border = on ? AP.text : AP.control
    }
}

/// A `sel()` option box: `padding:Vpx Hpx; border-radius:R; border:1px` with centred text.
struct DOption: View {
    @Environment(AppModel.self) private var app
    var label: String
    var on: Bool
    var size: CGFloat = 13
    var vPad: CGFloat = 7
    var hPad: CGFloat = 11
    var radius: CGFloat = 8
    var height: CGFloat? = nil
    var fill = true
    var action: () -> Void

    var body: some View {
        let s = DSel(on)
        DT(app.tr(label), .sans, size)
            .foregroundStyle(s.fg)
            .lineLimit(1)
            .padding(.vertical, height == nil ? vPad + 1 : 0)
            .padding(.horizontal, hPad + 1)
            .frame(maxWidth: fill ? .infinity : nil)
            .frame(height: height)
            .background(RoundedRectangle(cornerRadius: radius).fill(s.bg))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(s.border, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: radius))
            .onTapGesture(perform: action)
    }
}

/// Legend swatch + label (`display:flex;align-items:center;gap:5px;white-space:nowrap`).
struct DLegend: View {
    @Environment(AppModel.self) private var app
    var label: String
    var color: Color
    var size: CGFloat = 10
    var radius: CGFloat = 3
    var font: CGFloat = 9
    var border: Color? = nil

    var body: some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: radius).fill(color)
                .overlay { if let border { RoundedRectangle(cornerRadius: radius).strokeBorder(border, lineWidth: 1) } }
                .frame(width: size, height: size)
            DT(app.tr(label), .mono, font).lineLimit(1).fixedSize()
        }
    }
}

/// The ring / dial / radar easing (`ease = 1 − (1 − fr)³`, fr over 16 ticks of 140 ms ≈ 2.24 s).
/// The prototype derives it from `t − ringT`; with the `live` tweak off (the design's default
/// state, and the screenshot harness) t never advances, so ease stays 0. In the running app the
/// animation plays from when the screen appears, and `replay()` restarts it.
@MainActor
@Observable
final class DRing {
    static let shared = DRing()
    static let duration = 16 * 0.14
    var start = Date()
    /// Design-reference mode: `-demoClock` without `-live` keeps the prototype's static t = ringT.
    let frozen: Bool = {
        let a = ProcessInfo.processInfo.arguments
        return a.contains("-demoClock") && !a.contains("-live")
    }()
    func replay() { start = Date() }
    func ease(at date: Date) -> Double {
        if frozen { return 0 }
        let fr = min(1, max(0, date.timeIntervalSince(start) / DRing.duration))
        return 1 - pow(1 - fr, 3)
    }
    func done(at date: Date) -> Bool { frozen || date.timeIntervalSince(start) >= DRing.duration }
}

/// Re-renders `content(ease)` every frame while the ring animation runs.
struct DEased<Content: View>: View {
    @State private var ring = DRing.shared
    @ViewBuilder var content: (Double) -> Content
    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: ring.frozen)) { ctx in
            content(ring.ease(at: ctx.date))
        }
    }
}

/// Polyline approximation of an SVG arc around (cx, cy) — angles in maths convention
/// (y up), as the prototype's `pt()` uses them.
func dArc(cx: Double, cy: Double, r: Double, from a0: Double, to a1: Double, steps: Int = 96) -> Path {
    Path(polyline: (0...steps).map { i in
        let a = a0 + (a1 - a0) * Double(i) / Double(steps)
        return CGPoint(x: cx + r * cos(a), y: cy - r * sin(a))
    })
}

/// Thin divider line inside list cards (`border-bottom:1px solid #1d2023`).
struct DDivider: View {
    var color: Color = AP.divider
    var body: some View { Rectangle().fill(color).frame(height: 1) }
}

/// Decision colours from the ledger (`decC`).
enum DDecision {
    static func color(_ d: String) -> Color {
        switch d {
        case "Accept": return AP.green
        case "Repeat": return AP.amber
        case "Rollback": return AP.rollback
        case "Abort": return AP.red
        default: return AP.cyan
        }
    }
}

/// `display:flex; flex-wrap:wrap; gap:g` — items left to right, wrapping onto new lines.
struct DFlow: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews)
        let h = rows.last.map { $0.y + $0.h } ?? 0
        return CGSize(width: proposal.width ?? rows.map { $0.w }.max() ?? 0, height: h)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(width: bounds.width, subviews) {
            var x = bounds.minX
            for i in row.items {
                let s = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(s))
                x += s.width + spacing
            }
        }
    }

    private struct Row { var items: [Int] = []; var y: CGFloat = 0; var w: CGFloat = 0; var h: CGFloat = 0 }
    private func arrange(width: CGFloat, _ subviews: Subviews) -> [Row] {
        var rows: [Row] = [], cur = Row()
        for (i, v) in subviews.enumerated() {
            let s = v.sizeThatFits(.unspecified)
            if !cur.items.isEmpty && cur.w + spacing + s.width > width + 0.5 {
                rows.append(cur)
                cur = Row(y: cur.y + cur.h + lineSpacing)
            }
            cur.w += (cur.items.isEmpty ? 0 : spacing) + s.width
            cur.h = max(cur.h, s.height)
            cur.items.append(i)
        }
        if !cur.items.isEmpty { rows.append(cur) }
        return rows
    }
}
