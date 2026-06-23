import IOKit
import IOKit.hidsystem

/// Reads and overrides the hardware Caps Lock lock state (and its green LED).
///
/// Caps Lock is toggled by the keyboard driver in the kernel HID layer, before
/// any `CGEventTap` — even a HID tap — observes the event. Suppressing the
/// event keeps apps from seeing the modifier, but the lock state and LED still
/// flip. Forcing the state back via IOKit's `IOHIDSystem` is the only way to
/// hold it.
///
/// While the keyboard is locked we keep a single connection open
/// (`beginSession`/`endSession`) so each correction is as fast as possible,
/// minimizing the visible LED flicker.
enum CapsLock {
    // Raw values from <IOKit/hidsystem/IOHIDLib.h> / IOHIDParameter.h, used
    // directly to avoid relying on Swift importing the C constants.
    private static let paramConnectType: UInt32 = 1   // kIOHIDParamConnectType
    private static let capsLockSelector: Int32 = 1    // kIOHIDCapsLockState

    private static var sessionConnection: io_connect_t = 0

    /// Open and cache a connection for the duration of a keyboard lock.
    static func beginSession() {
        guard sessionConnection == 0 else { return }
        sessionConnection = openConnection()
    }

    /// Release the cached connection when the lock ends.
    static func endSession() {
        if sessionConnection != 0 {
            IOServiceClose(sessionConnection)
            sessionConnection = 0
        }
    }

    /// Current Caps Lock lock state.
    static var state: Bool {
        let handle = sessionConnection != 0 ? sessionConnection : openConnection()
        guard handle != 0 else { return false }
        defer { if handle != sessionConnection { IOServiceClose(handle) } }
        var on = false
        IOHIDGetModifierLockState(handle, capsLockSelector, &on)
        return on
    }

    /// Force the Caps Lock lock state (and LED) to `on`.
    static func set(_ on: Bool) {
        let handle = sessionConnection != 0 ? sessionConnection : openConnection()
        guard handle != 0 else { return }
        defer { if handle != sessionConnection { IOServiceClose(handle) } }
        IOHIDSetModifierLockState(handle, capsLockSelector, on)
    }

    private static func openConnection() -> io_connect_t {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
        guard service != 0 else { return 0 }
        defer { IOObjectRelease(service) }
        var handle: io_connect_t = 0
        guard IOServiceOpen(service, mach_task_self_, paramConnectType, &handle) == KERN_SUCCESS else { return 0 }
        return handle
    }
}
