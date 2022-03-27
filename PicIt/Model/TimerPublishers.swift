//
import Foundation
import Combine

typealias ConnectedTimerPublisher = Publishers.Autoconnect<Timer.TimerPublisher>
typealias IntervalPublisher = Publishers.MapKeyPath<ConnectedTimerPublisher, TimeInterval>
typealias IntervalMapPublisher = Publishers.Map<IntervalPublisher, TimeInterval>
typealias IntervalMapPublisherClosure = (TimeInterval) -> IntervalMapPublisher

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
    func elapsedPublisherClosure(startAt: TimeInterval, interval: TimeInterval) -> IntervalMapPublisher {
        return self.intervalPublisher(interval: interval)
            .map({ (timeInterval) in
                return timeInterval - startAt
            })
    }
    
    // Converts an elapsedTime into a countdown timer, given `countdownFrom`
    func countdownPublisher(startAt: TimeInterval, countdownFrom: Double, interval: TimeInterval = defaultInterval) -> IntervalMapPublisher {
        return self.elapsedPublisherClosure(startAt: startAt, interval: interval)
            .map({elapsedTime in
                return countdownFrom - elapsedTime
            })
    }
}
