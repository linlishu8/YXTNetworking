
import Foundation
import Network

public final class YXTReachability {
    public static let shared = YXTReachability()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "yxt.reachability")
    private(set) public var isReachable: Bool = true
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isReachable = (path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }
}
