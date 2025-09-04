
import Foundation

public enum YXTHTTPMethod: String { case GET, POST, PUT, PATCH, DELETE, HEAD }

public enum YXTParameterEncoding {
    case json        // JSON body
    case query       // URL query
    case formURLEncoded  // x-www-form-urlencoded
}

public protocol YXTRequestTarget {
    var path: String { get }
    var method: YXTHTTPMethod { get }
    var parameters: [String: Any]? { get }
    var headers: [String: String]? { get }
    var encoding: YXTParameterEncoding { get }
    var requiresAuth: Bool { get }
    var timeout: TimeInterval? { get }
    var cachePolicy: URLRequest.CachePolicy? { get }
}

public extension YXTRequestTarget {
    var parameters: [String: Any]? { nil }
    var headers: [String: String]? { nil }
    var encoding: YXTParameterEncoding { .json }
    var requiresAuth: Bool { true }
    var timeout: TimeInterval? { nil }
    var cachePolicy: URLRequest.CachePolicy? { nil }
}
