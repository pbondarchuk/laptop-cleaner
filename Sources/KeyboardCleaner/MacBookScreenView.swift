import SwiftUI

/// The MacBook display (lid): a dark bezel around a lit "wallpaper", drawn
/// above the deck so the whole graphic reads as a laptop. Clicking it while
/// idle enters screen-cleaning mode (the real display blacks out).
struct MacBookScreenView: View {
    let mode: AppState.Mode
    let onCleanScreen: () -> Void

    @State private var hovering = false
    private var idle: Bool { mode == .idle }

    private let size = CGSize(width: 540, height: 250)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x2A2A2C), Color(hex: 0x121214)],
                                     startPoint: .top, endPoint: .bottom))

            Wallpaper()
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .padding(EdgeInsets(top: 15, leading: 13, bottom: 13, trailing: 13))

            // Camera dot in the top bezel.
            Circle()
                .fill(Color(hex: 0x0B0B0C))
                .frame(width: 5, height: 5)
                .overlay(Circle().fill(Color(hex: 0x2C3340)).frame(width: 2, height: 2))
                .offset(y: -size.height / 2 + 7.5)
        }
        .frame(width: size.width, height: size.height)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.black.opacity(0.35), lineWidth: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.accent, lineWidth: (idle && hovering) ? 2 : 0)
                .animation(.easeInOut(duration: 0.15), value: hovering)
        )
        .shadow(color: .black.opacity(0.28), radius: 22, x: 0, y: 14)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onHover { inside in
            guard idle else { return }
            hovering = inside
            if inside { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
        }
        .onTapGesture { if idle { onCleanScreen() } }
    }
}

/// A pseudo desktop — wallpaper gradient, faint menu bar, a row of dock icons —
/// so the screen clearly reads as "on / lit".
private struct Wallpaper: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x3E6BD6), Color(hex: 0x7C5CCB), Color(hex: 0xC471A8)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            VStack(spacing: 0) {
                // Menu bar
                HStack(spacing: 7) {
                    Circle().fill(.white.opacity(0.85)).frame(width: 6, height: 6)
                    Capsule().fill(.white.opacity(0.6)).frame(width: 22, height: 4)
                    Capsule().fill(.white.opacity(0.45)).frame(width: 16, height: 4)
                    Spacer()
                    Capsule().fill(.white.opacity(0.55)).frame(width: 28, height: 4)
                }
                .padding(.horizontal, 9)
                .frame(height: 17)
                .background(.white.opacity(0.16))

                Spacer()

                // Dock
                HStack(spacing: 7) {
                    ForEach(0..<6, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(.white.opacity(0.55 - Double(i) * 0.03))
                            .frame(width: 20, height: 20)
                    }
                }
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.18))
                )
                .padding(.bottom, 9)
            }
        }
    }
}
