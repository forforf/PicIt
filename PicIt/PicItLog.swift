//

import Foundation
import os.log

struct PicItLog {
    public struct Defaults {
        public static let subsystem = Bundle.main.bundleIdentifier ?? "PicItLog"
        public static let category = "PicItLog"
        public static let isPrivate = false
    }

    let logger: Logger
    
    public init(subsystem: String = Defaults.subsystem, category: String = Defaults.category) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }
}

struct PicItSelfLog<T> {
    static func get() -> Logger {
        let logName = String(describing: T.self as Any)
        return Logger(subsystem: PicItLog.Defaults.subsystem, category: logName)
    }
}
