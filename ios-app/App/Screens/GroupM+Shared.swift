import SwiftUI

// Helpers for the screens built in the main session (stubs left after the group agents stopped).

/// Status-dot step row: `display:flex; gap:10px; padding:7px 0` — 10 pt dot, sans 13 label, mono 11 state.
struct MDotRow: View {
    @Environment(AppModel.self) private var app
    var label: String
    var dot: Color
    var fg: Color
    var state: String

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(dot).frame(width: 10, height: 10)
            T(app.tr(label), .sans, 13).apFont(.sans, 13).foregroundStyle(fg)
                .frame(maxWidth: .infinity, alignment: .leading)
            T(app.tr(state), .mono, 11).apFont(.mono, 11).foregroundStyle(AP.label)
        }
        .padding(.vertical, 7)
    }
}

/// A design text run as a view: `M("LABEL", .mono, 10, color: AP.label)`.
struct M: View {
    @Environment(AppModel.self) private var app
    var text: String
    var face: Face
    var size: CGFloat
    var weight: Int = 400
    var color: Color? = nil
    var lineHeight: CGFloat? = nil
    var translate = true

    init(_ text: String, _ face: Face, _ size: CGFloat, _ weight: Int = 400, color: Color? = nil, lineHeight: CGFloat? = nil, translate: Bool = true) {
        self.text = text; self.face = face; self.size = size; self.weight = weight
        self.color = color; self.lineHeight = lineHeight; self.translate = translate
    }

    var body: some View {
        let t = T(translate ? app.tr(text) : text, face, size, weight).apFont(face, size, weight, lineHeight: lineHeight)
        if let color { t.foregroundStyle(color) } else { t }
    }
}

/// Bottom CTA `margin:auto 18px Npx; height:52px; r14; 15/600`.
struct MButton: View {
    @Environment(AppModel.self) private var app
    var label: String
    var bg: Color = AP.text
    var fg: Color = AP.ink
    var border: Color? = nil
    var bottom: CGFloat = 16
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            T(app.tr(label), .sans, 15, 600)
                .apFont(.sans, 15, 600)
                .foregroundStyle(fg)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 14).fill(bg))
                .overlay { if let border { RoundedRectangle(cornerRadius: 14).strokeBorder(border, lineWidth: 1) } }
                .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(APPressableStyle())
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, bottom)
    }
}

/// `x.toFixed(d)` as JavaScript prints it.
func jsFixed(_ x: Double, _ d: Int) -> String { String(format: "%.\(d)f", x) }

/// Bordered list `border:1px #23262a; r12; overflow:hidden`; every row carries `border-bottom:1px #1d2023`.
struct MList<Content: View>: View {
    var radius: CGFloat = 12
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(spacing: 0) { content() }
            .padding(1)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(AP.border, lineWidth: 1))
    }
}

extension View {
    /// List row: padding v×h, then the 1 px #1d2023 bottom divider.
    func mRow(_ v: CGFloat = 9, _ h: CGFloat = 12, divider: Color = AP.divider) -> some View {
        self.padding(.vertical, v).padding(.horizontal, h)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) { Rectangle().fill(divider).frame(height: 1) }
            .padding(.bottom, 1)
    }
}

/// Small selectable chip `padding:Vpx Hpx; r8; border 1px; Npx` with `sel()` colours.
struct MChip: View {
    @Environment(AppModel.self) private var app
    var label: String
    var on: Bool
    var size: CGFloat = 12
    var v: CGFloat = 6
    var h: CGFloat = 10
    var center = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            T(app.tr(label), .sans, size).apFont(.sans, size)
                .foregroundStyle(on ? AP.ink : AP.text2)
                .lineLimit(1).fixedSize(horizontal: !center, vertical: false)
                .padding(.vertical, v + 1).padding(.horizontal, h + 1)
                .frame(maxWidth: center ? .infinity : nil)
                .background(RoundedRectangle(cornerRadius: 8).fill(on ? AP.text : .clear))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(on ? AP.text : AP.control, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(APPressableStyle())
    }
}
