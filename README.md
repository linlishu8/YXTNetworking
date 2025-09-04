
# YXTNetworking (iOS 14+)

一个从零开始设计的、可长期维护扩展的网络库，基于 **URLSession**，具备 CocoaPods 与 SwiftPM 双支持。

## 特性
- `RequestTarget` 协议：接口即类型，强约束、易测试
- 拦截器管线 `YXTInterceptor`：可插拔：日志、重试、鉴权、埋点、Mock
- 401 自动刷新 Token（串行刷新 + 重放等待请求）
- 指数退避重试（带上限 & 网络可达性感知）
- `Decodable` 泛型解析 / Data / String 三种响应映射
- `async/await`（iOS 15+）与 `Combine`（iOS 13+）包装
- Multipart 上传、断点续传下载
- 可插拔 TokenStore（内存 / 钥匙串）
- 结构化日志，采样与级别控制
- 线程安全，零第三方依赖

## 安装
### Swift Package Manager
File → Add Packages… → 输入仓库地址，或 Add Local… 选择本仓库目录。

### CocoaPods
```
pod 'YXTNetworking', :git => 'https://github.com/example/YXTNetworking.git', :tag => '0.1.0'
```

## 快速开始
```swift
import YXTNetworking

let config = YXTNetworkConfig(baseURL: URL(string: "https://httpbin.org")!)
let tokenStore = YXTInMemoryTokenStore()

let client = YXTNetworkClient(
    config: config,
    tokenStore: tokenStore,
    authenticator: YXTAuthenticator { oldToken, completion in
        // 调你的刷新接口，完成后写回 tokenStore
        completion(.success(oldToken ?? ""))
    },
    interceptors: [YXTLoggingInterceptor(.info)]
)

struct GetIP: YXTRequestTarget {
    var path: String { "/ip" }
    var method: YXTHTTPMethod { .get }
    var requiresAuth: Bool { false }
}

client.request(GetIP(), as: YXTDecodableResponse<IPResp>.self) { result in
    print(result)
}

struct IPResp: Decodable { let origin: String }
```

更多示例见源码注释。
