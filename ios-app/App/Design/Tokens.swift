import SwiftUI

// Design tokens from design-import/ahhpuck-mobile (AhhPuck Mobile Build.dc.html, F00/F01).
// The prototype writes most colours in oklch; `Color.oklch` converts them the same way the
// browser does (OKLab → linear sRGB, clipped), so #6fd087 etc. come out byte-identical.

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: opacity)
    }

    static func oklch(_ l: Double, _ c: Double, _ h: Double, opacity: Double = 1) -> Color {
        let rgb = OKLCH.srgb(l, c, h)
        return Color(.sRGB, red: rgb.0, green: rgb.1, blue: rgb.2, opacity: opacity)
    }
}

enum OKLCH {
    static func srgb(_ L: Double, _ C: Double, _ H: Double) -> (Double, Double, Double) {
        let a = C * cos(H * .pi / 180), b = C * sin(H * .pi / 180)
        let l_ = L + 0.3963377774 * a + 0.2158037573 * b
        let m_ = L - 0.1055613458 * a - 0.0638541728 * b
        let s_ = L - 0.0894841775 * a - 1.2914855480 * b
        let l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_
        let r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
        let g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
        let bl = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
        func enc(_ x: Double) -> Double {
            let v = x <= 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1 / 2.4) - 0.055
            return min(1, max(0, v))
        }
        return (enc(r), enc(g), enc(bl))
    }
}

/// Palette. Names follow the README tokens; values are the ones the prototype actually renders.
enum AP {
    // status — reserved, always paired with a glyph and a word
    static let green = Color.oklch(0.78, 0.14, 150)      // status/ok #6fd087
    static let amber = Color.oklch(0.80, 0.15, 75)       // status/caution #f5ae39
    static let red = Color.oklch(0.68, 0.19, 25)         // status/critical #f75d59
    static let criticalBg = Color(hex: 0x9e141e)         // status/critical-bg
    static let stopButton = Color(hex: 0xe64343)         // status/stop-button
    static let rollback = Color.oklch(0.75, 0.14, 55)    // decision/rollback #f1944f
    static let cyan = Color.oklch(0.80, 0.10, 210)       // target #66cfe1

    // data
    static let baseline = Color(hex: 0x7d8287)
    static let candidate = Color.oklch(0.72, 0.17, 305)  // #be85f9
    static let repeatTrace = Color.oklch(0.82, 0.08, 285) // #bebdf7
    static let mapOnTarget = Color.oklch(0.45, 0.08, 150) // #31623d
    static let mapLean = Color.oklch(0.72, 0.14, 65)     // #e09036
    static let mapVeryLean = Color.oklch(0.60, 0.19, 27) // #db423c
    static let mapNoData = Color(hex: 0x141517)
    static let bandStop = Color.oklch(0.38, 0.09, 25)    // #6a2c29
    static let bandCaution = Color.oklch(0.50, 0.10, 75) // #845a0f
    static let bandOk = Color.oklch(0.45, 0.08, 150)     // #31623d

    // neutrals
    static let canvas = Color(hex: 0x1c1d1f)
    static let screen = Color(hex: 0x0d0e0f)
    static let card = Color(hex: 0x151719)
    static let selectedRow = Color(hex: 0x1c1f22)
    static let raised = Color(hex: 0x24272a)
    static let disabled = Color(hex: 0x2a2d30)
    static let track = Color(hex: 0x1f2225)
    static let border = Color(hex: 0x23262a)
    static let control = Color(hex: 0x2f3336)
    static let divider = Color(hex: 0x1d2023)
    static let hatchA = Color(hex: 0x3a3e42)

    // text
    static let text = Color(hex: 0xe8e6e1)
    static let text2 = Color(hex: 0xcfd2d4)
    static let text3 = Color(hex: 0xa9adb1)
    static let label = Color(hex: 0x8b8f93)
    static let faint = Color(hex: 0x6f7377)
    static let ink = Color(hex: 0x111111)

    /// Evidence tags use neutral greys only (prototype `tagC`).
    static func evidence(_ tag: String) -> Color {
        switch tag {
        case "DOCUMENTED": return text
        case "OBSERVED": return text2
        case "INFERRED": return text3
        default: return label
        }
    }
}

/// The three-state status vocabulary used across the prototype (`glyph(c)`).
enum Status: Int {
    case ok, caution, stop, none

    var color: Color { [AP.green, AP.amber, AP.red, AP.faint][rawValue] }
    var glyph: String { ["✓", "!", "✕", "–"][rawValue] }
}

/// Frame metrics from F00 · Spacing.
enum Metrics {
    static let frameWidth: CGFloat = 390
    /// The design's bars are CSS content-box: `height:50px; padding-bottom:6px` renders 56 pt tall,
    /// `height:82px; padding-top:10px` renders 92 pt. These are the rendered sizes.
    static let statusBar: CGFloat = 56
    static let tabBar: CGFloat = 92
    static let gutter: CGFloat = 18
}
