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

// We use inheritance rather than protocol because protocol doesn't support @Published yet.
// This allows us to swap out an countdown object that is disabled vs one that is enabled
class CountdownBase: ObservableObject {
    @Published var countdownState: CountdownState = .notStarted
    @Published var time = 0.0
    @Published var started: TimeInterval = Date().timeIntervalSince1970
    
    // I'm not entirely happy with having a function to express the state of the class.
    // It's primary purpose at the moment is to determine if an countdown implementation
    // should be re-initialized (i.e. restart the timer).
    // To explain further. An alternate approach (that didn't work out) would be to use an
    // optional (i.e. `Countdown?`. And set it to nil when we want to stop the timer, and
    // to restart the timer, we check if it's nil, and recreate it if it is. For example:
    // let countdown == countdown ?? Countdown() (remember the type is Countdown?)
    // The problem with that approach is that `nil` is not a publisher, so `onReceive` blows up
    // So we get around that by having a `DisabledCounter` that is a valid publisher, it just
    // doesn't publish anything. But then we still needed a check to see if the timer needed
    // replacing on restart ... so we ended up with this function.
    func isDisabled() -> Bool {
        return true
    }
}

// Concrete class for the disabled countdown. Keeps CountdownBase abstract
// while also having a more expressive name
class DisabledCountdown: CountdownBase {}

// The main Countdown class that will actually countdown.
class Countdown: CountdownBase {
    // Use the User Setting for the delay value.
    @AppStorage(PicItSetting.delay.key) var delay: Double = PicItSetting.delay.value
    
    override func isDisabled() -> Bool {
        return false
    }
    
    override init() {
        super.init()
        let mainTimerPublisher = Timer.publish(
            every: PicItSetting.interval,
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
                // return the countdown value
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
                    // countoown > delay
                    newState = .notStarted
                }
                return newState
            })
            .assign(to: &$countdownState)
    }
}
