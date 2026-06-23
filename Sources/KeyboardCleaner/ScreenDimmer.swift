import AppKit

/// Blacks out every display so the screen can be wiped. A dim "Press any key
/// to restore the screen" hint is centered on each. Any key press or mouse
/// click restores — this is the safe exit, and it means input isn't blocked.
///
/// No Accessibility permission is needed: these are just shielding-level
/// windows painted black, not an event tap.
final class ScreenDimmer {
    private var windows: [NSWindow] = []
    private var monitors: [Any] = []
    private var onDismiss: (() -> Void)?

    var isActive: Bool { !windows.isEmpty }

    func present(onDismiss: @escaping () -> Void) {
        guard windows.isEmpty else { return }
        self.onDismiss = onDismiss

        for screen in NSScreen.screens {
            let window = DimWindow(contentRect: screen.frame, styleMask: .borderless,
                                   backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.backgroundColor = .black
            window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.setFrame(screen.frame, display: true)
            window.contentView = hintView(size: screen.frame.size)
            windows.append(window)
        }

        for window in windows { window.orderFrontRegardless() }
        windows.first?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        let mask: NSEvent.EventTypeMask = [.keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown]
        // Local monitor consumes the event; global covers the (unlikely) case
        // that key focus is elsewhere.
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] _ in
            self?.trigger(); return nil
        }) { monitors.append(local) }
        if let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] _ in
            self?.trigger()
        }) { monitors.append(global) }
    }

    /// Tear down without firing the dismiss callback (used by external teardown).
    func dismiss() {
        teardown()
    }

    /// An input event restored the screen — tear down, then notify once.
    private func trigger() {
        guard onDismiss != nil else { return }
        let callback = onDismiss
        teardown()
        callback?()
    }

    private func teardown() {
        for monitor in monitors { NSEvent.removeMonitor(monitor) }
        monitors.removeAll()
        for window in windows { window.orderOut(nil); window.close() }
        windows.removeAll()
        onDismiss = nil
    }

    private func hintView(size: CGSize) -> NSView {
        let container = NSView(frame: CGRect(origin: .zero, size: size))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.black.cgColor

        let label = NSTextField(labelWithString: "Press any key to restore the screen")
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = NSColor(white: 0.30, alpha: 1) // dim so the screen stays dark for cleaning
        label.alignment = .center
        label.sizeToFit()
        label.frame.origin = CGPoint(x: (size.width - label.frame.width) / 2,
                                     y: (size.height - label.frame.height) / 2)
        label.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        container.addSubview(label)
        return container
    }
}

/// Borderless windows don't accept key input by default; allow it so the
/// local event monitor reliably catches the restoring keypress.
private final class DimWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
