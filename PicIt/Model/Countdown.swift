//

import Combine
import AVFoundation
import SwiftUI
import os.log

enum CountdownState {
    case ready
    case inProgress
    case triggering
    case complete
    case stopped
    case undefined
}

class Countdown: ObservableObject {
    static let defaultInterval = PicItSetting.interval
    static let log = Logger(subsystem: "us.joha.PicIt", category: "Countdown")
    
    @Published private(set) var time = 0.0
    @Published private(set) var state: CountdownState = .undefined
    
    private var cancellable: AnyCancellable?
    private var timerPublishers = TimerPublishers()
    
    init() {
        state = .ready
    }
    
    func start(_ interval: TimeInterval = defaultInterval,
               startAt: TimeInterval = Date().timeIntervalSince1970, countdownFrom: Double = Double(SettingsStore.countdownStart)) {
        Self.log.debug("Countdown attempting to start from state: \(String(describing: self.state))")
        cancellable?.cancel() // just in case
        switch state {
        case .ready:
            Self.log.debug("Starting Countdown from \(countdownFrom)")
            cancellable = timerPublishers.countdownPublisher(startAt: startAt, countdownFrom: countdownFrom, interval: interval)
                .sink { [weak self] time in
                    self?.time = time
                    self?.updateStateFromTimer(countdownTimer: time, countdownFrom: countdownFrom)
                }
        default:
            Self.log.debug("Invalid starting state: \(String(describing: self.state))")
        }
    }
    
    // Basically start, but with a cleaner type signature,
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
