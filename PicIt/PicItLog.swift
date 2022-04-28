//

import Foundation
import os.log

/*
    Extending Logger so we can format the messages
 */

struct PicItLog {
    public static let subsystem = Bundle.main.bundleIdentifier ?? "PicItLog"
    public static let category = "PicItLog"
    public static let isPrivate = false
    
    enum Prefix: String {
        case debug = "🔵[debug] "
        case info = "🟢[info] "
        case notice = "🟡[notice] "
        case warning = "🟠[warning] "
        case error = "🔴[error] "
    }
    
    private func formatMessage(_ message: String, prefix: String) -> String {
        return "\(prefix)\(message)"
    }
    
    func debug(_ message: String) {
        logger.debug("\(formatMessage(message, prefix: Prefix.debug.rawValue))")
    }
    
    func info(_ message: String) {
        logger.info("\(formatMessage(message, prefix: Prefix.info.rawValue))")
    }
    
    func notice(_ message: String) {
        logger.notice("\(formatMessage(message, prefix: Prefix.notice.rawValue))")
    }
    
    func warning(_ message: String) {
        logger.warning("\(formatMessage(message, prefix: Prefix.warning.rawValue))")
    }
    
    func error(_ message: String) {
        logger.error("\(formatMessage(message, prefix: Prefix.error.rawValue))")
    }

    let logger: Logger

    public init(subsystem: String = subsystem, category: String = category) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }
}

struct PicItSelfLog<T> {
    static func get() -> PicItLog {
        let logName = String(describing: T.self as Any)
        return PicItLog(category: logName)
    }
}
