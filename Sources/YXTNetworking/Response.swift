
import Foundation

public protocol YXTResponseType {
    associatedtype Output
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> Output
}

public enum YXTRawDataResponse: YXTResponseType {
    public static func map(_ data: Data, _ response: HTTPURLResponse) throws -> Data { data }
    public typealias Output = Data
}

public enum YXTStringResponse: YXTResponseType {
    public static func map(_ data: Data, _ response: HTTPURLResponse) throws -> String {
        String(data: data, encoding: .utf8) ?? ""
    }
    public typealias Output = String
}

public struct YXTDecodableResponse<T: Decodable>: YXTResponseType {
    public static func map(_ data: Data, _ response: HTTPURLResponse) throws -> T {
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw YXTNetworkError.decoding(error) }
    }
    public typealias Output = T
}
