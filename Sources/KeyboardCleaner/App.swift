import SwiftUI
import ApplicationServices

@main
struct KeyboardCleanerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState()

    var body: some Scene {
        Window("Keyboard Cleaner", id: "main") {
            ContentView()
                .environmentObject(state)
                .onAppear { appDelegate.state = state }
        }
        .windowResizability(.contentSize)
        .commandsRemoved()
    }
}

// MARK: - App lifecycle

final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var state: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = icon
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // Belt-and-suspenders: never leave input locked on exit (NFR-002).
    func applicationWillTerminate(_ notification: Notification) {
        InputBlocker.shared.stop()
    }
}

// MARK: - State

/// Window states: Idle plus the three cleaning locks (keyboard, trackpad, screen).
@MainActor
final class AppState: ObservableObject {
    enum Screen { case permission, main }
    enum Mode { case idle, keyboard, trackpad, screen }

    @Published var screen: Screen
    @Published var mode: Mode = .idle

    private let dimmer = ScreenDimmer()
    private var permissionPoll: Timer?

    init() {
        screen = Permissions.isTrusted ? .main : .permission
        InputBlocker.shared.onForceUnlock = { [weak self] in self?.unlock() }
        if screen == .permission { startPermissionPolling() }
    }

    // MARK: Mode transitions (only one area locked at a time — safeguard #5)

    func lockKeyboard() { setMode(.keyboard) }
    func lockTrackpad() { setMode(.trackpad) }
    func cleanScreen() { setMode(.screen) }
    func unlock() { setMode(.idle) }

    private func setMode(_ newMode: Mode) {
        guard newMode != mode else { return }

        // Tear down whatever is currently active.
        switch mode {
        case .keyboard, .trackpad: InputBlocker.shared.stop()
        case .screen: dimmer.dismiss()
        case .idle: break
        }

        switch newMode {
        case .idle:
            mode = .idle

        case .screen:
            // Just an overlay — no Accessibility needed, any input restores it.
            dimmer.present { [weak self] in self?.unlock() }
            mode = .screen

        case .keyboard, .trackpad:
            let lock: InputBlocker.LockMode = newMode == .keyboard ? .keyboard : .trackpad
            if InputBlocker.shared.start(mode: lock) {
                mode = newMode
            } else {
                // Lost Accessibility access — bounce back to the permission screen.
                mode = .idle
                screen = .permission
                startPermissionPolling()
            }
        }
    }

    // MARK: Permission gating

    func openSystemSettings() {
        Permissions.requestAndOpenSettings()
    }

    func continueFromPermission() {
        guard Permissions.isTrusted else { return }
        stopPermissionPolling()
        screen = .main
    }

    private func startPermissionPolling() {
        stopPermissionPolling()
        permissionPoll = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.objectWillChange.send() }
        }
    }

    private func stopPermissionPolling() {
        permissionPoll?.invalidate()
        permissionPoll = nil
    }
}

// MARK: - Accessibility permission

enum Permissions {
    /// Suppressing events with a `CGEventTap` requires Accessibility access.
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Prompt the user (adds the app to the Accessibility list) and open the
    /// relevant System Settings pane so they can flip the switch.
    static func requestAndOpenSettings() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
