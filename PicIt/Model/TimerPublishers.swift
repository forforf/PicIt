//
import Foundation
import Combine

typealias ConnectedTimerPublisher = Publishers.Autoconnect<Timer.TimerPublisher>
typealias IntervalPublisher = Publishers.MapKeyPath<ConnectedTimerPublisher, TimeInterval>
typealias IntervalMapPublisher = Publishers.Map<IntervalPublisher, TimeInterval>

protocol CountdownPublisherArgsProtocol {
    var countdownFrom: Double { get }
    var referenceTime: TimeInterval { get }
    var interval: TimeInterval? { get }
}

struct TimerPublishers {
    static let defaultInterval = 0.5
    
    // Creates a publisher (correct term?) for generating intervals suitable for chaining
    // with more operators
    func intervalPublisher(interval: TimeInterval = defaultInterval) -> IntervalPublisher {
        return Timer.publish(every: interval, on: .main, in: .default)
            .autoconnect()
            .map(\.timeIntervalSince1970)
    }
    
    // Converts interval into elapsedTime (given a starting time `startAt`)
    func elapsedPublisherClosure(referenceTime: TimeInterval, interval: TimeInterval) -> IntervalMapPublisher {
        return self.intervalPublisher(interval: interval)
            .map({ (timeInterval) in
                return timeInterval - referenceTime
            })
    }
    
    // Converts an elapsedTime into a countdown timer, given `countdownFrom`
    func countdownPublisher(args: CountdownPublisherArgsProtocol) -> IntervalMapPublisher {
        let interval = args.interval ?? Self.defaultInterval
        return self.elapsedPublisherClosure(referenceTime: args.referenceTime, interval: interval)
            .map({elapsedTime in
                return args.countdownFrom - elapsedTime
            })
    }
}
