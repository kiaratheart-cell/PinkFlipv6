//
//  BurnInGuard.swift
//  PinkFlip
//
//  Periodically produces a slow, subtle positional drift so that a
//  static, high-contrast clock face does not risk burning in to
//  displays that are susceptible to it. The movement is intentionally
//  tiny and slow so it is essentially invisible to the viewer.
//
//  This class does not move any view directly. Instead it owns the
//  current drift offset and calls back whenever it changes, leaving the
//  actual layout math to whoever owns the clock (PinkFlipView), which
//  already knows how to center the clock and can simply add this
//  offset on top of that centering each time it changes.
//

import Cocoa

final class BurnInGuard {

    /// Called whenever a new offset has been chosen. The receiver should
    /// animate its layout to the new offset over roughly `moveDuration`
    /// seconds for a smooth, unnoticeable drift.
    var onOffsetChanged: ((CGPoint, TimeInterval) -> Void)?

    /// How often a new drift offset is chosen.
    private let interval: TimeInterval

    /// Maximum drift distance from true center, in points.
    private let maxOffset: CGFloat

    /// The duration of the (barely perceptible) move animation itself.
    let moveDuration: TimeInterval = 8.0

    private var timer: Timer?
    private(set) var currentOffset: CGPoint = .zero

    /// - Parameters:
    ///   - interval: seconds between drift adjustments. Defaults to five
    ///     minutes: frequent enough to meaningfully protect the panel,
    ///     infrequent and slow enough to remain unnoticeable.
    ///   - maxOffset: maximum distance in points the clock may drift from
    ///     its true center in any direction.
    init(interval: TimeInterval = 300, maxOffset: CGFloat = 14) {
        self.interval = interval
        self.maxOffset = maxOffset
    }

    deinit {
        stop()
    }

    func start() {
        stop()
        let newTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.driftToNewOffset()
        }
        RunLoop.current.add(newTimer, forMode: .common)
        timer = newTimer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func driftToNewOffset() {
        let angle = CGFloat.random(in: 0..<(2 * .pi))
        let distance = CGFloat.random(in: (maxOffset * 0.3)...maxOffset)
        currentOffset = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
        onOffsetChanged?(currentOffset, moveDuration)
    }
}
