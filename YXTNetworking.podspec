
Pod::Spec.new do |s|
  s.name         = "YXTNetworking"
  s.version      = "0.1.0"
  s.summary      = "A modern, extensible, production-ready networking library for iOS 14+."
  s.description  = <<-DESC
A URLSession-based networking layer featuring:
- RequestTarget protocol
- Interceptor pipeline (logging/retry/auth/custom)
- Token refresh with pending request replay
- Exponential backoff retry
- Multipart upload & file download
- Reachability (NWPathMonitor)
- Swift Concurrency (async/await) & Combine wrappers
- Decodable mapping & typed errors
DESC
  s.homepage     = "https://github.com/linlishu8/YXTNetworking"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "YXT" => "ios@example.com" }
  s.platform     = :ios, "14.0"
  s.swift_versions = ["5.9"]
  s.source       = { :git => "https://github.com/linlishu8/YXTNetworking", :tag => s.version.to_s }
  s.source_files  = "Sources/YXTNetworking/**/*.{swift}"
  s.requires_arc  = true
end
