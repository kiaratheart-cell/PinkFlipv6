//
//  Colors.swift
//  PinkFlip
//
//  Central definition of the PinkFlip color palette. This is the
//  "outline" restyle: a soft peach-to-pink gradient backdrop with
//  airy, translucent flip cards whose outlines and digits are drawn in
//  a single vivid pink/magenta accent, rather than solid filled cards
//  with white digits.
//

import Cocoa

enum PinkFlipPalette {

    // MARK: Background gradient
    // A soft diagonal gradient reminiscent of a peach/pink sunset wash.
    static let backgroundGradientStops: [(NSColor, CGFloat)] = [
        (NSColor(hex: "F877B4"), 0.0),
        (NSColor(hex: "FFC3DC"), 0.35),
        (NSColor(hex: "FFEFE4"), 0.62),
        (NSColor(hex: "FF9BCB"), 1.0)
    ]
    static let backgroundGradientStart = CGPoint(x: 0.0, y: 1.0) // top-left
    static let backgroundGradientEnd = CGPoint(x: 1.0, y: 0.0)   // bottom-right

    /// Flat fallback background (used only if gradient rendering is
    /// unavailable for some reason).
    static let background = NSColor(hex: "FFCBDD")

    /// The single vivid accent used for card outlines, digits, the
    /// colon, and the hinge seam — the entire look is built from one
    /// pink/magenta tone at varying opacity rather than multiple hues.
    static let accent = NSColor(hex: "FF3D96")

    /// Very light, translucent fill for each card face, so the
    /// background gradient reads faintly through the cards.
    static let cardFill = NSColor(hex: "FFFFFF").withAlphaComponent(0.16)

    /// Card outline stroke.
    static let cardOutline = accent.withAlphaComponent(0.9)

    /// Digit / glyph color.
    static let text = accent

    /// Hairline seam drawn at the center hinge of each flip card.
    static let seam = accent.withAlphaComponent(0.85)

    /// Small hinge "nub" tabs drawn at the seam, echoing a physical
    /// split-flap mechanism.
    static let hinge = accent.withAlphaComponent(0.95)

    /// Extremely soft drop shadow — kept minimal since the design is
    /// flat and airy rather than heavily dimensional.
    static let cardDropShadow = accent.withAlphaComponent(0.10)

    /// Subtle highlight, barely-there, along the top edge of each card.
    static let cardHighlight = NSColor.white.withAlphaComponent(0.10)

    /// Subtle shading overlay used while a flap is rotating, to simulate
    /// changing light as the card turns in 3D space.
    static let flapShading = accent.withAlphaComponent(0.18)
}
