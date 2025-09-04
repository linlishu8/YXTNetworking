
import Foundation

public struct YXTRequestContext {
    public let id: UUID
    public var request: URLRequest
    public var attempt: Int
    public let startTime: Date
    public init(request: URLRequest, attempt: Int = 0) {
        self.id = UUID()
        self.request = request
        self.attempt = attempt
        self.startTime = Date()
    }
}

public struct YXTResponseContext {
    public let request: URLRequest
    public let data: Data?
    public let response: URLResponse?
    public let error: Error?
    public let attempt: Int
}

public protocol YXTInterceptor {
    func willSend(context: inout YXTRequestContext)
    func didReceive(context: YXTResponseContext)
    func shouldRetry(context: YXTResponseContext, maxAttempts: Int) -> (retry: Bool, delay: TimeInterval)
}

public extension YXTInterceptor {
    func willSend(context: inout YXTRequestContext) {}
    func didReceive(context: YXTResponseContext) {}
    func shouldRetry(context: YXTResponseContext, maxAttempts: Int) -> (retry: Bool, delay: TimeInterval) { (false, 0) }
}
