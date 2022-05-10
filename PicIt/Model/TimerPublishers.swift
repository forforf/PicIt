//
import Foundation
import Combine

protocol CountdownPublisherArgsProtocol {
    var countdownFrom: Double { get }
    var referenceTime: TimeInterval { get }
    var interval: TimeInterval? { get }
}

struct TimerPublishers {
    static let defaultInterval = 0.5
    
    // Creates a publisher (correct term?) for generating intervals suitable for chaining
    // with more operators
    func intervalPublisher(interval: TimeInterval = defaultInterval) -> AnyPublisher<TimeInterval, Never> {
        return Timer.publish(every: interval, on: .main, in: .default)
            .autoconnect()
            .map(\.timeIntervalSince1970)
            .eraseToAnyPublisher()
    }
    
    // Converts interval into elapsedTime (given a starting time `startAt`)
    func elapsedPublisherClosure(referenceTime: TimeInterval, interval: TimeInterval) -> AnyPublisher<TimeInterval, Never> {
        return self.intervalPublisher(interval: interval)
            .map({ (timeInterval) in
                return timeInterval - referenceTime
            })
            .eraseToAnyPublisher()
    }
    
    // Converts an elapsedTime into a countdown timer, given `countdownFrom`
    // Note regarding Double vs TimeInterval. I don't have strong argument for using Double for Countdown it just feels
    // like the countdown is just a number to me. PS: TimeInterval is a system defined typealias for Double anyway.
    func countdownPublisher(args: CountdownPublisherArgsProtocol) -> AnyPublisher<Double, Never> {
        let interval = args.interval ?? Self.defaultInterval
        return self.elapsedPublisherClosure(referenceTime: args.referenceTime, interval: interval)
            .map({elapsedTime in
                return args.countdownFrom - elapsedTime
            })
            .eraseToAnyPublisher()
    }
}
