
import Foundation
import Security

public protocol YXTTokenStore: AnyObject {
    func read() -> String?
    func write(_ token: String?)
}

public final class YXTInMemoryTokenStore: YXTTokenStore {
    private var token: String?
    private let queue = DispatchQueue(label: "yxt.token.store", attributes: .concurrent)
    public init() {}
    public func read() -> String? { queue.sync { token } }
    public func write(_ token: String?) { queue.async(flags: .barrier) { self.token = token } }
}

// 轻量 Keychain 存储（可选）
public final class YXTKeychainTokenStore: YXTTokenStore {
    private let service: String
    private let account: String
    public init(service: String = "YXTNetworking", account: String = "auth.token") {
        self.service = service; self.account = account
    }
    public func read() -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    public func write(_ token: String?) {
        let data = token?.data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        SecItemAdd(attrs as CFDictionary, nil)
    }
}
