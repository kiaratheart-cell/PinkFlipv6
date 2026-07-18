//
//  FlipAnimation.swift
//  PinkFlip
//
//  Reusable Core Animation constants and animation factories for the
//  split-flap "flip" effect used by FlipDigitView. Keeping the animation
//  construction here separates timing/easing concerns from the layer
//  layout logic in FlipDigitView.
//

import QuartzCore

enum FlipAnimation {

    /// Total duration of a full flip (both the top-flap-falls and the
    /// bottom-flap-rises phases combined). Kept short and understated,
    /// per the "not overly dramatic" design goal.
    static let totalDuration: TimeInterval = 0.35

    /// Each half of the flip gets exactly half the total duration.
    static var phaseDuration: TimeInterval { totalDuration / 2.0 }

    /// Perspective strength applied to the container layer's
    /// sublayerTransform so rotated flaps feel three dimensional rather
    /// than simply squashing flat.
    static let perspective: CGFloat = -1.0 / 1400.0

    /// Standard easing used for both flip phases: gentle acceleration in,
    /// gentle deceleration out, matching the restrained motion requested.
    static var timingFunction: CAMediaTimingFunction {
        CAMediaTimingFunction(name: .easeInEaseOut)
    }

    /// Builds a rotation-around-X-axis animation for a flap layer.
    ///
    /// - Parameters:
    ///   - fromDegrees: starting rotation, in degrees.
    ///   - toDegrees: ending rotation, in degrees.
    ///   - beginTime: optional CAMediaTiming begin time offset (relative
    ///     to the enclosing transaction) used to chain the two phases.
    static func rotationAnimation(fromDegrees: CGFloat,
                                   toDegrees: CGFloat) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform")
        let fromTransform = CATransform3DRotate(CATransform3DIdentity,
                                                 fromDegrees * .pi / 180.0,
                                                 1, 0, 0)
        let toTransform = CATransform3DRotate(CATransform3DIdentity,
                                               toDegrees * .pi / 180.0,
                                               1, 0, 0)
        animation.fromValue = NSValue(caTransform3D: fromTransform)
        animation.toValue = NSValue(caTransform3D: toTransform)
        animation.duration = phaseDuration
        animation.timingFunction = timingFunction
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        return animation
    }

    /// Builds a subtle shading (opacity) animation used to darken a flap
    /// slightly as it rotates toward edge-on, simulating a soft shadow
    /// passing across the card, then fading back out.
    static func shadingAnimation(peakOpacity: Float, risingFirst: Bool) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        if risingFirst {
            animation.values = [0.0, peakOpacity, 0.0]
        } else {
            animation.values = [0.0, peakOpacity, peakOpacity]
        }
        animation.keyTimes = [0.0, 0.6, 1.0]
        animation.duration = phaseDuration
        animation.timingFunction = timingFunction
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        return animation
    }
}
