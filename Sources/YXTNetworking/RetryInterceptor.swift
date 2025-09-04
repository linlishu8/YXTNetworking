
import Foundation

public final class YXTRetryInterceptor: YXTInterceptor {
    let maxAttempts: Int
    let backoff: (Int) -> TimeInterval
    let reachability: () -> Bool
    public init(maxAttempts: Int, backoff: @escaping (Int) -> TimeInterval, reachability: @escaping () -> Bool) {
        self.maxAttempts = maxAttempts; self.backoff = backoff; self.reachability = reachability
    }
    public func shouldRetry(context: YXTResponseContext, maxAttempts: Int) -> (retry: Bool, delay: TimeInterval) {
        let attempt = context.attempt
        guard attempt < self.maxAttempts else { return (false, 0) }
        // 网络不可达或 5xx/超时/暂时性错误时重试
        if let http = context.response as? HTTPURLResponse, (500...599).contains(http.statusCode) {
            return (true, backoff(attempt))
        }
        if (context.error as NSError?)?.code == NSURLErrorTimedOut {
            return (true, backoff(attempt))
        }
        if !reachability() { return (true, backoff(attempt)) }
        return (false, 0)
    }
}
