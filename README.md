# PinkFlip

A native macOS split-flap clock screensaver, built entirely with
Swift and `ScreenSaver.framework`. PinkFlip is an original design
inspired by the *look and feel* of classic flip clocks — it shares no
code, assets, or branding with any existing product.

- Large, centered 12‑hour flip clock (`09:45 PM`)
- Soft blush background (`#FFC5D6`) with vivid pink flip cards
  (`#FE5A9D`) and crisp white text (`#FFFFFF`)
- Smooth, restrained two-phase split-flap animation (~0.35s) built on
  Core Animation — no video, no images, no web technology
- Updates once per minute; no seconds, no date
- Fully responsive layout, sharp on Retina displays
- Slow, near-invisible pixel drift every few minutes to protect
  against display burn-in
- No configuration window, no menus, no logos — just the clock

---

## Requirements

- macOS Tahoe (26) or later to install and run the screensaver
- Xcode 26 (or any recent Xcode with a macOS 13+ SDK) to build it
- Swift 5

## Project layout

```
PinkFlip/
├── PinkFlip.xcodeproj/          Xcode project
└── PinkFlip/                    Target sources
    ├── Info.plist
    ├── Assets.xcassets/         Color assets (background, card, text)
    └── Sources/
        ├── PinkFlipView.swift       Main ScreenSaverView subclass (entry point)
        ├── ClockView.swift          Lays out and drives the six flip cards
        ├── FlipDigitView.swift      A single split-flap card + flip animation
        ├── FlipAnimation.swift      Core Animation timing/easing helpers
        ├── DigitCardRenderer.swift  Rasterizes card faces (glyph + styling)
        ├── TimeProvider.swift       Minute-boundary clock observer
        ├── BurnInGuard.swift        Slow periodic drift for burn-in protection
        ├── Colors.swift             Central color palette
        └── Extensions.swift         Small shared utilities
```

## How to open the project

1. Double-click `PinkFlip.xcodeproj`, or open it from Xcode via
   **File → Open…**.
2. Xcode will resolve the single `PinkFlip` target automatically —
   there are no external dependencies or packages to fetch.

## How to build

1. In Xcode, select the **PinkFlip** scheme (already selected by
   default) and the **My Mac** destination.
2. Choose **Product → Build** (`⌘B`), or **Product → Archive** for a
   release build.
3. The build product is `PinkFlip.saver`, a `.saver` bundle.

To build from the command line instead:

```bash
cd PinkFlip
xcodebuild -project PinkFlip.xcodeproj -scheme PinkFlip -configuration Release build
```

The built bundle will be under your DerivedData products directory,
e.g. `~/Library/Developer/Xcode/DerivedData/PinkFlip-*/Build/Products/Release/PinkFlip.saver`.

## How to install

1. Locate `PinkFlip.saver` (see above).
2. Double-click it. macOS will ask whether to install the screensaver
   for **just you** or **all users of this Mac** — choose either.
3. This opens **System Settings → Screen Saver** with PinkFlip already
   selected. Pick it to activate it.
4. There is no configuration screen — PinkFlip has no adjustable
   settings by design.

You can also install it manually by copying the bundle into either:

- `~/Library/Screen Savers/` (current user only), or
- `/Library/Screen Savers/` (all users, requires admin)

Then select **PinkFlip** from **System Settings → Screen Saver**.

## Troubleshooting

**Xcode shows "No such module" or a signing error.**
Open the target's **Signing & Capabilities** tab and select your own
team (or "Sign to Run Locally"). The project builds ad-hoc signed
(`CODE_SIGN_IDENTITY = "-"`) by default, which is sufficient to run
locally but Xcode may still prompt you to pick a team the first time.

**macOS says the screensaver "can't be opened because it is from an
unidentified developer."**
Right-click (or Control-click) `PinkFlip.saver` and choose **Open**,
or run `xattr -dr com.apple.quarantine PinkFlip.saver` in Terminal
before double-clicking it. This is standard for any unsigned or
ad-hoc–signed screensaver you build yourself.

**The clock doesn't appear, or System Settings shows a blank
preview.**
Quit **System Settings**, remove any previously installed copy of
`PinkFlip.saver` from `~/Library/Screen Savers/` or
`/Library/Screen Savers/`, rebuild, and reinstall. macOS aggressively
caches screensaver bundles by path and bundle identifier, so stale
copies are the most common cause of a blank preview after a rebuild.

**I changed the code but the installed screensaver didn't update.**
Screen Saver previews are hosted by a system process
(`legacyScreenSaver` / `ScreenSaverEngine`) that caches loaded
bundles. After reinstalling a rebuilt `PinkFlip.saver`, log out and
back in (or restart) if System Settings continues to show the old
behavior.

**Performance / CPU usage.**
PinkFlip does no per-frame drawing. It updates only once a minute
(driven by `TimeProvider`) and briefly during the ~0.35s flip
animations, plus one tiny layout pass every few minutes for burn-in
drift. CPU usage while idle between updates should be effectively
zero.

## Design notes

- Every glyph face (each digit 0–9 plus the colon) is rendered once
  per size/scale change into a `CGImage` by `DigitCardRenderer`, then
  sliced into top/bottom halves via `CALayer.contentsRect`. This keeps
  the animation cheap: Core Animation is just compositing and
  transforming pre-rendered images, not re-drawing text every frame.
- The flip itself is a physically-inspired two-phase animation: the
  top flap folds away (0° → −90°) around a shared horizontal hinge to
  reveal the new value, then the bottom flap unfolds (−90° → 0°) to
  sweep the new value into place — mirroring how a real split-flap
  display works, without needing any bitmap or video assets.
- `BurnInGuard` nudges the clock a few points in a random direction
  every five minutes, animated slowly over several seconds, so the
  motion is essentially imperceptible while still protecting
  burn-in–prone displays over long idle periods.
