import SwiftUI

struct MainScreen: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 18) {
            Banner(mode: state.mode)
            VStack(spacing: 0) {
                MacBookScreenView(mode: state.mode, onCleanScreen: state.cleanScreen)
                Hinge()
                MacBookDeckView(
                    mode: state.mode,
                    onLockKeyboard: state.lockKeyboard,
                    onLockTrackpad: state.lockTrackpad,
                    onUnlockKeyboard: state.unlock
                )
            }
            hint
                .frame(minHeight: 20)
        }
        .padding(EdgeInsets(top: 24, leading: 26, bottom: 26, trailing: 26))
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var hint: some View {
        switch state.mode {
        case .trackpad:
            HStack(spacing: 8) {
                KeyCap("esc")
                Text("to unlock the touchpad")
                    .font(.system(size: 12.5))
                    .foregroundColor(Theme.textTertiary)
            }
        case .idle:
            Text("Click the screen, keyboard, or trackpad to clean it · Esc unlocks")
                .font(.system(size: 12))
                .foregroundColor(Theme.textQuaternary)
        case .keyboard, .screen:
            EmptyView()
        }
    }
}

/// Thin silver hinge connecting the lid to the deck.
private struct Hinge: View {
    var body: some View {
        LinearGradient(colors: [Color(hex: 0xC4C8CE), Color(hex: 0x9CA0A8)],
                       startPoint: .top, endPoint: .bottom)
            .frame(width: 556, height: 8)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Banner

private struct Banner: View {
    let mode: AppState.Mode

    var body: some View {
        let copy = Self.copy(for: mode)
        let locked = mode != .idle
        VStack(spacing: 5) {
            HStack(spacing: 8) {
                if locked { PulsingDot() }
                Text(copy.title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(copy.color)
            }
            Text(copy.subtitle)
                .font(.system(size: 13.5))
                .foregroundColor(Theme.textTertiary)
        }
        .frame(minHeight: 56)
        .multilineTextAlignment(.center)
    }

    private static func copy(for mode: AppState.Mode) -> (title: String, subtitle: String, color: Color) {
        switch mode {
        case .idle:
            return ("Clean your MacBook", "Click an area below to lock it while you wipe it down.", Theme.textPrimary)
        case .keyboard:
            return ("Keyboard is locked", "Press the button on the touchpad to unlock.", Theme.accent)
        case .trackpad:
            return ("Touchpad is locked", "Press Escape to unlock.", Theme.accent)
        case .screen:
            return ("Screen is off", "Press any key to restore the screen.", Theme.accent)
        }
    }
}

/// Accent dot with an expanding "ping" ring.
private struct PulsingDot: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.accent, lineWidth: 2)
                .frame(width: 9, height: 9)
                .scaleEffect(animate ? 1.8 : 0.6)
                .opacity(animate ? 0 : 0.8)
            Circle()
                .fill(Theme.accent)
                .frame(width: 9, height: 9)
        }
        .frame(width: 15, height: 15)
        .onAppear {
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}

// MARK: - Keycap (hint)

struct KeyCap: View {
    let label: String
    init(_ label: String) { self.label = label }

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                LinearGradient(colors: [.white, Color(hex: 0xECEEF1)],
                               startPoint: .top, endPoint: .bottom)
            )
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(.black.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.18), radius: 0, x: 0, y: 1.5)
    }
}
