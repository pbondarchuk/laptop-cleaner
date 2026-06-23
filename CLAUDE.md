# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A native macOS utility (Swift + SwiftUI, SwiftPM executable, macOS 13+) that
temporarily locks the keyboard **or** trackpad — or blacks out the screen — so
the MacBook can be wiped down without triggering input. The original spec is in
`specs/macbook_keyboard_touchpad_cleaning_utility_spec.md`; the visual design
came from a Claude Design prototype and is mirrored in `Theme.swift` and the
view files.

## Commands

```sh
swift build                 # compile (debug) — fast feedback while editing
swift run                   # run the bare binary (Accessibility re-prompts each rebuild)
./build_app.sh              # build release + assemble & sign Keyboard Cleaner.app  ← use this to test for real
./package.sh                # build_app.sh + produce a distributable Keyboard Cleaner.dmg
swift Tools/make_icon.swift <out.iconset>   # regenerate icon PNGs from the design
```

There are **no tests** and no lint config. To exercise input-blocking behavior
you must run the real `.app` and grant it Accessibility — `swift run` is only
useful for checking that the UI renders.

If an Accessibility grant gets stuck (stale System Settings entry), reset it:

```sh
tccutil reset Accessibility com.example.keyboardcleaner
```

## Architecture

Three layers; the input layer is where the real complexity lives.

**State machine** — `AppState` (`App.swift`) is the single source of truth:
`Screen` (permission | main) and `Mode` (idle | keyboard | trackpad | screen).
All mode changes go through `setMode`, which tears down the previous mode and
sets up the new one, enforcing that only one is ever active. `keyboard`/
`trackpad` drive `InputBlocker`; `screen` drives `ScreenDimmer` instead (no
Accessibility needed). If starting the blocker fails (lost Accessibility), it
bounces back to the permission screen. `Permissions` (also `App.swift`) gates on
`AXIsProcessTrusted()`; the permission screen polls it via a timer.

**Input blocking** — `InputBlocker.swift` installs a `CGEventTap`. The subtle
parts, each a hard-won macOS gotcha (do not "simplify" these away):
- Tap is at **`.cghidEventTap`** (HID level), not session level, so Caps Lock
  and media/function keys are intercepted before the system acts on them.
- Keyboard mode suppresses keyDown/keyUp/flagsChanged **plus system-defined
  events (raw type 14)** — F-keys default to media actions (volume, play/pause →
  launches Music) that don't arrive as normal key events.
- Trackpad mode suppresses mouse/scroll events **and** calls
  `CGAssociateMouseAndMouseCursorPosition(0)` — suppressing `mouseMoved` alone
  does *not* stop the WindowServer from sliding the cursor.
- Caps Lock's LED/lock state is toggled in the kernel before any tap sees it, so
  it's forced back via IOKit (`CapsLock.swift`, `IOHIDSystem`) on each
  `flagsChanged`; a connection is held open for the lock to minimize LED flicker.
- Safety exits: trackpad unlocks on Escape (passed through, not suppressed);
  keyboard unlocks via the on-screen button (clicked with the still-live
  trackpad) or a ~1.5s Escape hold. The tap is kernel-owned, so input is
  restored automatically if the process dies; `stop()` and
  `applicationWillTerminate` also tear it down explicitly.

**UI** — `ContentView` switches between the permission screen and `MainScreen`.
`MainScreen` stacks `MacBookScreenView` (the lid — clicking it enters screen
mode) + a hinge + `MacBookDeckView` (the clickable keyboard well + trackpad with
lock scrims) so the whole graphic reads as a laptop. `KeyboardView` draws the
weighted key grid (`KEY_ROWS`-style layout via `GeometryReader`, plus the
inverted-T arrow cluster). Screen mode is **not** an in-window scrim: it's
`ScreenDimmer.swift`, which paints shielding-level black `NSWindow`s over every
display with a dim "press any key" hint; any key/click restores (a local +
global `NSEvent` monitor), so input isn't tapped. `Theme.swift` holds all
colors/gradients lifted from the prototype. The app draws **no** window chrome —
it uses the real macOS title bar.

## Code signing (important)

`build_app.sh` signs with a **stable self-signed cert** (`Keyboard Cleaner Dev`,
auto-created in the login keychain). This is deliberate: macOS keys the
Accessibility grant to the code signature's designated requirement
(`identifier + certificate leaf`), which stays constant across rebuilds. **Never
revert to ad-hoc signing** (`codesign --sign -`) — its hash changes every build,
dropping the grant and leaving stuck System Settings entries. The app is not
notarized (personal distribution only); recipients approve it once via "Open
Anyway". Bundle id is `com.example.keyboardcleaner`; the binary is arm64-only.
