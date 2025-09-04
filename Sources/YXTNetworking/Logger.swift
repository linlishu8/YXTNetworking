
import Foundation

public enum YXTLogLevel: Int { case off = 0, error = 1, info = 2, debug = 3 }

public struct YXTLogger {
    public static func log(_ level: YXTLogLevel, _ msg: @autoclosure () -> String) {
        #if DEBUG
        print("[YXTNetworking][\(level)] " + msg())
        #else
        if level.rawValue <= YXTLogLevel.error.rawValue { print("[YXTNetworking][Error] " + msg()) }
        #endif
    }
}
