import SwiftUI

// Helpers shared by the group B screens (drive & capture: S07–S14, S39, S40).

/// Outlined secondary button · `height:52px; border:1px solid #2f3336; r14; 15/600` — content-box, so 54 pt tall.
struct BOutlineButton: View {
    @Environment(AppModel.self) private var app
    var label: String
    var fg: Color = AP.text
    var border: Color = AP.control
    var fill: Color = .clear
    var height: CGFloat = 54
    var action: () -> Void = {}

    var body: some View {
        T(app.tr(label), .sans, 15, 600)
            .apFont(.sans, 15, 600)
            .foregroundStyle(fg)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(RoundedRectangle(cornerRadius: 14).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(border, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .onTapGesture(perform: action)
            .accessibilityAddTraits(.isButton)
    }
}

/// Two-column CSS grid (`grid-template-columns:1fr 1fr; gap`), rows sized to their tallest cell.
struct BGrid2<Item, Cell: View>: View {
    var items: [Item]
    var gap: CGFloat = 8
    @ViewBuilder var cell: (Item) -> Cell

    var body: some View {
        VStack(spacing: gap) {
            ForEach(Array(stride(from: 0, to: items.count, by: 2)), id: \.self) { i in
                HStack(alignment: .top, spacing: gap) {
                    cell(items[i]).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    if i + 1 < items.count {
                        cell(items[i + 1]).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    } else {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Mono label helper: `T` + `.apFont` with the same face/size/weight.
func BMono(_ s: String, _ size: CGFloat, _ weight: Int = 400, _ color: Color = AP.label) -> some View {
    T(s, .mono, size, weight).apFont(.mono, size, weight).foregroundStyle(color)
}

/// Sans body helper with CSS line-height.
func BSans(_ s: String, _ size: CGFloat, _ weight: Int = 400, _ color: Color = AP.text, lh: CGFloat? = nil) -> some View {
    T(s, .sans, size, weight).apFont(.sans, size, weight, lineHeight: lh).foregroundStyle(color)
}

/// Status-chip definitions shared by S08 (prototype `stDef`).
struct BStDef {
    let l: String
    let bg: Color
    let fg: Color
    let hatched: Bool
    static let all: [BStDef] = [
        BStDef(l: "✓ OK", bg: AP.green, fg: AP.ink, hatched: false),
        BStDef(l: "! CAUTION", bg: AP.amber, fg: AP.ink, hatched: false),
        BStDef(l: "✕ STOP", bg: AP.red, fg: .white, hatched: false),
        BStDef(l: "⌀ FAULT", bg: .clear, fg: AP.text, hatched: true),
        BStDef(l: "– NOT FITTED", bg: .clear, fg: AP.label, hatched: false),
    ]
}

extension Color {
    /// `#rrggbb` colours used inline in the design.
    static let bDim2 = Color(hex: 0x4a4f54)
}
