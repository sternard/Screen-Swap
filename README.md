# Screen Swap

Screen Swap is a no-window macOS utility for the Mac Assistant menu. Launching it moves each visible app window to the next connected display, preserving its relative position on that display. With two displays this swaps windows between screens; with three or more it rotates windows left-to-right and wraps the rightmost display back to the first.

Screen Swap uses macOS Accessibility APIs to move other apps' windows. On first launch, macOS may ask for Accessibility permission. Enable Screen Swap in System Settings > Privacy & Security > Accessibility, then run it again.

During development, macOS may ask again after the executable changes. If System Settings already shows ScreenSwap as enabled but the prompt still appears, remove the old ScreenSwap entry from Accessibility, run Screen Swap once, and enable the newly prompted app. The launcher preserves the local app bundle between runs so normal menu clicks reuse the same Accessibility identity.

Before moving windows, Screen Swap attempts to leave app-level full-screen mode for any visible full-screen windows. It does not restore those windows to full-screen afterward.

## Run

```sh
./scripts/run-app.sh
```

## Test

```sh
swift test
```
