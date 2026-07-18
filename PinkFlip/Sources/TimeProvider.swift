//
//  TimeProvider.swift
//  PinkFlip
//
//  Supplies the current wall-clock time to the clock view and notifies
//  it precisely when the displayed minute changes, so the UI only
//  updates (and animates) exactly once per minute rather than polling
//  and redrawing constantly. This keeps CPU usage extremely low, which
//  matters a great deal for a screensaver.
//

import Foundation

/// A single snapshot of the time values the clock needs to render.
struct ClockTime: Equatable {
    /// Hour in 12-hour format, 1...12.
    let hour12: Int
    /// Minute, 0...59.
    let minute: Int
    /// Whether the current time is PM.
    let isPM: Bool

    var hourTens: Int { hour12 / 10 }
    var hourOnes: Int { hour12 % 10 }
    var minuteTens: Int { minute / 10 }
    var minuteOnes: Int { minute % 10 }

    static func from(date: Date, calendar: Calendar) -> ClockTime {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour24 = components.hour ?? 0
        let minute = components.minute ?? 0
        let isPM = hour24 >= 12
        var hour12 = hour24 % 12
        if hour12 == 0 { hour12 = 12 }
        return ClockTime(hour12: hour12, minute: minute, isPM: isPM)
    }
}

/// Observes the system clock and calls back whenever the minute changes.
///
/// Internally this uses a lightweight one-second repeating timer purely
/// to detect the minute boundary reliably (accounting for sleep/wake and
/// clock adjustments) without depending on exact timer fire alignment.
/// The one-second timer does negligible work (an integer comparison) so
/// its CPU cost is effectively zero.
final class TimeProvider {

    /// Called immediately with the current time when observation starts,
    /// and again every time the minute value changes thereafter.
    var onTimeChanged: ((ClockTime) -> Void)?

    private var timer: Timer?
    private var lastMinute: Int = -1
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    deinit {
        stop()
    }

    /// Begins observing the system clock.
    func start() {
        stop()

        let initial = ClockTime.from(date: Date(), calendar: calendar)
        lastMinute = initial.minute
        onTimeChanged?(initial)

        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // .common so it keeps firing while the screensaver's run loop is
        // tracking other events (e.g. during window server activity).
        RunLoop.current.add(newTimer, forMode: .common)
        timer = newTimer
    }

    /// Stops observing the system clock.
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let now = ClockTime.from(date: Date(), calendar: calendar)
        guard now.minute != lastMinute else { return }
        lastMinute = now.minute
        onTimeChanged?(now)
    }
}
