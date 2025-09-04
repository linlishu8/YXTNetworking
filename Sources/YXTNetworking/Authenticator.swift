
import Foundation

public final class YXTAuthenticator {
    public typealias Refresh = (_ oldToken: String?, _ completion: @escaping (Result<String, Error>) -> Void) -> Void
    let refreshClosure: Refresh
    public init(refresh: @escaping Refresh) { self.refreshClosure = refresh }
    
    public func refresh(oldToken: String?, completion: @escaping (Result<String, Error>) -> Void) {
        refreshClosure(oldToken, completion)
    }
}
