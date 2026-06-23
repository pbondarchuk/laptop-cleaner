# Specification: MacBook Keyboard and Touchpad Cleaning Utility

## 1. Overview

The application is a small native macOS utility that allows the user to temporarily lock either the keyboard or the touchpad so the MacBook surface can be cleaned safely without triggering unwanted input.

The application should provide a simple visual interface showing the lower part of a MacBook, including the keyboard and touchpad areas. The user can click either area to activate the corresponding cleaning mode.

## 2. Application Goals

The main goals of the application are:

1. Allow the user to temporarily lock keyboard input while keeping the touchpad available.
2. Allow the user to temporarily lock touchpad input while keeping the keyboard available.
3. Provide a very simple and clear visual interface.
4. Make activation and deactivation of cleaning modes easy and predictable.
5. Prevent accidental typing, clicking, scrolling, or gestures while cleaning the selected area.

## 3. Target Platform

The application should be developed as a native macOS application.

Recommended technology stack:

- Language: Swift
- UI Framework: SwiftUI or AppKit
- Target OS: macOS
- Distribution: Direct download or Mac App Store, depending on implementation constraints

## 4. Main User Interface

The application should open as a small window centered on the screen.

The main window should display a simple visual representation of the lower part of a MacBook:

- Keyboard area
- Touchpad area

The visual representation does not need to be highly detailed. It can be a simplified image or custom-drawn layout.

Each area should behave as an interactive button:

- Clicking the keyboard area activates Keyboard Cleaning Mode.
- Clicking the touchpad area activates Touchpad Cleaning Mode.

## 5. Keyboard Cleaning Mode

### 5.1 Activation

The user activates this mode by clicking the keyboard area in the application window.

### 5.2 Behavior

When Keyboard Cleaning Mode is active:

- Keyboard input should be blocked or ignored.
- Touchpad input should remain available.
- The application should display a clear overlay message:

```text
Keyboard is locked.
Press the button on the touchpad to unlock.
```

The screen should also show a visible unlock button that can be clicked using the touchpad.

### 5.3 Deactivation

The user exits Keyboard Cleaning Mode by clicking the unlock button using the touchpad.

After unlocking:

- Keyboard input should return to normal.
- The application should return to its main screen.

## 6. Touchpad Cleaning Mode

### 6.1 Activation

The user activates this mode by clicking the touchpad area in the application window.

### 6.2 Behavior

When Touchpad Cleaning Mode is active:

- Touchpad input should be blocked or ignored.
- Keyboard input should remain available.
- The application should display a clear overlay message:

```text
Touchpad is locked.
Press Escape to unlock.
```

### 6.3 Deactivation

The user exits Touchpad Cleaning Mode by pressing the `Escape` key.

After unlocking:

- Touchpad input should return to normal.
- The application should return to its main screen.

## 7. Functional Requirements

### FR-001: Main Window

The application shall display a main window with a visual representation of the MacBook keyboard and touchpad.

### FR-002: Keyboard Area Selection

The application shall allow the user to click the keyboard area to activate Keyboard Cleaning Mode.

### FR-003: Touchpad Area Selection

The application shall allow the user to click the touchpad area to activate Touchpad Cleaning Mode.

### FR-004: Keyboard Lock Mode

The application shall suppress or ignore keyboard input while Keyboard Cleaning Mode is active.

### FR-005: Touchpad Lock Mode

The application shall suppress or ignore touchpad input while Touchpad Cleaning Mode is active.

### FR-006: Keyboard Unlock

The application shall provide an on-screen unlock button when the keyboard is locked.

### FR-007: Touchpad Unlock

The application shall allow the user to unlock the touchpad by pressing the `Escape` key.

### FR-008: Status Message

The application shall clearly display the current cleaning mode and unlock instruction.

### FR-009: Safe Exit

The application shall always provide a reliable way to exit the active cleaning mode.

## 8. Non-Functional Requirements

### NFR-001: Simplicity

The application should have a minimal interface with no unnecessary settings.

### NFR-002: Reliability

The application should not leave the keyboard or touchpad in a locked state after closing, crashing, or exiting.

### NFR-003: Native User Experience

The application should look and behave like a native macOS utility.

### NFR-004: Performance

The application should start quickly and use minimal system resources.

### NFR-005: Accessibility

Text instructions should be clearly readable, with sufficient contrast and large enough font size.

## 9. Safety and Recovery Requirements

The application must include recovery behavior to avoid locking the user out.

Recommended safeguards:

1. Keyboard Cleaning Mode must be unlockable using the touchpad.
2. Touchpad Cleaning Mode must be unlockable using the keyboard.
3. Pressing and holding `Escape` for several seconds may optionally force-unlock any active mode.
4. The application should automatically unlock all input when the app is closed.
5. The application should not activate both lock modes at the same time.

## 10. Permissions and macOS Considerations

The application may require macOS Accessibility or Input Monitoring permissions to intercept or suppress keyboard and touchpad events.

On first launch, the application should explain why these permissions are required and guide the user to enable them in macOS System Settings.

Example message:

```text
This application needs permission to temporarily block keyboard or touchpad input while cleaning your MacBook.
You can enable this in System Settings > Privacy & Security > Accessibility.
```

## 11. Basic User Flow

### Flow 1: Lock Keyboard

1. User opens the application.
2. User clicks the keyboard area.
3. Application enters Keyboard Cleaning Mode.
4. Keyboard input is blocked.
5. User cleans the keyboard.
6. User clicks the on-screen unlock button using the touchpad.
7. Application returns to the main screen.

### Flow 2: Lock Touchpad

1. User opens the application.
2. User clicks the touchpad area.
3. Application enters Touchpad Cleaning Mode.
4. Touchpad input is blocked.
5. User cleans the touchpad.
6. User presses `Escape`.
7. Application returns to the main screen.

## 12. Suggested Window States

The application should support three main states:

```text
Idle
KeyboardLocked
TouchpadLocked
```

### Idle

Default state. The user can select either keyboard or touchpad cleaning mode.

### KeyboardLocked

Keyboard input is blocked. Touchpad remains active for unlocking.

### TouchpadLocked

Touchpad input is blocked. Keyboard remains active for unlocking.

## 13. Optional Features

The first version can be very simple, but future versions may include:

- Menu bar icon for quick access.
- Countdown timer before lock activation.
- Automatic unlock after a configurable timeout.
- Full-screen cleaning mode.
- Different MacBook layout images.
- Sound or visual confirmation when a mode is activated or unlocked.
- Support for external keyboards and trackpads.

## 14. MVP Scope

The MVP should include only the following:

1. Native macOS app window.
2. Simple MacBook keyboard/touchpad visual.
3. Keyboard Cleaning Mode.
4. Touchpad Cleaning Mode.
5. Clear unlock instructions.
6. Reliable recovery/unlock behavior.
7. Required macOS permission handling.

The MVP should avoid advanced configuration, themes, timers, or external device support unless they are easy to implement.
