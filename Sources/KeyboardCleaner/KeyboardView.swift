import SwiftUI

/// A simplified MacBook keyboard: six weighted rows of black keys.
/// `highlightEsc` makes the Escape key glow (used while the touchpad is
/// locked, since Escape is how you unlock it).
struct KeyboardView: View {
    let highlightEsc: Bool

    private let spacing: CGFloat = 4

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { _, row in
                KeyRow(row: row, spacing: spacing, highlightEsc: highlightEsc)
                    .frame(maxHeight: .infinity)
            }
        }
    }

    // [label, weight] per key, matching the prototype's KEY_ROWS.
    static let rows: [[KeySpec]] = [
        [k("esc", 1.6), k("F1"), k("F2"), k("F3"), k("F4"), k("F5"), k("F6"),
         k("F7"), k("F8"), k("F9"), k("F10"), k("F11"), k("F12"), k("\u{23FB}")],
        [k("~"), k("1"), k("2"), k("3"), k("4"), k("5"), k("6"), k("7"), k("8"),
         k("9"), k("0"), k("\u{2013}"), k("+"), k("delete", 1.7)],
        [k("tab", 1.7), k("Q"), k("W"), k("E"), k("R"), k("T"), k("Y"), k("U"),
         k("I"), k("O"), k("P"), k("["), k("]"), k("\u{00A0}", 1.6)],
        [k("caps", 1.9), k("A"), k("S"), k("D"), k("F"), k("G"), k("H"), k("J"),
         k("K"), k("L"), k(";"), k("'"), k("return", 1.95)],
        [k("shift", 2.4), k("Z"), k("X"), k("C"), k("V"), k("B"), k("N"), k("M"),
         k(","), k("."), k("/"), k("shift", 2.45)],
        [k("fn", 1.1), k("\u{2303}", 1.1), k("\u{2325}", 1.1), k("\u{2318}", 1.45),
         k("", 6.0), k("\u{2318}", 1.45), k("\u{2325}", 1.1), k("ARROWS", 2.7)]
    ]

    private static func k(_ label: String, _ weight: Double = 1) -> KeySpec {
        KeySpec(label: label, weight: weight)
    }
}

struct KeySpec {
    let label: String
    let weight: Double
}

/// Lays one row out by weight, accounting for inter-key spacing.
private struct KeyRow: View {
    let row: [KeySpec]
    let spacing: CGFloat
    let highlightEsc: Bool

    var body: some View {
        GeometryReader { geo in
            let totalWeight = row.reduce(0) { $0 + $1.weight }
            let available = geo.size.width - spacing * CGFloat(row.count - 1)
            HStack(spacing: spacing) {
                ForEach(Array(row.enumerated()), id: \.offset) { _, spec in
                    KeyView(spec: spec, highlight: highlightEsc && spec.label == "esc")
                        .frame(width: max(0, available * spec.weight / totalWeight))
                }
            }
        }
    }
}

private struct KeyView: View {
    let spec: KeySpec
    let highlight: Bool

    var body: some View {
        if spec.label == "ARROWS" {
            ArrowCluster()
        } else if spec.label.isEmpty {
            Color.clear // spacebar gap
        } else {
            Text(spec.label)
                .font(.system(size: 8.5, weight: highlight ? .bold : .medium))
                .tracking(0.2)
                .foregroundColor(highlight ? .white : Theme.keyLabel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(highlight ? AnyShapeStyle(Theme.keyHighlight) : AnyShapeStyle(Theme.key))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(highlight ? Theme.accentDark : Color(hex: 0x0C0C0D), lineWidth: 0.5)
                )
                .shadow(color: highlight ? Theme.accent.opacity(0.67) : .clear, radius: 6)
        }
    }
}

/// Inverted-T arrow cluster: full-height ◄ ►, half-height ▲▼ stacked between.
private struct ArrowCluster: View {
    var body: some View {
        HStack(spacing: 4) {
            arrowKey("\u{25C4}")
            VStack(spacing: 2) {
                arrowKey("\u{25B2}")
                arrowKey("\u{25BC}")
            }
            arrowKey("\u{25BA}")
        }
    }

    private func arrowKey(_ glyph: String) -> some View {
        Text(glyph)
            .font(.system(size: 7))
            .foregroundColor(Theme.keyLabel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.key)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color(hex: 0x0C0C0D), lineWidth: 0.5)
            )
    }
}
