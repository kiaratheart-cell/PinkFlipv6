//
//  FlipDigitView.swift
//  PinkFlip
//
//  A single split-flap "flip card" showing one glyph (a digit, or ":").
//  Visually and mechanically modeled on a physical split-flap display:
//  the card is split into a top half and a bottom half, and changing
//  the glyph plays a two-phase animation:
//
//    Phase 1: the top half's flap folds away (0deg -> -90deg) around
//             the horizontal center hinge, revealing the new glyph's
//             top half underneath.
//    Phase 2: the bottom half's flap unfolds (-90deg -> 0deg) around
//             the same hinge, sweeping down to reveal the new glyph's
//             bottom half.
//
//  All rendering of glyph pixels is delegated to DigitCardRenderer,
//  which rasterizes a full card face once per glyph change; the four
//  CALayers here simply display slices of those rasterized images via
//  `contentsRect`, which is extremely cheap to composite and animate.
//

import Cocoa
import QuartzCore

final class FlipDigitView: NSView {

    // MARK: Configuration

    /// The glyph currently displayed (after any in-flight animation
    /// settles). Setting this directly (outside of `setGlyph`) has no
    /// visual effect; use `setGlyph(_:animated:)` instead.
    private(set) var currentGlyph: Character

    private let cornerRadiusFraction: CGFloat
    private var cornerRadius: CGFloat { max(4, bounds.width * cornerRadiusFraction) }

    // MARK: Layers

    private let containerLayer = CALayer()
    private let topBackLayer = CALayer()
    private let bottomBackLayer = CALayer()
    private let topFlapLayer = CALayer()
    private let bottomFlapLayer = CALayer()
    private let topShadeLayer = CALayer()
    private let bottomShadeLayer = CALayer()

    private var isAnimating = false
    private var pendingGlyph: Character?

    // MARK: Init

    init(glyph: Character, cornerRadiusFraction: CGFloat = 0.16) {
        self.currentGlyph = glyph
        self.cornerRadiusFraction = cornerRadiusFraction
        super.init(frame: .zero)
        setUpLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Layer setup

    private func setUpLayers() {
        ensureLayerBacked()
        layer!.addSublayer(containerLayer)
        containerLayer.masksToBounds = false

        // Drop shadow for the whole card, drawn on the container so it
        // is not clipped by the half-layer masks. Kept extremely soft
        // and faint to match the flat, airy outline design.
        containerLayer.shadowColor = PinkFlipPalette.cardDropShadow.cgColor
        containerLayer.shadowOpacity = 1.0
        containerLayer.shadowRadius = 14
        containerLayer.shadowOffset = CGSize(width: 0, height: -2)

        for (layer, corners) in [
            (topBackLayer, topCorners),
            (bottomBackLayer, bottomCorners),
            (topFlapLayer, topCorners),
            (bottomFlapLayer, bottomCorners)
        ] {
            layer.masksToBounds = true
            layer.contentsGravity = .resize
            containerLayer.addSublayer(layer)
            _ = corners // corners applied once bounds are known, in layout
        }

        topShadeLayer.backgroundColor = PinkFlipPalette.flapShading.cgColor
        topShadeLayer.opacity = 0
        topFlapLayer.addSublayer(topShadeLayer)

        bottomShadeLayer.backgroundColor = PinkFlipPalette.flapShading.cgColor
        bottomShadeLayer.opacity = 0
        bottomFlapLayer.addSublayer(bottomShadeLayer)

        // Subtle highlight hairline along the very top edge of the card.
        let highlight = CALayer()
        highlight.backgroundColor = PinkFlipPalette.cardHighlight.cgColor
        highlight.name = "highlight"
        topFlapLayer.addSublayer(highlight)
    }

    private var topCorners: CACornerMask { [.layerMinXMaxYCorner, .layerMaxXMaxYCorner] }
    private var bottomCorners: CACornerMask { [.layerMinXMinYCorner, .layerMaxXMinYCorner] }

    // MARK: Layout

    override func layout() {
        super.layout()
        guard bounds.width > 0, bounds.height > 0 else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        containerLayer.frame = bounds
        containerLayer.sublayerTransform = CATransform3DMakePerspective(FlipAnimation.perspective)
        containerLayer.shadowPath = CGPath(roundedRect: bounds, cornerWidth: cornerRadius,
                                            cornerHeight: cornerRadius, transform: nil)

        let halfHeight = bounds.height / 2.0
        let fullRect = CGRect(origin: .zero, size: bounds.size)
        let hingePoint = CGPoint(x: bounds.midX, y: bounds.midY)

        topBackLayer.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: halfHeight)
        topBackLayer.position = CGPoint(x: bounds.midX, y: bounds.height - halfHeight / 2)
        topBackLayer.roundCorners(topCorners, radius: cornerRadius)
        topBackLayer.contentsRect = CGRect(x: 0, y: 0.5, width: 1, height: 0.5)

        bottomBackLayer.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: halfHeight)
        bottomBackLayer.position = CGPoint(x: bounds.midX, y: halfHeight / 2)
        bottomBackLayer.roundCorners(bottomCorners, radius: cornerRadius)
        bottomBackLayer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 0.5)

        topFlapLayer.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: halfHeight)
        topFlapLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
        topFlapLayer.position = hingePoint
        topFlapLayer.roundCorners(topCorners, radius: cornerRadius)
        topFlapLayer.contentsRect = CGRect(x: 0, y: 0.5, width: 1, height: 0.5)

        bottomFlapLayer.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: halfHeight)
        bottomFlapLayer.anchorPoint = CGPoint(x: 0.5, y: 1)
        bottomFlapLayer.position = hingePoint
        bottomFlapLayer.roundCorners(bottomCorners, radius: cornerRadius)
        bottomFlapLayer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 0.5)

        topShadeLayer.frame = topFlapLayer.bounds
        bottomShadeLayer.frame = bottomFlapLayer.bounds

        if let highlight = topFlapLayer.sublayers?.first(where: { $0.name == "highlight" }) {
            let lineHeight = max(1.0, bounds.height * 0.006)
            highlight.frame = CGRect(x: 0, y: topFlapLayer.bounds.height - lineHeight,
                                      width: topFlapLayer.bounds.width, height: lineHeight)
        }

        _ = fullRect

        CATransaction.commit()

        renderCurrentGlyph()
    }

    // MARK: Rendering

    private var lastRenderedSize: CGSize = .zero

    private func renderCurrentGlyph() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        // Avoid redundant re-rasterization if size hasn't changed and we
        // are not mid-flip (mid-flip images are managed by flip logic).
        if bounds.size == lastRenderedSize && !isAnimating { return }
        lastRenderedSize = bounds.size

        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        let image = DigitCardRenderer.renderCard(glyph: currentGlyph,
                                                   size: bounds.size,
                                                   scale: scale,
                                                   cornerRadius: cornerRadius)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        topBackLayer.contents = image
        bottomBackLayer.contents = image
        topFlapLayer.contents = image
        bottomFlapLayer.contents = image
        CATransaction.commit()
    }

    // MARK: Public API

    /// Updates the displayed glyph, optionally animating a flip.
    func setGlyph(_ glyph: Character, animated: Bool) {
        guard glyph != currentGlyph else { return }

        guard animated, bounds.width > 0, bounds.height > 0 else {
            currentGlyph = glyph
            lastRenderedSize = .zero
            renderCurrentGlyph()
            return
        }

        if isAnimating {
            // A new value arrived before the current flip finished; queue
            // it and let the completion handler pick it up. In normal
            // once-a-minute operation this should not happen, but it
            // keeps rapid successive updates (e.g. screensaver restart)
            // robust and glitch-free.
            pendingGlyph = glyph
            return
        }

        performFlip(to: glyph)
    }

    private func performFlip(to newGlyph: Character) {
        guard bounds.width > 0, bounds.height > 0 else {
            currentGlyph = newGlyph
            return
        }

        isAnimating = true

        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        let newImage = DigitCardRenderer.renderCard(glyph: newGlyph,
                                                      size: bounds.size,
                                                      scale: scale,
                                                      cornerRadius: cornerRadius)

        // Pre-load the new top half underneath the top flap.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        topBackLayer.contents = newImage
        CATransaction.commit()

        // Phase 1: top flap folds away, from flat (0) to edge-on (-90).
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.beginPhaseTwo(newGlyph: newGlyph, newImage: newImage)
        }

        let rotation = FlipAnimation.rotationAnimation(fromDegrees: 0, toDegrees: -90)
        topFlapLayer.transform = CATransform3DRotate(CATransform3DIdentity, -90 * .pi / 180, 1, 0, 0)
        topFlapLayer.add(rotation, forKey: "flipPhase1")

        let shade = FlipAnimation.shadingAnimation(peakOpacity: 0.30, risingFirst: true)
        topShadeLayer.add(shade, forKey: "shadePhase1")

        CATransaction.commit()
    }

    private func beginPhaseTwo(newGlyph: Character, newImage: CGImage) {
        // Snap the (now invisible, edge-on) top flap back flat with the
        // new glyph already in place. Because it is edge-on this change
        // is imperceptible.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        topFlapLayer.transform = CATransform3DIdentity
        topFlapLayer.contents = newImage
        topShadeLayer.opacity = 0

        // Snap the bottom flap to its hidden, edge-on starting position
        // with the new glyph loaded. The (still old-valued) bottomBack
        // layer remains visible underneath during this instant, so
        // nothing appears to change on screen yet.
        bottomFlapLayer.transform = CATransform3DRotate(CATransform3DIdentity, -90 * .pi / 180, 1, 0, 0)
        bottomFlapLayer.contents = newImage
        CATransaction.commit()

        // Phase 2: bottom flap unfolds from edge-on (-90) down to flat
        // (0), sweeping the new glyph into view.
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.finishFlip(newGlyph: newGlyph, newImage: newImage)
        }

        let rotation = FlipAnimation.rotationAnimation(fromDegrees: -90, toDegrees: 0)
        bottomFlapLayer.transform = CATransform3DIdentity
        bottomFlapLayer.add(rotation, forKey: "flipPhase2")

        let shade = FlipAnimation.shadingAnimation(peakOpacity: 0.30, risingFirst: false)
        bottomShadeLayer.add(shade, forKey: "shadePhase2")

        CATransaction.commit()
    }

    private func finishFlip(newGlyph: Character, newImage: CGImage) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        bottomBackLayer.contents = newImage
        bottomShadeLayer.opacity = 0
        CATransaction.commit()

        currentGlyph = newGlyph
        lastRenderedSize = bounds.size
        isAnimating = false

        if let pending = pendingGlyph {
            pendingGlyph = nil
            if pending != currentGlyph {
                performFlip(to: pending)
            }
        }
    }
}

// MARK: - Perspective helper

func CATransform3DMakePerspective(_ m34: CGFloat) -> CATransform3D {
    var transform = CATransform3DIdentity
    transform.m34 = m34
    return transform
}
