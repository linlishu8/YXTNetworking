
import Foundation
#if canImport(Combine)
import Combine
#endif

public extension YXTNetworkClient {
    #if canImport(Combine)
    func publisher<R: YXTResponseType>(_ target: YXTRequestTarget, as: R.Type) -> AnyPublisher<R.Output, YXTNetworkError> {
        Future { promise in
            _ = self.request(target, as: R.self) { result in
                promise(result)
            }
        }.eraseToAnyPublisher()
    }
    #endif
}
