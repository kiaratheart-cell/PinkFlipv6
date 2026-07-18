//
//  ClockView.swift
//  PinkFlip
//
//  Composes four flip cards (H H : M M) and a colon into the full
//  PinkFlip clock face, and owns the TimeProvider that drives updates.
//  Sizing is fully responsive: `layout()` recomputes card dimensions
//  from the view's own bounds every time it changes, so the clock
//  scales cleanly to any monitor size and stays crisp on Retina
//  displays (each FlipDigitView re-rasterizes at the current backing
//  scale factor whenever its size changes).
//

import Cocoa

final class ClockView: NSView {

    // MARK: Subviews

    private let hourTens = FlipDigitView(glyph: "0")
    private let hourOnes = FlipDigitView(glyph: "0")
    private let minuteTens = FlipDigitView(glyph: "0")
    private let minuteOnes = FlipDigitView(glyph: "0")
    private let colonLabel = CATextLayer()

    private let timeProvider = TimeProvider()

    /// Target aspect ratio (width : height) for each individual flip
    /// card — tall and narrow, matching the airy outline cards in the
    /// reference design.
    private let cardAspect: CGFloat = 0.6

    /// Spacing between the two cards within a pair (H-H or M-M),
    /// expressed as a fraction of card width. Kept tight, like a
    /// single connected pair.
    private let pairSpacingFraction: CGFloat = 0.05

    /// Spacing given to the colon gap between the hour and minute
    /// pairs, as a fraction of card width.
    private let colonWidthFraction: CGFloat = 0.5

    // MARK: Init

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        ensureLayerBacked()
        layer!.backgroundColor = NSColor.clear.cgColor

        for digitView in [hourTens, hourOnes, minuteTens, minuteOnes] {
            addSubview(digitView)
        }

        colonLabel.string = ":"
        colonLabel.alignmentMode = .center
        colonLabel.foregroundColor = PinkFlipPalette.accent.cgColor
        colonLabel.contentsScale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        layer!.addSublayer(colonLabel)

        timeProvider.onTimeChanged = { [weak self] time in
            self?.apply(time: time, animated: true)
        }
    }

    // MARK: Lifecycle

    func start() {
        timeProvider.start()
    }

    func stop() {
        timeProvider.stop()
    }

    // MARK: Time application

    private var hasAppliedInitialTime = false

    private func apply(time: ClockTime, animated: Bool) {
        // The very first application (when the screensaver launches)
        // should snap directly to the correct time without playing a
        // flip animation, since there is no meaningful "previous" value
        // to flip from.
        let shouldAnimate = animated && hasAppliedInitialTime

        hourTens.setGlyph(Character(String(time.hourTens)), animated: shouldAnimate)
        hourOnes.setGlyph(Character(String(time.hourOnes)), animated: shouldAnimate)
        minuteTens.setGlyph(Character(String(time.minuteTens)), animated: shouldAnimate)
        minuteOnes.setGlyph(Character(String(time.minuteOnes)), animated: shouldAnimate)

        hasAppliedInitialTime = true
    }

    // MARK: Layout

    override func layout() {
        super.layout()
        guard bounds.width > 0, bounds.height > 0 else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Solve for the largest card size that fits the available
        // width, accounting for four cards, a colon gap, and the two
        // tight within-pair gaps, while also respecting the available
        // height (card height = card width / cardAspect).
        let totalWidthUnits: CGFloat = 4 + colonWidthFraction + 2 * pairSpacingFraction

        let widthConstrainedCardWidth = bounds.width * 0.88 / totalWidthUnits
        let heightConstrainedCardWidth = (bounds.height * 0.78) * cardAspect

        let cardWidth = max(20, min(widthConstrainedCardWidth, heightConstrainedCardWidth))
        let cardHeight = cardWidth / cardAspect
        let pairSpacing = cardWidth * pairSpacingFraction
        let colonWidth = cardWidth * colonWidthFraction

        let totalWidth = cardWidth * 4 + colonWidth + pairSpacing * 2
        let originX = bounds.midX - totalWidth / 2
        let centerY = bounds.midY

        var x = originX

        hourTens.frame = CGRect(x: x, y: centerY - cardHeight / 2, width: cardWidth, height: cardHeight)
        x += cardWidth + pairSpacing

        hourOnes.frame = CGRect(x: x, y: centerY - cardHeight / 2, width: cardWidth, height: cardHeight)
        x += cardWidth

        let colonRect = CGRect(x: x, y: centerY - cardHeight / 2, width: colonWidth, height: cardHeight)
        colonLabel.frame = colonRect
        colonLabel.fontSize = cardHeight * 0.46
        colonLabel.font = NSFont.monospacedDigitSystemFont(ofSize: colonLabel.fontSize, weight: .regular)
        colonLabel.foregroundColor = PinkFlipPalette.accent.cgColor
        colonLabel.contentsScale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        x += colonWidth

        minuteTens.frame = CGRect(x: x, y: centerY - cardHeight / 2, width: cardWidth, height: cardHeight)
        x += cardWidth + pairSpacing

        minuteOnes.frame = CGRect(x: x, y: centerY - cardHeight / 2, width: cardWidth, height: cardHeight)
        x += cardWidth

        CATransaction.commit()
    }

    /// The natural (unclamped) size the clock would like to occupy,
    /// useful for the host view when computing burn-in drift bounds.
    var intrinsicClockSize: CGSize {
        return bounds.size
    }
}
