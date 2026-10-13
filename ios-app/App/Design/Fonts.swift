import SwiftUI
import UIKit

/// The three families from the design, each with IBM Plex Sans JP as the Japanese fallback
/// (the prototype's stacks are `'Barlow Condensed','IBM Plex Sans JP'`, `'IBM Plex Mono','IBM Plex Sans JP'`
/// and `'IBM Plex Sans','IBM Plex Sans JP'`). The fallback is a UIFont cascade list, so Latin glyphs
/// keep their own face and only Japanese characters come from Plex Sans JP.
enum Face {
    case barlow, mono, sans
}

enum APFont {
    private static var cache: [String: UIFont] = [:]

    static func ui(_ face: Face, _ size: CGFloat, _ weight: Int = 400) -> UIFont {
        let key = "\(face)-\(size)-\(weight)"
        if let f = cache[key] { return f }
        let name: String
        switch face {
        case .barlow: name = weight >= 700 ? "BarlowCondensed-Bold" : weight >= 600 ? "BarlowCondensed-SemiBold" : "BarlowCondensed-Medium"
        case .mono: name = weight >= 600 ? "IBMPlexMono-SemiBold" : weight >= 500 ? "IBMPlexMono-Medium" : "IBMPlexMono-Regular"
        case .sans: name = weight >= 600 ? "IBMPlexSans-SmBld" : weight >= 500 ? "IBMPlexSans-Medm" : "IBMPlexSans"
        }
        let jp = weight >= 700 ? "IBMPlexSansJP-Bold" : weight >= 600 ? "IBMPlexSansJP-SemiBold" : weight >= 500 ? "IBMPlexSansJP-Medium" : "IBMPlexSansJP-Regular"
        let base = UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
        let desc = base.fontDescriptor.addingAttributes([
            .cascadeList: [UIFontDescriptor(fontAttributes: [.name: jp])]
        ])
        let font = UIFont(descriptor: desc, size: size)
        cache[key] = font
        return font
    }

    static func font(_ face: Face, _ size: CGFloat, _ weight: Int = 400) -> Font {
        Font(ui(face, size, weight))
    }
}

extension View {
    /// Applies a design font. `lineHeight` is the CSS unitless line-height (e.g. 0.9, 1, 1.45);
    /// nil means CSS `normal`, which is the font's natural line box, same as SwiftUI's default.
    func apFont(_ face: Face, _ size: CGFloat, _ weight: Int = 400, lineHeight: CGFloat? = nil, tabular: Bool = false) -> some View {
        modifier(APFontModifier(face: face, size: size, weight: weight, lineHeight: lineHeight, tabular: tabular))
    }

    /// CSS `letter-spacing` in em. Never applied to Japanese text (README · Internationalisation).
    func apTracking(_ em: CGFloat, size: CGFloat) -> some View {
        modifier(APTrackingModifier(points: em * size))
    }
}

private struct APFontModifier: ViewModifier {
    let face: Face, size: CGFloat, weight: Int, lineHeight: CGFloat?, tabular: Bool

    func body(content: Content) -> some View {
        let ui = APFont.ui(face, size, weight)
        let natural = ui.lineHeight
        let base = content.font(tabular ? APFont.font(face, size, weight).monospacedDigit() : APFont.font(face, size, weight))
        if let lh = lineHeight {
            let box = lh * size
            // Multi-line text gets the extra leading between lines; the outer box is trimmed or
            // grown by half-leading on each side, the way CSS centres glyphs in the line box.
            base
                .lineSpacing(max(0, box - natural))
                .padding(.vertical, (box - natural) / 2)
        } else {
            base
        }
    }
}

private struct APTrackingModifier: ViewModifier {
    @Environment(AppModel.self) private var app
    let points: CGFloat
    func body(content: Content) -> some View {
        content.tracking(app.isJA ? 0 : points)
    }
}

// MARK: - Glyph fallbacks (match the browser)

/// The prototype loads Barlow / Plex from Google Fonts in Latin, Latin-ext, Cyrillic and Greek
/// subsets, so the status glyphs are NOT drawn by Plex: Chrome on macOS falls back per character.
/// These are the faces Chrome actually used in the design render (CSS.getPlatformFontsForNode),
/// so the glyphs look the same in the app. Lucida Grande isn't on iOS; Menlo stands in for it.
enum GlyphFallback {
    private static let mono: [Character: String] = [
        "✓": "Menlo", "✕": "Menlo", "⌀": "Menlo", "◐": "Menlo", "◷": "Menlo", "↺": "Menlo", "↗": "Menlo",
        "₂": "Courier", "≈": "Courier", "λ": "TimesNewRomanPS",
    ]
    private static let sans: [Character: String] = [
        "✓": "Menlo", "✕": "ZapfDingbatsITC", "⌀": "Menlo", "◐": "Menlo", "◷": "Menlo", "↺": "Menlo", "↗": "Menlo",
        "₂": "Courier", "≈": "Courier",
    ]
    private static let barlow: [Character: String] = sans

    static func family(for c: Character, face: Face) -> String? {
        switch face {
        case .mono: return mono[c]
        case .sans: return sans[c]
        case .barlow: return barlow[c]
        }
    }

    /// PostScript name for a fallback family at a CSS weight (Chrome uses the bold face from 600 up).
    static func postScript(_ family: String, weight: Int) -> String {
        let bold = weight >= 600
        switch family {
        case "Menlo": return bold ? "Menlo-Bold" : "Menlo-Regular"
        case "Courier": return bold ? "Courier-Bold" : "Courier"
        case "TimesNewRomanPS": return bold ? "TimesNewRomanPS-BoldMT" : "TimesNewRomanPSMT"
        default: return family
        }
    }

    static func needsFallback(_ s: String, face: Face) -> Bool {
        s.contains { family(for: $0, face: face) != nil }
    }
}

/// A design text run: the face, size and weight from the design, with the browser's per-glyph
/// fallbacks applied. Returns `Text`, so runs can be concatenated with `+`.
func T(_ s: String, _ face: Face, _ size: CGFloat, _ weight: Int = 400, tabular: Bool = false) -> Text {
    let base = tabular ? APFont.font(face, size, weight).monospacedDigit() : APFont.font(face, size, weight)
    guard GlyphFallback.needsFallback(s, face: face) else { return Text(verbatim: s).font(base) }
    var out = Text(verbatim: "")
    var run = ""
    func flush() { if !run.isEmpty { out = out + Text(verbatim: run).font(base); run = "" } }
    for c in s {
        if let fam = GlyphFallback.family(for: c, face: face) {
            flush()
            let ui = UIFont(name: GlyphFallback.postScript(fam, weight: weight), size: size) ?? APFont.ui(face, size, weight)
            out = out + Text(verbatim: String(c)).font(Font(ui))
        } else {
            run.append(c)
        }
    }
    flush()
    return out
}
