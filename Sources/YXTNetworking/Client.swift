
import Foundation

public final class YXTNetworkClient {
    public typealias Completion<T> = (Result<T, YXTNetworkError>) -> Void
    
    private let urlSession: URLSession
    private let config: YXTNetworkConfig
    private weak var tokenStore: YXTTokenStore?
    private let authenticator: YXTAuthenticator?
    private var interceptors: [YXTInterceptor]
    
    // 刷新锁 & 挂起请求队列
    private let lock = NSLock()
    private var isRefreshing = false
    private var pendings: [(String?) -> Void] = []
    
    public init(
        config: YXTNetworkConfig,
        tokenStore: YXTTokenStore? = nil,
        authenticator: YXTAuthenticator? = nil,
        interceptors: [YXTInterceptor] = [],
        session: URLSession? = nil
    ) {
        self.config = config
        self.tokenStore = tokenStore
        self.authenticator = authenticator
        self.interceptors = interceptors
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = config.timeout
        cfg.requestCachePolicy = config.cachePolicy
        cfg.httpAdditionalHeaders = config.defaultHeaders
        self.urlSession = session ?? URLSession(configuration: cfg)
        // 默认重试器和日志
        if !interceptors.contains(where: { $0 is YXTRetryInterceptor }) {
            self.interceptors.append(YXTRetryInterceptor(maxAttempts: config.maxRetryCount, backoff: config.retryBackoff, reachability: { YXTReachability.shared.isReachable }))
        }
        if !interceptors.contains(where: { $0 is YXTLoggingInterceptor }) {
            self.interceptors.append(YXTLoggingInterceptor(config.logLevel, sampler: config.logSampler))
        }
    }
    
    // MARK: - Public APIs
    
    @discardableResult
    public func request<R: YXTResponseType>(_ target: YXTRequestTarget, as: R.Type, completion: @escaping Completion<R.Output>) -> URLSessionDataTask? {
        do {
            let req = try buildRequest(target)
            return perform(req, attempt: 0, mapTo: R.self, completion: completion)
        } catch let e as YXTNetworkError {
            completion(.failure(e)); return nil
        } catch {
            completion(.failure(.unknown)); return nil
        }
    }
    
    // Multipart 上传（简单实现）
    @discardableResult
    public func upload<R: YXTResponseType>(_ target: YXTRequestTarget, multipart: [YXTMultipartPart], as: R.Type, completion: @escaping Completion<R.Output>) -> URLSessionDataTask? {
        do {
            var req = try buildRequest(target)
            let boundary = "yxt.boundary.\(UUID().uuidString)"
            req.httpMethod = "POST"
            req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            req.httpBody = YXTMultipartBuilder(boundary: boundary).build(parts: multipart, additional: target.parameters)
            return perform(req, attempt: 0, mapTo: R.self, completion: completion)
        } catch let e as YXTNetworkError {
            completion(.failure(e)); return nil
        } catch {
            completion(.failure(.unknown)); return nil
        }
    }
    
    // 简单下载至内存（可扩展为写文件与断点续传）
    @discardableResult
    public func download(_ target: YXTRequestTarget, completion: @escaping Completion<Data>) -> URLSessionDataTask? {
        struct Raw: YXTResponseType { static func map(_ data: Data, _ response: HTTPURLResponse) throws -> Data { data } ; typealias Output = Data }
        return request(target, as: Raw.self, completion: completion)
    }
    
    // MARK: - Build Request
    
    func buildRequest(_ target: YXTRequestTarget) throws -> URLRequest {
        guard let url = URL(string: target.path, relativeTo: config.baseURL) else { throw YXTNetworkError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = target.method.rawValue
        req.timeoutInterval = target.timeout ?? config.timeout
        req.cachePolicy = target.cachePolicy ?? config.cachePolicy
        
        var headers = config.defaultHeaders
        if let custom = target.headers { for (k,v) in custom { headers[k] = v } }
        if target.requiresAuth, let t = tokenStore?.read(), !t.isEmpty { headers["Authorization"] = "Bearer " + t }
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
        
        if let params = target.parameters {
            switch target.encoding {
            case .json:
                req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                guard JSONSerialization.isValidJSONObject(params) else { throw YXTNetworkError.encodingFailed }
                req.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            case .query:
                if var comps = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                    comps.queryItems = params.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
                    req.url = comps.url
                }
            case .formURLEncoded:
                req.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                let body = params.map { "\($0.key)=\(String(describing: $0.value))" }.joined(separator: "&")
                req.httpBody = body.data(using: .utf8)
            }
        }
        return req
    }
    
    // MARK: - Core Perform
    
    private func perform<R: YXTResponseType>(_ req: URLRequest, attempt: Int, mapTo: R.Type, completion: @escaping Completion<R.Output>) -> URLSessionDataTask {
        var ctx = YXTRequestContext(request: req, attempt: attempt)
        interceptors.forEach { $0.willSend(context: &ctx) }
        
        let task = urlSession.dataTask(with: ctx.request) { data, response, error in
            let http = response as? HTTPURLResponse
            let ctxResp = YXTResponseContext(request: ctx.request, data: data, response: response, error: error, attempt: attempt)
            self.interceptors.forEach { $0.didReceive(context: ctxResp) }
            
            // 401 处理（刷新 + 重放）
            if let status = http?.statusCode, (status == 401 || status == 403), let auth = self.authenticator {
                self.enqueuePending { _ in
                    // 重放
                    _ = self.perform(ctx.request, attempt: attempt + 1, mapTo: mapTo, completion: completion)
                }
                self.tryRefreshIfNeeded(auth) { ok in
                    if !ok { completion(.failure(.tokenRefreshFailed)) }
                }
                return
            }
            
            // 非 2xx
            if let status = http?.statusCode, !(200..<300).contains(status) {
                // 重试判定
                if self.shouldRetry(ctxResp, currentAttempt: attempt) {
                    let delay = self.retryDelay(for: ctxResp, currentAttempt: attempt)
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        _ = self.perform(ctx.request, attempt: attempt + 1, mapTo: mapTo, completion: completion)
                    }
                    return
                }
                completion(.failure(.server(statusCode: status, data: data)))
                return
            }
            
            if let e = error as NSError? {
                if e.code == NSURLErrorCancelled { completion(.failure(.cancelled)) ; return }
                // 对可重试错误做重试
                if self.shouldRetry(ctxResp, currentAttempt: attempt) {
                    let delay = self.retryDelay(for: ctxResp, currentAttempt: attempt)
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        _ = self.perform(ctx.request, attempt: attempt + 1, mapTo: mapTo, completion: completion)
                    }
                    return
                }
                completion(.failure(.transport(e)))
                return
            }
            
            guard let d = data, let h = http else { completion(.failure(.unknown)); return }
            do {
                let mapped = try R.map(d, h)
                completion(.success(mapped))
            } catch let ne as YXTNetworkError {
                completion(.failure(ne))
            } catch {
                completion(.failure(.decoding(error)))
            }
        }
        task.resume()
        return task
    }
    
    private func shouldRetry(_ ctx: YXTResponseContext, currentAttempt: Int) -> Bool {
        for itc in interceptors {
            let r = itc.shouldRetry(context: ctx, maxAttempts: config.maxRetryCount)
            if r.retry { return true }
        }
        return false
    }
    
    private func retryDelay(for ctx: YXTResponseContext, currentAttempt: Int) -> TimeInterval {
        for itc in interceptors {
            let r = itc.shouldRetry(context: ctx, maxAttempts: config.maxRetryCount)
            if r.retry { return r.delay }
        }
        return 0
    }
    
    // MARK: - Token Refresh
    
    private func enqueuePending(_ block: @escaping (String?) -> Void) {
        lock.lock(); defer { lock.unlock() }
        pendings.append(block)
    }
    
    private func tryRefreshIfNeeded(_ auth: YXTAuthenticator, completion: @escaping (Bool) -> Void) {
        lock.lock()
        if isRefreshing { lock.unlock(); return } // 已在刷新中，等待
        isRefreshing = true
        let old = tokenStore?.read()
        lock.unlock()
        
        auth.refresh(oldToken: old) { result in
            switch result {
            case .success(let newToken):
                self.tokenStore?.write(newToken)
                self.lock.lock()
                let blocks = self.pendings
                self.pendings.removeAll()
                self.isRefreshing = false
                self.lock.unlock()
                blocks.forEach { $0(newToken) }
                completion(true)
            case .failure:
                self.lock.lock()
                self.pendings.removeAll()
                self.isRefreshing = false
                self.lock.unlock()
                completion(false)
            }
        }
    }
}
