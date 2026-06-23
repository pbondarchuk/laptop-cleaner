import SwiftUI

/// The simplified lower deck of a MacBook: a black keyboard well above a
/// silver trackpad, set in a silver chassis. Each zone is an interactive
/// button while idle; locking a zone overlays a lock scrim.
struct MacBookDeckView: View {
    let mode: AppState.Mode
    let onLockKeyboard: () -> Void
    let onLockTrackpad: () -> Void
    let onUnlockKeyboard: () -> Void

    @State private var hoverKeyboard = false
    @State private var hoverTrackpad = false

    private var idle: Bool { mode == .idle }
    private var keyboardLocked: Bool { mode == .keyboard }
    private var trackpadLocked: Bool { mode == .trackpad }

    var body: some View {
        VStack(spacing: 15) {
            keyboardWell
            trackpad
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 24, trailing: 20))
        .frame(width: 540)
        .background(Theme.deck)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.black.opacity(0.18), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.28), radius: 25, x: 0, y: 18)
    }

    // MARK: Keyboard well

    private var keyboardWell: some View {
        KeyboardView(highlightEsc: trackpadLocked)
            .padding(11)
            .frame(height: 196)
            .frame(maxWidth: .infinity)
            .background(Theme.keyboardWell)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                if keyboardLocked { LockScrim() }
            }
            .overlay(selectionRing(visible: idle && hoverKeyboard, radius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Theme.accent, lineWidth: keyboardLocked ? 2 : 0)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .onHover { inside in
                guard idle else { return }
                hoverKeyboard = inside
                setPointerCursor(inside)
            }
            .onTapGesture { if idle { onLockKeyboard() } }
    }

    // MARK: Trackpad

    private var trackpad: some View {
        ZStack {
            if keyboardLocked {
                Button(action: onUnlockKeyboard) {
                    Text("Unlock Keyboard")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(Theme.accent))
                        .shadow(color: Theme.accent.opacity(0.4), radius: 7, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 234, height: 144)
        .background(Theme.trackpad)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            if trackpadLocked { LockScrim() }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.black.opacity(0.16), lineWidth: 0.5)
        )
        .overlay(selectionRing(visible: idle && hoverTrackpad, radius: 12))
        .shadow(color: .black.opacity(0.12), radius: 1, x: 0, y: 1)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onHover { inside in
            guard idle else { return }
            hoverTrackpad = inside
            setPointerCursor(inside)
        }
        .onTapGesture { if idle { onLockTrackpad() } }
    }

    private func setPointerCursor(_ inside: Bool) {
        if inside { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
    }

    private func selectionRing(visible: Bool, radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(Theme.accent, lineWidth: visible ? 2 : 0)
            .animation(.easeInOut(duration: 0.15), value: visible)
    }
}

/// Translucent dark scrim with a padlock, shown over a locked zone.
private struct LockScrim: View {
    var body: some View {
        ZStack {
            Color(hex: 0x0A0C10, opacity: 0.46)
            Image(systemName: "lock.fill")
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

