
import Foundation

public enum YXTNetworkError: Error, CustomStringConvertible {
    case invalidURL
    case encodingFailed
    case transport(Error)
    case server(statusCode: Int, data: Data?)
    case decoding(Error)
    case cancelled
    case tokenRefreshFailed
    case unknown
    
    public var description: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .encodingFailed: return "Encoding failed"
        case .transport(let e): return "Transport error: \(e.localizedDescription)"
        case .server(let c, _): return "Server error (\(c))"
        case .decoding(let e): return "Decoding failed: \(e.localizedDescription)"
        case .cancelled: return "Cancelled"
        case .tokenRefreshFailed: return "Token refresh failed"
        case .unknown: return "Unknown error"
        }
    }
}
