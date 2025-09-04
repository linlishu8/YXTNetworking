
import Foundation

public extension YXTNetworkClient {
    @available(iOS 15.0, *)
    func request<R: YXTResponseType>(_ target: YXTRequestTarget, as: R.Type) async -> Result<R.Output, YXTNetworkError> {
        await withCheckedContinuation { cont in
            _ = self.request(target, as: R.self) { res in cont.resume(returning: res) }
        }
    }
}
