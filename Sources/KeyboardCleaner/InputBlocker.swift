import AppKit
import CoreGraphics

/// Suppresses keyboard or trackpad/mouse input system-wide using a
/// `CGEventTap`. Only one device is ever blocked at a time.
///
/// Safety: the tap is a kernel-attached mach port owned by this process,
/// so it is automatically torn down if the app quits or crashes — input
/// can never stay locked after the process dies (NFR-002). We additionally
/// stop it explicitly on unlock and on termination.
final class InputBlocker {
    enum LockMode { case idle, keyboard, trackpad }

    static let shared = InputBlocker()

    /// Called (on the main queue) when the tap decides the active mode
    /// should be released — Escape in trackpad mode, or a sustained
    /// Escape hold in keyboard mode (the spec's force-unlock safeguard).
    var onForceUnlock: (() -> Void)?

    /// How long Escape must be held to force-unlock keyboard mode.
    private let holdToUnlock: TimeInterval = 1.5
    private let escapeKeyCode: Int64 = 53

    private(set) var mode: LockMode = .idle
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var escapeHeld = false
    private var cursorFrozen = false
    private var lockedCapsState = false

    /// Begin blocking the given device. Returns `false` if the event tap
    /// could not be created (almost always missing Accessibility access).
    @discardableResult
    func start(mode: LockMode) -> Bool {
        stop()
        guard mode != .idle else { return true }

        let mask = Self.eventMask(for: mode)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        // HID-level tap: intercepts events before the system acts on them, so
        // Caps Lock and the media/function keys (volume, play/pause, brightness…)
        // are actually suppressed rather than handled before we see them.
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: Self.tapCallback,
            userInfo: refcon
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        self.mode = mode

        // Suppressing mouse events stops apps from *seeing* movement, but the
        // WindowServer still slides the cursor from the raw HID layer. Detach
        // the cursor from the mouse so the pointer physically stops moving
        // while the trackpad is wiped.
        if mode == .trackpad {
            CGAssociateMouseAndMouseCursorPosition(0)
            cursorFrozen = true
        }
        if mode == .keyboard {
            // Hold one IOKit connection open and remember Caps Lock so we can
            // pin it there (as fast as possible) if the key is pressed.
            CapsLock.beginSession()
            lockedCapsState = CapsLock.state
        }
        return true
    }

    /// Stop blocking and restore normal input.
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if cursorFrozen {
            CGAssociateMouseAndMouseCursorPosition(1)
            cursorFrozen = false
        }
        CapsLock.endSession()
        eventTap = nil
        runLoopSource = nil
        escapeHeld = false
        mode = .idle
    }

    // MARK: - Event handling

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // The system disables a tap if it ever times out or is interrupted
        // by an OS-level input grab. Re-enable so the lock keeps holding.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        switch mode {
        case .keyboard:
            trackEscapeHold(type: type, event: event)
            // The kernel already toggled Caps Lock before we saw the event;
            // force it back so the lock state and LED don't change.
            if type == .flagsChanged {
                CapsLock.set(lockedCapsState)
            }
            return nil // swallow every keyboard event

        case .trackpad:
            if type == .keyDown {
                if event.getIntegerValueField(.keyboardEventKeycode) == escapeKeyCode {
                    DispatchQueue.main.async { [weak self] in self?.onForceUnlock?() }
                    return nil // consume Escape so it doesn't reach other apps
                }
                return Unmanaged.passUnretained(event) // keyboard stays usable
            }
            return nil // swallow every mouse / trackpad event

        case .idle:
            return Unmanaged.passUnretained(event)
        }
    }

    /// In keyboard mode the on-screen button (clicked with the touchpad) is
    /// the normal exit; holding Escape is the always-available safety exit.
    private func trackEscapeHold(type: CGEventType, event: CGEvent) {
        guard event.getIntegerValueField(.keyboardEventKeycode) == escapeKeyCode else { return }
        if type == .keyUp {
            escapeHeld = false
        } else if type == .keyDown {
            let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            guard !isRepeat else { return }
            escapeHeld = true
            DispatchQueue.main.asyncAfter(deadline: .now() + holdToUnlock) { [weak self] in
                guard let self, self.escapeHeld, self.mode == .keyboard else { return }
                self.onForceUnlock?()
            }
        }
    }

    // MARK: - Static helpers

    /// NSEvent.EventType.systemDefined — media/function keys (volume,
    /// play/pause, brightness…) arrive as these, not as keyDown. CGEventType
    /// has no named case, so reference it by raw value.
    private static let systemDefinedMask: CGEventMask = CGEventMask(1) << 14

    private static func eventMask(for mode: LockMode) -> CGEventMask {
        func bit(_ t: CGEventType) -> CGEventMask { CGEventMask(1) << CGEventMask(t.rawValue) }
        switch mode {
        case .keyboard:
            return bit(.keyDown) | bit(.keyUp) | bit(.flagsChanged) | systemDefinedMask
        case .trackpad:
            return bit(.mouseMoved)
                | bit(.leftMouseDown) | bit(.leftMouseUp) | bit(.leftMouseDragged)
                | bit(.rightMouseDown) | bit(.rightMouseUp) | bit(.rightMouseDragged)
                | bit(.otherMouseDown) | bit(.otherMouseUp) | bit(.otherMouseDragged)
                | bit(.scrollWheel)
                | bit(.keyDown) // watch (but pass) keys so Escape can unlock
        case .idle:
            return 0
        }
    }

    private static let tapCallback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon else { return Unmanaged.passUnretained(event) }
        let blocker = Unmanaged<InputBlocker>.fromOpaque(refcon).takeUnretainedValue()
        return blocker.handle(type: type, event: event)
    }
}
