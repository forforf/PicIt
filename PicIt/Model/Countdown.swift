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

//    @Published var time = 0.0
//
//    @Published var started: TimeInterval = Date().timeIntervalSince1970
//    @Published var countdownState: CountdownState = .notStarted
    
    //TODO: Store the cancellables
    
    
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
                    // countoown > delay
                    newState = .notStarted
                }
                return newState
            })
            .assign(to: &$countdownState)
    }
}

//enum PicItTimerState {
//    case started
//    case stopped
//}



/*
   delay: How long to wait from the time the timer start until it takes a pciture
   interval: How often the view should update (mainly for countdown timer updates)
   tolerance: How far off the interval can be, used internally by the OS to optimize timer performance
 FUTURE:
   retakes: Number of times to take the picture
   retakeInterval: Delay between each picture retake
 */
//class PicItTimer: ObservableObject {
//    // TODO: See if there is a way to inject this rather than declaring it inside
//    @AppStorage(PicItSetting.delay.key) var delay: Double = PicItSetting.delay.value
//
////    let delay: Double
//    let interval: Double
//    let tolerance: Double
//    @Published var publisher: Publishers.Autoconnect<Timer.TimerPublisher>
//    @Published private(set) var foo = Date().timeIntervalSince1970
//    @Published var countdownState: CountdownState = .notStarted
//
////    private var countdownStartTime: Date?
//
////    lazy var publisher = Timer.TimerPublisher(
////        interval: interval,
////        tolerance: tolerance,
////        runLoop: .main,
////        mode: .common
////    ).autoconnect()
//
//
////    private var picitDelay: Double {
////        return Double(_picitDelay) ?? PicItSetting.delay.value
////    }
//
//
//    var state: PicItTimerState
//
//    init(
//        delay: Double,
//        interval: Double,
//        tolerance: Double) {
//            self.delay = delay
//            self.interval = interval
//            self.tolerance = tolerance
//
//            let publisher = Timer.TimerPublisher(
//                interval: interval,
//                tolerance: tolerance,
//                runLoop: .main,
//                mode: .common
//            ).autoconnect()
//
//            self.publisher = publisher
//
//
////            Timer.publish(
////                every: 1,
////                on: .main,
////                in: .default
////            )
////            .autoconnect()
////            .map(\.timeIntervalSince1970)
////            .assign(to: &$foo)
//
//
////            foo.sink(
////                receiveCompletion: { completion in
////                    print("COMPLETION: \(completion)")
////                },
////                receiveValue: { value in
////                    print("VALUE: \(value)")
////                }
////            )
//
//
//
//
//
////            publisher
////                .map({ output in
////                    return Double(output.timeIntervalSince1970)
////                })
////                .sink( { time in
////                    $countdown = time.
////                })
//            print("INIT called for PicItTimer: \(delay), \(interval), \(tolerance)")
//            //            self.publisher = Self.startTimer(interval: interval, tolerance: tolerance)
//            self.state = .started
//            //            self.cancellable = publisher.connect() as? AnyCancellable
//        }
//
//    convenience init(interval: Double, tolerance: Double) {
//        let delay = PicItSetting.delay.value
//        self.init(delay: delay, interval: interval, tolerance: tolerance)
//    }
//
//
//    deinit {
////        self.cancellable?.cancel()
//        self.state = .stopped
//        self.publisher.upstream.connect().cancel()
//    }
//
//    func stopTimer() {
//        print("Stopping Timmer")
//        self.publisher.upstream.connect().cancel()
////        self.cancellable?.cancel()
//
//        self.state = .stopped
//        print("Stopped Timer")
//    }
//
//    func restartTimer() {
//        print("Restarting Timer")
//
//        if self.state != .started {
//            self.publisher = Timer.TimerPublisher(
//                interval: interval,
//                tolerance: tolerance,
//                runLoop: .main,
//                mode: .common
//            ).autoconnect()
////            self.publisher = Self.startTimer(interval: self.interval, tolerance: self.tolerance)
////            self.cancellable = publisher.connect() as? AnyCancellable
//            self.state = .started
//            print("Restarted Timer")
//        } else {
//            // TODO: Replace print with better handler (maybe closure?)
//            print("Tried to restart already running timer!!!!!")
//        }
//    }
//
//    func timeRemaining(_ counter: Double) -> Double{
//        print("Calcuating time remaining: \(delay - counter), current state: \(self.state)")
//        return delay - counter
//    }
//}
