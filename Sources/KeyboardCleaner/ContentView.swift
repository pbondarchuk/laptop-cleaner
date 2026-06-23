import SwiftUI

private let fixedWidth: CGFloat = 660

struct ContentView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        Group {
            switch state.screen {
            case .permission: PermissionScreen()
            case .main: MainScreen()
            }
        }
        .frame(width: fixedWidth)
        .background(Theme.windowBackground)
    }
}

// MARK: - Permission screen

private struct PermissionScreen: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        let trusted = Permissions.isTrusted
        VStack(spacing: 16) {
            AppIconView(size: 64)

            VStack(spacing: 10) {
                Text("Allow input access")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(attributedExplanation)
                    .font(.system(size: 13.5))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 420)
            }

            // Faux System Settings row mirroring the real toggle the user
            // needs to flip; the indicator reflects live permission state.
            HStack(spacing: 11) {
                AppIconView(size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Keyboard Cleaner")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Accessibility · Input Monitoring")
                        .font(.system(size: 11.5))
                        .foregroundColor(Theme.textMuted)
                }
                Spacer()
                StatusToggle(on: trusted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: 420)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.black.opacity(0.12), lineWidth: 0.5)
            )

            HStack(spacing: 10) {
                PillButton("Open System Settings", style: .secondary) {
                    state.openSystemSettings()
                }
                PillButton("Continue", style: .primary, disabled: !trusted) {
                    state.continueFromPermission()
                }
            }
            .padding(.top, 6)

            Text(trusted ? "Access granted — you’re all set."
                         : "Turn on the switch above to continue.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textQuaternary)
        }
        .padding(EdgeInsets(top: 24, leading: 26, bottom: 26, trailing: 26))
        .frame(maxWidth: .infinity)
    }

    private var attributedExplanation: AttributedString {
        var s = AttributedString("Keyboard Cleaner needs permission to temporarily block keyboard or touchpad input while you clean your MacBook. Enable it in ")
        var bold = AttributedString("System Settings › Privacy & Security › Accessibility")
        bold.font = .system(size: 13.5, weight: .semibold)
        bold.foregroundColor = Color(hex: 0x3C3C43)
        s += bold
        s += AttributedString(".")
        return s
    }
}

/// Read-only macOS-style switch reflecting whether access is granted.
private struct StatusToggle: View {
    let on: Bool
    var body: some View {
        ZStack(alignment: on ? .trailing : .leading) {
            Capsule()
                .fill(on ? Color(hex: 0x34C759) : Color(hex: 0xE3E3E8))
            Circle()
                .fill(.white)
                .padding(2)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
        .frame(width: 42, height: 25)
        .animation(.easeInOut(duration: 0.2), value: on)
    }
}

// MARK: - Buttons

enum PillStyle { case primary, secondary }

struct PillButton: View {
    let title: String
    let style: PillStyle
    var disabled: Bool = false
    let action: () -> Void

    @State private var hovering = false

    init(_ title: String, style: PillStyle, disabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundColor(style == .primary ? .white : Theme.textPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.black.opacity(style == .secondary ? 0.18 : 0), lineWidth: 0.5)
                )
                .opacity(style == .secondary && disabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { hovering = $0 }
    }

    private var background: Color {
        switch style {
        case .primary:
            return disabled ? Color(hex: 0xB6D4FF) : (hovering ? Theme.accentDark : Theme.accent)
        case .secondary:
            return .white
        }
    }
}
