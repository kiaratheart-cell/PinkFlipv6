//
//  DigitCardRenderer.swift
//  PinkFlip
//
//  Renders a full flip-card face — an airy, translucent rounded-rect
//  outline with a centered glyph in a single vivid pink accent, plus a
//  hairline center seam with small hinge "nub" tabs — into a CGImage.
//  FlipDigitView slices the resulting image in half via
//  CALayer.contentsRect, which is far cheaper than maintaining separate
//  live text layers for every flap and back layer.
//

import Cocoa

enum DigitCardRenderer {

    /// Renders a single flip card face for the given glyph.
    ///
    /// - Parameters:
    ///   - glyph: the character to draw, e.g. "0"..."9" or ":".
    ///   - size: the size of the full card, in points.
    ///   - scale: the backing scale factor (2.0/3.0 on Retina displays).
    ///   - cornerRadius: corner radius applied to all four corners of the
    ///     full card (each half layer masks its own visible corners).
    /// - Returns: a CGImage sized `size * scale`, ready to be assigned to
    ///   a CALayer's `contents`.
    static func renderCard(glyph: Character,
                            size: CGSize,
                            scale: CGFloat,
                            cornerRadius: CGFloat) -> CGImage {
        let pixelWidth = max(1, Int((size.width * scale).rounded()))
        let pixelHeight = max(1, Int((size.height * scale).rounded()))

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil,
                                 width: pixelWidth,
                                 height: pixelHeight,
                                 bitsPerComponent: 8,
                                 bytesPerRow: 0,
                                 space: colorSpace,
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

        context.scaleBy(x: scale, y: scale)

        let bounds = CGRect(origin: .zero, size: size)
        let strokeWidth = max(1.5, size.width * 0.022)
        let insetBounds = bounds.insetBy(dx: strokeWidth / 2, dy: strokeWidth / 2)
        let path = CGPath(roundedRect: insetBounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

        // Very light translucent fill so the gradient backdrop shows
        // faintly through each card.
        context.addPath(path)
        context.setFillColor(PinkFlipPalette.cardFill.cgColor)
        context.fillPath()

        // A very light top-to-bottom highlight, barely visible, for a
        // touch of glassy depth without looking heavy or dimensional.
        context.saveGState()
        context.addPath(path)
        context.clip()
        if let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                NSColor.white.withAlphaComponent(0.10).cgColor,
                NSColor.white.withAlphaComponent(0.0).cgColor
            ] as CFArray,
            locations: [0.0, 0.4]
        ) {
            context.drawLinearGradient(gradient,
                                        start: CGPoint(x: bounds.midX, y: bounds.maxY),
                                        end: CGPoint(x: bounds.midX, y: bounds.minY),
                                        options: [])
        }
        context.restoreGState()

        // Card outline stroke — this is the primary graphic element of
        // the design, so it is drawn crisp and fully opaque.
        context.addPath(path)
        context.setStrokeColor(PinkFlipPalette.cardOutline.cgColor)
        context.setLineWidth(strokeWidth)
        context.strokePath()

        // Center hinge seam: a hairline across the vertical middle of
        // the card, mimicking the physical split of a flip card.
        let seamHeight: CGFloat = max(1.0, size.height * 0.01)
        let seamInset = size.width * 0.06
        let seamRect = CGRect(x: seamInset, y: bounds.midY - seamHeight / 2,
                               width: size.width - seamInset * 2, height: seamHeight)
        context.setFillColor(PinkFlipPalette.seam.cgColor)
        context.fill(seamRect)

        // Small hinge "nub" tabs straddling the seam near the left and
        // right edges, echoing the little mechanical clips on a real
        // split-flap display.
        let nubWidth = size.width * 0.05
        let nubHeight = size.height * 0.028
        let nubInset = size.width * 0.09
        for nubX in [nubInset, size.width - nubInset - nubWidth] {
            let nubRect = CGRect(x: nubX, y: bounds.midY - nubHeight / 2, width: nubWidth, height: nubHeight)
            let nubPath = CGPath(roundedRect: nubRect, cornerWidth: nubHeight * 0.4, cornerHeight: nubHeight * 0.4, transform: nil)
            context.addPath(nubPath)
            context.setFillColor(PinkFlipPalette.hinge.cgColor)
            context.fillPath()
        }

        // Glyph. Uses the system's built-in monospaced-digit numeral
        // style, at a light weight to match the thin, airy line work
        // of the rest of the card, so consecutive digits never shift
        // horizontally.
        let fontSize = size.height * 0.62
        let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .regular)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: PinkFlipPalette.text,
            .paragraphStyle: paragraph
        ]

        let string = String(glyph)
        let attributed = NSAttributedString(string: string, attributes: attributes)
        let textSize = attributed.size()

        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        let previous = NSGraphicsContext.current
        NSGraphicsContext.current = nsContext

        // Optically center: system fonts sit slightly above true visual
        // center, so nudge down a touch for perfect balance inside the
        // card, matching the restrained, precise look of a quality flip
        // clock face.
        let drawRect = CGRect(
            x: bounds.midX - textSize.width / 2,
            y: bounds.midY - textSize.height / 2 - size.height * 0.02,
            width: textSize.width,
            height: textSize.height
        )
        attributed.draw(in: drawRect)

        NSGraphicsContext.current = previous

        return context.makeImage()!
    }
}
