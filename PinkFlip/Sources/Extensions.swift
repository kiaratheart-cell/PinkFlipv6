//
//  Extensions.swift
//  PinkFlip
//
//  Utility extensions shared across the PinkFlip screensaver target.
//

import Cocoa
import QuartzCore

// MARK: - NSColor + Hex

extension NSColor {

    /// Creates a color from a 6-digit hex string such as "FE5A9D" or "#FE5A9D".
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let red   = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue  = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(deviceRed: red, green: green, blue: blue, alpha: alpha)
    }
}

// MARK: - CGFloat helpers

extension CGFloat {
    /// Returns a random value between `-magnitude` and `+magnitude`.
    static func randomJitter(magnitude: CGFloat) -> CGFloat {
        return CGFloat.random(in: -magnitude...magnitude)
    }

    /// Linear interpolation.
    func lerp(to end: CGFloat, t: CGFloat) -> CGFloat {
        return self + (end - self) * t
    }
}

// MARK: - CALayer rounded corners

extension CALayer {

    /// Rounds a specific subset of corners of the layer using a mask layer.
    /// - Parameters:
    ///   - corners: which corners to round.
    ///   - radius: corner radius in points.
    func roundCorners(_ corners: CACornerMask, radius: CGFloat) {
        if #available(macOS 10.13, *) {
            self.cornerRadius = radius
            self.maskedCorners = corners
        } else {
            // Fallback for older systems: build an explicit mask path.
            let path = CGMutablePath()
            let rect = bounds
            let topLeftRadius = corners.contains(.layerMinXMinYCorner) ? radius : 0
            let topRightRadius = corners.contains(.layerMaxXMinYCorner) ? radius : 0
            let bottomLeftRadius = corners.contains(.layerMinXMaxYCorner) ? radius : 0
            let bottomRightRadius = corners.contains(.layerMaxXMaxYCorner) ? radius : 0

            path.move(to: CGPoint(x: rect.minX, y: rect.minY + bottomLeftRadius))
            path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY),
                        tangent2End: CGPoint(x: rect.minX + bottomLeftRadius, y: rect.minY),
                        radius: bottomLeftRadius)
            path.addLine(to: CGPoint(x: rect.maxX - bottomRightRadius, y: rect.minY))
            path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
                        tangent2End: CGPoint(x: rect.maxX, y: rect.minY + bottomRightRadius),
                        radius: bottomRightRadius)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - topRightRadius))
            path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                        tangent2End: CGPoint(x: rect.maxX - topRightRadius, y: rect.maxY),
                        radius: topRightRadius)
            path.addLine(to: CGPoint(x: rect.minX + topLeftRadius, y: rect.maxY))
            path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                        tangent2End: CGPoint(x: rect.minX, y: rect.maxY - topLeftRadius),
                        radius: topLeftRadius)
            path.closeSubpath()

            let mask = CAShapeLayer()
            mask.path = path
            self.mask = mask
        }
    }
}

// MARK: - CGRect helpers

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

// MARK: - NSView convenience

extension NSView {
    /// Ensures the view is layer-backed and returns its layer.
    @discardableResult
    func ensureLayerBacked() -> CALayer {
        wantsLayer = true
        if layer == nil {
            layer = CALayer()
        }
        return layer!
    }
}
