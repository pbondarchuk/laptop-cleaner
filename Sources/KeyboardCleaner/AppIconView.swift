import SwiftUI

/// The blue rounded-square app glyph: a broom plus a sparkle, recreated
/// from the SVG in the prototype's `AppIcon`.
struct AppIconView: View {
    var size: CGFloat = 64

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
            .fill(Theme.appIcon)
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                    .strokeBorder(.white.opacity(0.4), lineWidth: 0.5)
                    .blendMode(.overlay)
            )
            .overlay(glyph)
            .frame(width: size, height: size)
            .shadow(color: Theme.accent.opacity(0.34), radius: 8, x: 0, y: 6)
    }

    /// Drawn in a 24×24 space, scaled to 0.56 × icon size and centered.
    private var glyph: some View {
        let g = size * 0.56
        let unit = g / 24
        return ZStack {
            // Broom head — rounded bar, angled like a sweeping broom.
            RoundedRectangle(cornerRadius: 1.4 * unit, style: .continuous)
                .fill(.white.opacity(0.95))
                .frame(width: 11 * unit, height: 6 * unit)
                .rotationEffect(.degrees(-32))
                .offset(x: -g * 0.16, y: g * 0.20)
            // Sparkle — 4-point star, upper right.
            Sparkle()
                .fill(.white)
                .frame(width: 8 * unit, height: 8 * unit)
                .offset(x: g * 0.18, y: -g * 0.21)
        }
        .frame(width: g, height: g)
    }
}

/// A 4-point sparkle/star that fills its rect.
private struct Sparkle: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let cx = rect.midX, cy = rect.midY
        // Concave-sided star: tips at edges, waist pulled ~28% toward center.
        let waist: CGFloat = 0.28
        var path = Path()
        path.move(to: CGPoint(x: cx, y: rect.minY))                       // top tip
        path.addLine(to: CGPoint(x: cx + w * waist, y: cy - h * waist))
        path.addLine(to: CGPoint(x: rect.maxX, y: cy))                    // right tip
        path.addLine(to: CGPoint(x: cx + w * waist, y: cy + h * waist))
        path.addLine(to: CGPoint(x: cx, y: rect.maxY))                    // bottom tip
        path.addLine(to: CGPoint(x: cx - w * waist, y: cy + h * waist))
        path.addLine(to: CGPoint(x: rect.minX, y: cy))                    // left tip
        path.addLine(to: CGPoint(x: cx - w * waist, y: cy - h * waist))
        path.closeSubpath()
        return path
    }
}
