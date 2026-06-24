# Keyboard Cleaner

A tiny native macOS utility that temporarily locks your keyboard **or**
touchpad — or blacks out the screen — so you can wipe down your MacBook
without triggering input.

Implemented in Swift + SwiftUI from
[`specs/macbook_keyboard_touchpad_cleaning_utility_spec.md`](specs/macbook_keyboard_touchpad_cleaning_utility_spec.md),
matching the Claude Design prototype (native macOS look, system blue accent).

## What it does

The window shows a simplified MacBook — screen, keyboard, and trackpad. Hover
a zone to see a blue selection ring; click it to clean that area.

- **Idle** — click the screen, keyboard, or trackpad to start cleaning it.
- **Keyboard locked** — every keystroke is suppressed (including Caps Lock and
  the media/function keys); the trackpad still works and an **Unlock Keyboard**
  button appears *on the trackpad*.
- **Touchpad locked** — all pointer/scroll/gesture input is suppressed and the
  cursor is frozen in place; the keyboard still works and the on-screen **esc**
  key glows. Press **Escape** to unlock.
- **Screen off** — clicking the screen blacks out every display with a dim
  "Press any key to restore the screen" hint, so you can wipe the glass and
  spot smudges. Any key press or click restores it.

Only one area is ever active at a time. Keyboard/trackpad input is blocked with
a `CGEventTap`, which the kernel tears down automatically if the app quits or
crashes — so input can never stay stuck locked. Screen-off is just a black
overlay window, so any input always brings the display back.

### Safety exits
- **Touchpad mode:** press **Escape**.
- **Keyboard mode:** click **Unlock Keyboard** with the touchpad, or **hold
  Escape ~1.5 s** to force-unlock.
- **Screen off:** press any key or click.
- Quitting or closing the window always restores input and the display.

## Permissions

Locking the **keyboard or trackpad** requires **Accessibility** access. On first
launch the app shows an onboarding screen explaining this and links straight to
**System Settings › Privacy & Security › Accessibility**. Flip the switch for
*Keyboard Cleaner*, then click **Continue**. (Screen-off needs no permission —
it's just an overlay — but the onboarding still gates the main window.)

## Build & run

A real `.app` bundle is needed so macOS remembers the Accessibility grant:

```sh
./build_app.sh
open "Keyboard Cleaner.app"
```

For quick iteration you can also `swift build && swift run`, but Accessibility
may re-prompt on each rebuild of the bare binary.

Requires macOS 13+ and the Swift toolchain (Xcode or Command Line Tools).

### Signing

`build_app.sh` signs with a stable, self-signed certificate (`Keyboard Cleaner
Dev`) that it auto-creates in the login keychain on first run. This is
deliberate: macOS keys the Accessibility grant to the code signature, and an
ad-hoc signature changes every rebuild — which would drop the grant and leave
stale, un-toggleable entries in System Settings. The stable cert means you
grant access once and it survives every rebuild.

If a grant ever gets stuck, reset it and re-grant:

```sh
tccutil reset Accessibility com.example.keyboardcleaner
```

## Distributing to friends & family

Run the packaging script to produce a shareable disk image:

```sh
./package.sh        # rebuilds, signs, and creates "Keyboard Cleaner.dmg"
```

Send the resulting `Keyboard Cleaner.dmg` (email, AirDrop, iCloud/Dropbox).
Recipients open it, drag the app onto **Applications**, and follow the bundled
`Read Me First.txt`:

1. **First launch** — macOS blocks it ("can't verify the developer"). Open
   **System Settings › Privacy & Security**, scroll to the Keyboard Cleaner
   message, and click **Open Anyway**, then confirm. One time only.
2. **Accessibility** — the app's first screen guides them to enable it; this is
   what lets the app block input. Granted once per machine.

Caveats:

- **Apple Silicon only.** The binary is built for arm64; it won't run on Intel
  Macs. (Build a universal binary with
  `swift build -c release --arch arm64 --arch x86_64` if you ever need Intel.)
- **The "Open Anyway" step is unavoidable** because the app isn't *notarized*.
  Zero-friction launches require a paid Apple Developer ID and notarization
  (`xcrun notarytool` + `stapler`) — overkill for personal sharing.
- The Accessibility grant is per-machine and can't be pre-set or transferred.
