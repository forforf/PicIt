//

import XCTest

@testable import PicIt

class CountdownTests: XCTestCase {
    
    private var countdown: Countdown!
    
    override func setUpWithError() throws {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        countdown = Countdown()
    }
        
    func testInstanceCreatedInReadyState() throws {
        XCTAssertEqual(countdown.state, .ready)
    }
}
