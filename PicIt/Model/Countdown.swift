//

import Combine
import AVFoundation
import SwiftUI

enum CountdownState {
    case ready
    case inProgress
    case triggering
    case complete
    case stopped
    case undefined
}

class Countdown: ObservableObject {
    static let defaultInterval = 0.5
    
    @Published private(set) var time = 0.0
    @Published private(set) var state: CountdownState = .undefined
    
    private var cancellable: AnyCancellable?
    private var timerPublishers = TimerPublishers()
    
    init() {
        self.state = .ready
    }
    
    func start(_ interval: TimeInterval = defaultInterval,
               startAt: TimeInterval = Date().timeIntervalSince1970, countdownFrom: Double = 5) {
        
        if state == .ready {
            cancellable = timerPublishers.countdownPublisher(startAt: startAt, countdownFrom: countdownFrom, interval: interval)
                .sink { [weak self] time in
                    self?.time = time
                    self?.updateStateFromTimer(countdownTimer: time, countdownFrom: countdownFrom)
                }
        } else {
            print("Invalid state: \(state)")
        }
    }
    
    func stop() {
        self.state = .stopped
        cancellable?.cancel()
        self.state = .ready
    }
    
    private func updateStateFromTimer(countdownTimer: TimeInterval, countdownFrom: Double){
        var newState = self.state
        if countdownTimer <= 0.0 {
            if self.state == .inProgress {
                newState = .triggering
            }
            if self.state == .triggering {
                newState = .complete
                // stop the countdown timer
                self.stop()
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
