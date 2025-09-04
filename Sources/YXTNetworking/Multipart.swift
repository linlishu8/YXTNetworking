
import Foundation

public struct YXTMultipartPart {
    public var data: Data
    public var name: String
    public var fileName: String?
    public var mimeType: String?
    public init(data: Data, name: String, fileName: String? = nil, mimeType: String? = nil) {
        self.data = data; self.name = name; self.fileName = fileName; self.mimeType = mimeType
    }
}

struct YXTMultipartBuilder {
    let boundary: String
    func build(parts: [YXTMultipartPart], additional: [String: Any]?) -> Data {
        var body = Data()
        let sep = "--" + boundary + "\r\n"
        for p in parts {
            body.append(sep.data(using: .utf8)!)
            if let fn = p.fileName, let mt = p.mimeType {
                body.append("Content-Disposition: form-data; name=\"\(p.name)\"; filename=\"\(fn)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: \(mt)\r\n\r\n".data(using: .utf8)!)
            } else {
                body.append("Content-Disposition: form-data; name=\"\(p.name)\"\r\n\r\n".data(using: .utf8)!)
            }
            body.append(p.data)
            body.append("\r\n".data(using: .utf8)!)
        }
        if let add = additional {
            for (k,v) in add {
                body.append(sep.data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(k)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(v)".data(using: .utf8)!)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        body.append("--" + boundary + "--\r\n")
        return body
    }
}
