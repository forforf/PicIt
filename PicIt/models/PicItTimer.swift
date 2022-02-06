//

import Combine
import AVFoundation

enum PicItTimerState {
    case started
    case stopped
}

/*
   delay: How long to wait from the time the timer start until it takes a pciture
   interval: How often the view should update (mainly for countdown timer updates)
   tolerance: How far off the interval can be, used internally by the OS to optimize timer performance
 FUTURE:
   retakes: Number of times to take the picture
   retakeInterval: Delay between each picture retake
 */
class PicItTimer {
    let delay: Double
    let interval: Double
    let tolerance: Double
    var publisher: Timer.TimerPublisher
    var cancellable: AnyCancellable?
    var state: PicItTimerState
    
    static private func startTimer(interval: Double, tolerance: Double) -> Timer.TimerPublisher {
        return Timer.TimerPublisher(
            interval: interval,
            tolerance: tolerance,
            runLoop: .main,
            mode: .common
        )
    }

    init(
        delay: Double,
        interval: Double,
        tolerance: Double) {
            print("INIT called for PicItTimer")
            self.delay = delay
            self.interval = interval
            self.tolerance = tolerance
            self.publisher = Self.startTimer(interval: interval, tolerance: tolerance)
            self.state = .started
            self.cancellable = publisher.connect() as? AnyCancellable
        }

    deinit {
        self.cancellable?.cancel()
        self.state = .stopped
    }
    
    func stopTimer() {
        print("Stopping Timmer")
        self.cancellable?.cancel()
        self.state = .stopped
        print("Stopped Timer")
    }
    
    func restartTimer() {
        print("Restarting Timer")
        if self.state != .started {
            self.publisher = Self.startTimer(interval: self.interval, tolerance: self.tolerance)
            self.cancellable = publisher.connect() as? AnyCancellable
            self.state = .started
            print("Restarted Timer")
        } else {
            // TODO: Replace print with better handler (maybe closure?)
            print("Tried to restart already running timer!!!!!")
        }
    }
    
    func timeRemaining(_ counter: Double) -> Double{
        print("Calcuating time remaining: \(delay - counter), current state: \(self.state)")
        return delay - counter
    }
}
