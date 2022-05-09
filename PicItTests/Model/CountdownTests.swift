//

import XCTest
import Combine

@testable import PicIt

typealias Closure<ARG, RET> = (ARG) -> RET
// typealias ExpectationCompletion = (Subscribers.Completion<Never>) -> Void

// TODO: create new helper function countdown that does not go below 0 ... this will leave the state as .inProgress (so we can test that)
//       Once we have a couple functions, DRY it up so that we can test various countdown scenarios.
class CountdownTests: XCTestCase {
        
    private var countdownBasic: Countdown!
    
    // This value is appended to the countdown, it signals that we've finished all countdown related work
    // I would MUCH rather use a copletion handler, but haven't figured out how to do that for a published variable
    // in an ObservableObject.
//    private static let markEndOfCountdown = -999.0
    private var cancellables: Set<AnyCancellable> = []
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Setup a basic countdown instance
        let countdownListBasic = makeCountdownList(interval: MockDefaults.interval, countdownFrom: MockDefaults.countdownFrom)
        let countdownDependenciesBasic = makeDependencies(countdownListBasic)
        countdownBasic = Countdown(countdownDependenciesBasic)
    }
    
    override func tearDownWithError() throws {
        cancellables = []
    }
    
    // Instantiation Tests
    func test_init_stateIsReady() throws {
        XCTAssertEqual(Countdown().state, .ready) // Test default initialization
        XCTAssertEqual(countdownBasic.state, .ready)
    }
    
    func test_init_timeIsInitialized() throws {
        XCTAssertEqual(Countdown().time, Countdown.initialCountdownTime) // Test default initialization
        XCTAssertEqual(countdownBasic.time, Countdown.initialCountdownTime)
    }
        
    // countdown behavior tests
    func test_start_timeIsUpdated() throws {
        self.continueAfterFailure = false
        let expectation = XCTestExpectation(description: "Wait for last countdown value")

        let countdownList = makeCountdownList(interval: MockDefaults.interval, countdownFrom: MockDefaults.countdownFrom)
        let mockCompleteCountdown = MockFactory.addEndMarker(countdownList)
        let countdownDependencies = makeDependencies(mockCompleteCountdown)
        let countdown = Countdown(countdownDependencies)
        
        var expectedCountdownTimes = expectedCountdownComplete(countdownList,
                                                               initVal: Countdown.initialCountdownTime,
                                                               endMarker: CountdownTests.markEndOfCountdown)
        
        timeSubscriberWithExpectation(countdown, expectation: expectation) { time in
            // remove elements from the expected array and compare to actual published value
            let expectedCountdownTime = expectedCountdownTimes.isEmpty ? nil : expectedCountdownTimes.removeFirst()
            XCTAssertNotNil(expectedCountdownTime)
            XCTAssertEqual(expectedCountdownTime!, time, accuracy: 0.01) // compare to published value
        }
        
        countdown.start()
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_start_stateInProgress() throws {
        let countdownList = [MockDefaults.countdownFrom]
        let countdownDependencies = makeDependencies(countdownList)
        let countdown = Countdown(countdownDependencies)
        
        var receivedStates: [CountdownState] = []
        let expectation = XCTestExpectation(description: "Get first countdown event")
        // TODO: This test is failing, because Countdown behavior needs to change
        let expectedCountdownStates: [CountdownState] = [.ready, .inProgress]
  
        // Fulfills expecation
        timeSubscriber(countdown) { time in
            print("Countdown time: \(time)")
            if time == MockDefaults.countdownFrom {
                expectation.fulfill()
            }
        }
        
        countdown.$state
            .removeDuplicates() // Remove duplicates to get unique states chnages
            .sink { state in receivedStates.append(state) }
            .store(in: &cancellables)
        
        countdown.start()
        wait(for: [expectation], timeout: 0.1)
        
        XCTAssertEqual(expectedCountdownStates, receivedStates)
    }
    
    func test_start_stateTriggering() throws {
        let triggerValue = 0.0 // must be <= 0
        let countdownList = [MockDefaults.countdownFrom, triggerValue]
        let countdownDependencies = makeDependencies(countdownList)
        let countdown = Countdown(countdownDependencies)
        
        var receivedStates: [CountdownState] = []
        let expectation = XCTestExpectation(description: "Wait until triggering")
        // TODO: This test is failing, because Countdown behavior needs to change
        let expectedCountdownStates: [CountdownState] = [.ready, .inProgress, .triggering]
  
        // Fulfills expecation
        timeSubscriber(countdown) { time in
            print("Countdown time: \(time)")
            if time == triggerValue {
                expectation.fulfill()
            }
        }
        
        countdown.$state
            .removeDuplicates() // Remove duplicates to get unique states chnages
            .sink { state in receivedStates.append(state) }
            .store(in: &cancellables)
        
        countdown.start()
        wait(for: [expectation], timeout: 0.1)
        
        XCTAssertEqual(expectedCountdownStates, receivedStates)
    }
    
    func test_start_stateIsUpdatedOnCompleteCountdown() throws {
        let countdownList = makeCountdownList(interval: MockDefaults.interval, countdownFrom: MockDefaults.countdownFrom)
        let mockCompleteCountdown = MockFactory.addEndMarker(countdownList)
        let countdownDependencies = makeDependencies(mockCompleteCountdown)
        let countdown = Countdown(countdownDependencies)
        
        var receivedStates: [CountdownState] = []
        let expectation = XCTestExpectation(description: "Wait for last countdown value")
        // TODO: This test is failing, because Countdown behavior needs to change
        let expectedCountdownStates: [CountdownState] = [.ready, .inProgress, .triggering, .complete]
  
        // Fulfills expecation
        timeSubscriberWithExpectation(countdown, expectation: expectation)
        
        countdown.$state
            .removeDuplicates() // Remove duplicates to get unique states chnages
            .sink { state in
            receivedStates.append(state)
        }
        .store(in: &cancellables)
        
        countdown.start()
        wait(for: [expectation], timeout: 0.1)
        
        XCTAssertEqual(expectedCountdownStates, receivedStates)
        
        print("Expected: \(String(describing: expectedCountdownStates))")
        print("Received: \(String(describing: receivedStates))")
    }
    
    func test_reset_countdownNeverSubscribed() throws {
        countdownBasic.reset()
        XCTAssertEqual(countdownBasic.state, .ready)
        XCTAssertEqual(countdownBasic.time, Countdown.initialCountdownTime)
    }
         
    private func timeSubscriber(_ countdown: Countdown, perform: Closure<Double, Void>? = nil) {
        countdown.$time.sink { time in
            perform?(time)
        }
        .store(in: &cancellables)
    }
    
    private func timeSubscriberWithExpectation(_ countdown: Countdown, expectation: XCTestExpectation, perform: Closure<Double, Void>? = nil ) {
        timeSubscriber(countdown) { time in
            perform?(time)
            if time == Self.markEndOfCountdown {
                expectation.fulfill()
            }
        }
    }
}

// Test Helpers for setting up mocks
extension CountdownTests {
    private static let markEndOfCountdown = -999.0
    
    func makeCountdownList(interval: TimeInterval, countdownFrom: Double) -> [Double] {
        let step = -interval
        return Array(stride(from: countdownFrom, through: step, by: step))
    }
    
    func makeDependencies(_ countdownList: [Double]) -> CountdownDependencies {
        let countdownPublisherClosure = MockFactory.countdownClosure(countdownList)
        return MockFactory.getCountdownDependencies(countdownPublisherClosure)
    }
    
    func expectedCountdownComplete(_ countdownList: [Double], initVal: Double, endMarker: Double) -> [Double] {
        var wrappedList = countdownList
        wrappedList.insert(initVal, at: 0)
        wrappedList.append(endMarker)
        return wrappedList
    }
    
    struct MockDefaults {
        static let referenceTimeClosure = { Date(timeIntervalSinceReferenceDate: 0.0).timeIntervalSince1970}
        static let countdownFrom = 5.5
        static let interval = 0.7
    }

    struct MockFactory {
        
        static func addEndMarker(_ countdownList: [Double]) -> [Double] {
            return countdownList + [CountdownTests.markEndOfCountdown]
        }

        static func getCountdownDependencies(_ countdownPublisherClosure: @escaping CountdownPublisherClosure,
                                             referenceTimeProvider: @escaping ReferenceTimeProvider = MockDefaults.referenceTimeClosure,
                                             countdownFrom: Double = MockDefaults.countdownFrom,
                                             interval: TimeInterval = MockDefaults.interval
        ) -> CountdownDependencies {
            return CountdownDependencies(
                referenceTimeProvider: referenceTimeProvider,
                countdownFrom: countdownFrom,
                interval: interval,
                countdownPublisherClosure: countdownPublisherClosure
            )
        }

        static func getCountdownPublisherArgs(_ deps: CountdownDependenciesProtocol) -> CountdownPublisherArgsProtocol {
            return CountdownPublisherArgs(
                countdownFrom: deps.countdownFrom,
                referenceTime: deps.referenceTimeProvider(),
                interval: deps.interval
            )
        }

        
        static func countdownClosure(_ countdownList: [Double]) -> CountdownPublisherClosure {
            return { _ in countdownList.publisher.eraseToAnyPublisher() }
        }
        
//        static func countdownPublishedListComplete(_ countdownList: [Double]) -> [Double] {
//            return wrapCountdownList(countdownList, initVal: Countdown.initialCountdownTime, endMarker: CountdownTests.markEndOfCountdown)
//        }
    }
}
