
import Foundation

public final class YXTLoggingInterceptor: YXTInterceptor {
    let level: YXTLogLevel
    let sampler: () -> Bool
    public init(_ level: YXTLogLevel = .info, sampler: @escaping () -> Bool = { true }) {
        self.level = level; self.sampler = sampler
    }
    public func willSend(context: inout YXTRequestContext) {
        guard level != .off, sampler() else { return }
        let req = context.request
        YXTLogger.log(.info, "➡️ [Attempt: \(context.attempt)] \(req.httpMethod ?? "?") \(req.url?.absoluteString ?? "?")\nHeaders: \(req.allHTTPHeaderFields ?? [:])")
        if let body = req.httpBody, let text = String(data: body, encoding: .utf8), level == .debug {
            YXTLogger.log(.debug, "Body: \(text)")
        }
    }
    public func didReceive(context: YXTResponseContext) {
        guard level != .off, sampler() else { return }
        let code = (context.response as? HTTPURLResponse)?.statusCode ?? -1
        YXTLogger.log(.info, "⬅️ [Code: \(code)] URL: \(context.request.url?.absoluteString ?? "?"), Size: \((context.data ?? Data()).count) bytes, Attempt: \(context.attempt)")
    }
}
