
import Foundation

public struct YXTNetworkConfig {
    public var baseURL: URL
    public var defaultHeaders: [String: String]
    public var timeout: TimeInterval
    public var cachePolicy: URLRequest.CachePolicy
    public var maxRetryCount: Int
    public var retryBackoff: (Int) -> TimeInterval
    public var logLevel: YXTLogLevel
    public var logSampler: () -> Bool
    
    public init(
        baseURL: URL,
        defaultHeaders: [String: String] = [:],
        timeout: TimeInterval = 20,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        maxRetryCount: Int = 2,
        retryBackoff: @escaping (Int) -> TimeInterval = { attempt in pow(2.0, Double(attempt)) },
        logLevel: YXTLogLevel = .info,
        logSampler: @escaping () -> Bool = { true }
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeout = timeout
        self.cachePolicy = cachePolicy
        self.maxRetryCount = maxRetryCount
        self.retryBackoff = retryBackoff
        self.logLevel = logLevel
        self.logSampler = logSampler
    }
}
