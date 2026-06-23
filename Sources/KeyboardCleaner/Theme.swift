import SwiftUI

/// Shared visual tokens, mirrored from the Claude Design prototype
/// (app.jsx / macbook.jsx). Native macOS system palette — system blue
/// accent, SF font stack, vibrancy-light surfaces.
enum Theme {
    static let accent = Color(hex: 0x0A84FF)
    static let accentDark = Color(hex: 0x0A6DFF)

    // Window content surface (rgba(246,247,249,...) in the prototype).
    static let windowBackground = Color(hex: 0xF6F7F9)

    // Text colors
    static let textPrimary = Color(hex: 0x1D1D1F)
    static let textSecondary = Color(hex: 0x5C5C63)
    static let textTertiary = Color(hex: 0x6E6E76)
    static let textQuaternary = Color(hex: 0xA1A1A6)
    static let textMuted = Color(hex: 0x86868B)

    // MacBook deck (silver chassis) — linear-gradient(170deg,#eef0f3,#dcdfe4,#cdd0d6)
    static let deck = LinearGradient(
        colors: [Color(hex: 0xEEF0F3), Color(hex: 0xDCDFE4), Color(hex: 0xCDD0D6)],
        startPoint: .top, endPoint: .bottom)

    // Keyboard well (black recess) — linear-gradient(180deg,#0f0f11,#171719)
    static let keyboardWell = LinearGradient(
        colors: [Color(hex: 0x0F0F11), Color(hex: 0x171719)],
        startPoint: .top, endPoint: .bottom)

    // A standard black key — linear-gradient(180deg,#3a3a3d,#252527 55%,#1d1d1f)
    static let key = LinearGradient(
        stops: [
            .init(color: Color(hex: 0x3A3A3D), location: 0),
            .init(color: Color(hex: 0x252527), location: 0.55),
            .init(color: Color(hex: 0x1D1D1F), location: 1)
        ],
        startPoint: .top, endPoint: .bottom)

    // A highlighted (accent) key — linear-gradient(180deg,#3a9bff,#0a84ff 60%,#0a6dff)
    static let keyHighlight = LinearGradient(
        stops: [
            .init(color: Color(hex: 0x3A9BFF), location: 0),
            .init(color: Color(hex: 0x0A84FF), location: 0.60),
            .init(color: Color(hex: 0x0A6DFF), location: 1)
        ],
        startPoint: .top, endPoint: .bottom)

    // Trackpad surface — linear-gradient(180deg,#f4f5f7,#e6e8ec)
    static let trackpad = LinearGradient(
        colors: [Color(hex: 0xF4F5F7), Color(hex: 0xE6E8EC)],
        startPoint: .top, endPoint: .bottom)

    // App icon background — linear-gradient(160deg,#3a9bff,#0a6dff 55%,#0a52d6)
    static let appIcon = LinearGradient(
        stops: [
            .init(color: Color(hex: 0x3A9BFF), location: 0),
            .init(color: Color(hex: 0x0A6DFF), location: 0.55),
            .init(color: Color(hex: 0x0A52D6), location: 1)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let keyLabel = Color(hex: 0xC9C9CE)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity)
    }
}
