//

import Combine
import AVFoundation
import SwiftUI
import os.log

typealias ReferenceTimeProvider = () -> TimeInterval
typealias CountdownPublisherClosure = (CountdownPublisherArgsProtocol) -> AnyPublisher<Double, Never>

enum CountdownState: CaseIterable {
    case ready
    case inProgress
    case triggering
    case complete
    case stopped
    case undefined
}

protocol CountdownDependenciesProtocol {
    var referenceTimeProvider: ReferenceTimeProvider { get }
    var countdownFrom: Double { get }
    var interval: TimeInterval { get }
    var countdownPublisherClosure: CountdownPublisherClosure { get }
}

// In most cases the client should be providing the defaults, but
// these fallbacks can provide a starting point and guide.
struct CountdownDependencies: CountdownDependenciesProtocol {
    var referenceTimeProvider = { Date().timeIntervalSince1970 }
    var countdownFrom = 5.0
    var interval = 0.5
    var countdownPublisherClosure = TimerPublishers().countdownPublisher
}

struct CountdownPublisherArgs: CountdownPublisherArgsProtocol {
    let countdownFrom: Double
    let referenceTime: TimeInterval
    let interval: TimeInterval? // fall back to default if not provided
}

// TODO: Rename "startAt" to referenceTime.
// referenceTime is the absolute time when the countdown starts. In most cases this will be the current time.
// but for testing (and added feature flexibility) it is useful to specify a specific time.
// TODO: Pass a referenceTimeProvider in init that will execute on start to prive the timeZero time
// which is usually
class Countdown: ObservableObject {
    static let log = PicItSelfLog<Countdown>.get()
    
    // The initial value of the time property before any updates have been published by the underlying publisher
    static let initialCountdownTime = 0.0
    
    @Published private(set) var time = Countdown.initialCountdownTime
    @Published private(set) var state: CountdownState = .ready
    
    private var cancellable: AnyCancellable?
    private var dependencies: CountdownDependenciesProtocol
    
    private var countdownPublisher: CountdownPublisherClosure
    
    init(_ deps: CountdownDependenciesProtocol = CountdownDependencies()) {
        self.dependencies = deps
        self.countdownPublisher = deps.countdownPublisherClosure // syntactic sugar
        Self.log.debug("Countdown Initialized")
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
        let interval = interval ?? dependencies.interval
        let referenceTime = referenceTime ?? dependencies.referenceTimeProvider()
        let countdownFrom = countdownFrom ?? dependencies.countdownFrom
        Self.log.debug("Countdown attempting to start from state: \(String(describing: self.state))")
        cancellable?.cancel() // just in case
        switch state {
        case .ready:
            Self.log.debug("Starting Countdown from \(countdownFrom)")
            let countdownArgs = CountdownPublisherArgs(countdownFrom: countdownFrom, referenceTime: referenceTime, interval: interval)
            cancellable = countdownPublisher(countdownArgs)
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
        Self.log.debug("stopping countdown")
        self.state = .stopped
        self.cancellable?.cancel()
        // self.state = .complete
    }
    
    func complete() {
        Self.log.debug("Countdown complete")
        self.cancellable?.cancel()
        self.state = .complete
    }
    
    private func updateStateFromTimer(countdownTimer: TimeInterval, countdownFrom: Double) {
        if countdownTimer <= 0.0 {
            switch state {
            case .inProgress:
                self.state = .triggering
            case .triggering:
                complete()
            case .complete, .stopped, .undefined:
                Self.log.warning("Countdown still running in state \(state)")
            case .ready:
                Self.log.warning("Countdown ended without ever being .inProgress")
            }
        } else if countdownTimer <= countdownFrom {
            self.state = .inProgress
        } else {
            // countdownTimer > countdownFrom (not sure how we got here)
            self.state = .undefined
        }
    }
}
