//

import Combine
import AVFoundation
import SwiftUI

enum CountdownState {
    case notStarted
    case inProgress
    case triggering
    case complete
}

class CountdownBase: ObservableObject {
    @Published var countdownState: CountdownState = .notStarted
    @Published var time = 0.0
    @Published var started: TimeInterval = Date().timeIntervalSince1970
    
    func isEmpty() -> Bool {
        return true
    }
}

class EmptyCountdown: CountdownBase {
    
}

class Countdown: CountdownBase {
    @AppStorage(PicItSetting.delay.key) var delay: Double = PicItSetting.delay.value
    
    override func isEmpty() -> Bool {
        return false
    }
    
    // I need to investigate to see if it is working as intended, but the goal
    // here is to have the publisher be ephemeral and set up in init. That way
    // when the Countdown object is deallocated, all the resources will be
    // cleaned up automatically.
    override init() {
        super.init()
        print("INIT for Countdown")
        let mainTimerPublisher = Timer.publish(
            every: 1,
            on: .main,
            in: .default
        )
        
        let cancellable = mainTimerPublisher.autoconnect()
        started = Date().timeIntervalSince1970
        
        // Take today's date and combine it with a timer
        // calculate the countdown value and assign it to
        // a published var so we can trigger on it as well
        $started.combineLatest(cancellable)
            .map({ started, time in
                let elapsedTime =  time.timeIntervalSince1970 - started
                // countdown value
                return self.delay - elapsedTime
            })
            .assign(to: &$time)
        
        // $time is the countdown value, so we map it to
        // the relevant countdown states
        // This decouples the countdown value from the
        // countdown state. This allows us to use the
        // countdown state for triggering any actions
        $time
            .map({ (countdown) -> (CountdownState) in
                var newState = self.countdownState
                if countdown <= 0.0 {
                    if self.countdownState == .inProgress {
                        newState = .triggering
                    }
                    if self.countdownState == .triggering {
                        newState = CountdownState.complete
                        // stop the countdown timer
                        cancellable.upstream.connect().cancel()
                    }
                } else if countdown <= self.delay {
                    newState = CountdownState.inProgress
                } else {
                    // countdown > delay
                    newState = .notStarted
                }
                return newState
            })
            .assign(to: &$countdownState)
    }
}
