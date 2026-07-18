//
//  PinkFlipView.swift
//  PinkFlip
//
//  The screensaver's principal class (see NSPrincipalClass in
//  Info.plist). Hosts the background color, centers the ClockView, and
//  applies slow burn-in-protection drift. Intentionally has no
//  configuration UI: hasConfigureSheet is false and configureSheet is
//  nil, per the design brief (no menus, no settings window).
//

import Cocoa
import ScreenSaver

@objc(PinkFlipView)
final class PinkFlipView: ScreenSaverView {

    private let clockView = ClockView(frame: .zero)
    private let burnInGuard = BurnInGuard()
    private var currentDriftOffset: CGPoint = .zero

    // MARK: Init

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        // A full minute passes between meaningful visual updates, so we
        // do not need ScreenSaverView's per-frame animateOneFrame timer
        // running at a fast interval. We still set a modest interval as
        // a safe fallback / heartbeat; the real updates are driven by
        // TimeProvider's minute-boundary callback for accuracy and
        // efficiency.
        animationTimeInterval = 1.0 / 30.0

        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        addSubview(clockView)

        burnInGuard.onOffsetChanged = { [weak self] offset, duration in
            self?.animateToOffset(offset, duration: duration)
        }
    }

    // MARK: NSView

    override var isOpaque: Bool { true }

    override func layout() {
        super.layout()
        positionClock(animated: false)
    }

    private func positionClock(animated: Bool, duration: TimeInterval = 0) {
        let clockSize = idealClockSize()
        let center = CGPoint(x: bounds.midX + currentDriftOffset.x,
                              y: bounds.midY + currentDriftOffset.y)
        let targetFrame = CGRect(x: center.x - clockSize.width / 2,
                                  y: center.y - clockSize.height / 2,
                                  width: clockSize.width,
                                  height: clockSize.height)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = duration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                clockView.animator().frame = targetFrame
            }
        } else {
            clockView.frame = targetFrame
        }
    }

    /// The clock area simply fills most of the screensaver's bounds;
    /// ClockView itself works out exact card sizing responsively inside
    /// whatever frame it is given.
    private func idealClockSize() -> CGSize {
        let inset: CGFloat = min(bounds.width, bounds.height) * 0.06
        return CGSize(width: bounds.width - inset * 2, height: bounds.height - inset * 2)
    }

    private func animateToOffset(_ offset: CGPoint, duration: TimeInterval) {
        currentDriftOffset = offset
        positionClock(animated: true, duration: duration)
    }

    // MARK: ScreenSaverView lifecycle

    override func startAnimation() {
        super.startAnimation()
        clockView.start()
        burnInGuard.start()
    }

    override func stopAnimation() {
        super.stopAnimation()
        clockView.stop()
        burnInGuard.stop()
    }

    override func animateOneFrame() {
        // Intentionally empty. All visual updates are event-driven
        // (minute-boundary ticks from TimeProvider and the periodic
        // burn-in drift), not per-frame, which keeps CPU usage minimal.
    }

    override func draw(_ rect: NSRect) {
        guard let gradient = NSGradient(
            colorsAndLocations:
                (PinkFlipPalette.backgroundGradientStops[0].0, PinkFlipPalette.backgroundGradientStops[0].1),
                (PinkFlipPalette.backgroundGradientStops[1].0, PinkFlipPalette.backgroundGradientStops[1].1),
                (PinkFlipPalette.backgroundGradientStops[2].0, PinkFlipPalette.backgroundGradientStops[2].1),
                (PinkFlipPalette.backgroundGradientStops[3].0, PinkFlipPalette.backgroundGradientStops[3].1)
        ) else {
            PinkFlipPalette.background.setFill()
            rect.fill()
            return
        }

        // Diagonal wash from the bottom-left corner to the top-right
        // corner, matching the soft peach-to-pink sweep in the design.
        let angle: CGFloat = {
            let dx = bounds.width
            let dy = bounds.height
            return atan2(dy, dx) * 180.0 / .pi
        }()
        gradient.draw(in: bounds, angle: angle)
    }

    // MARK: Configuration (intentionally none)

    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }
}
