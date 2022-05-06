//

import Combine
import AVFoundation
import SwiftUI
import os.log

typealias ReferenceTimeProvider = () -> TimeInterval

enum CountdownState: CaseIterable {
    case ready
    case inProgress
    case triggering
    case complete
    case stopped
    case undefined
}

protocol CountdownDefaultsProtocol {
    var referenceTimeProvider: ReferenceTimeProvider { get }
    var countdownFrom: Double { get }
    var interval: TimeInterval { get }
}

// In most cases the client should be providing the defaults, but
// these fallbacks can provide a starting point and guide.
struct CountdownFallbackDefaults: CountdownDefaultsProtocol {
    let referenceTimeProvider = { Date().timeIntervalSince1970 }
    let countdownFrom = 5.0
    let interval = 0.5
}

// TODO: Rename "startAt" to referenceTime.
// referenceTime is the absolute time when the countdown starts. In most cases this will be the current time.
// but for testing (and added feature flexibility) it is useful to specify a specific time.
// TODO: Pass a referenceTimeProvider in init that will execute on start to prive the timeZero time
// which is usually
class Countdown: ObservableObject {
    static let log = PicItSelfLog<Countdown>.get()
    
    @Published private(set) var time = 0.0
    @Published private(set) var state: CountdownState = .undefined
    
    private var cancellable: AnyCancellable?
    private var timerPublishers = TimerPublishers()
    private var defaults: CountdownDefaultsProtocol
    
    init(defaults: CountdownDefaultsProtocol = CountdownFallbackDefaults()) {
        self.defaults = defaults
        state = .ready
        Self.log.debug("Countdown Initialized to ready state")
    }
    
    func reset() {
        cancellable?.cancel()
        switch state {
        case .ready:
            break
        case .inProgress, .triggering, .stopped, .complete:
            state = .ready
        case .undefined:
            Self.log.warning("Resetting from an undefined state")
            state = .ready
        }
    }
    
    func start(_ countdownFrom: Double? = nil,
               interval: TimeInterval? = nil,
               referenceTime: TimeInterval? = nil) {
        let interval = interval ?? defaults.interval
        let referenceTime = referenceTime ?? defaults.referenceTimeProvider()
        let countdownFrom = countdownFrom ?? defaults.countdownFrom
        Self.log.debug("Countdown attempting to start from state: \(String(describing: self.state))")
        cancellable?.cancel() // just in case
        switch state {
        case .ready:
            Self.log.debug("Starting Countdown from \(countdownFrom)")
            cancellable = timerPublishers.countdownPublisher(countdownFrom: countdownFrom, referenceTime: referenceTime, interval: interval)
                .sink { [weak self] time in
                    self?.time = time
                    self?.updateStateFromTimer(countdownTimer: time, countdownFrom: countdownFrom)
                }
        default:
            Self.log.notice("Invalid starting state: \(String(describing: self.state))")
        }
    }
    
    // Basically start, but with a cleaner type signature
    // instead of (TimeInterval, TimeInterval, Double) -> Void, it is () -> Void
    func restart() {
        start()
    }
    
    func stop() {
        DispatchQueue.main.async {
            Self.log.debug("stopping countdown from main thread")
            self.state = .stopped
            self.cancellable?.cancel()
            self.state = .ready
        }
    }
    
    private func updateStateFromTimer(countdownTimer: TimeInterval, countdownFrom: Double) {
        var newState = state
        if countdownTimer <= 0.0 {
            if state == .inProgress {
                newState = .triggering
            }
            if state == .triggering {
                newState = .complete
                // stop the countdown timer
                stop()
                newState = .ready
            }
        } else if countdownTimer <= countdownFrom {
            newState = .inProgress
        } else {
            // countdownTimer > countdownFrom (not sure how we got here)
            newState = .undefined
        }
        self.state = newState
    }
}
