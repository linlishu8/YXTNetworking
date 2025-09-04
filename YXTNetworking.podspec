
Pod::Spec.new do |s|
  s.name         = "YXTNetworking"
  s.version      = "0.1.1"  # 必须与 Git tag 保持一致
  s.summary      = "A modern, extensible networking library for iOS 14+."
  s.description  = <<-DESC
URLSession-based networking:
- RequestTarget protocol
- Interceptor pipeline (logging/retry/auth/custom)
- Token refresh with pending request replay
- Exponential backoff retry
- Multipart upload & file download
- Reachability (NWPathMonitor)
- Swift Concurrency & Combine
- Decodable mapping & typed errors
DESC

  s.homepage     = "https://github.com/linlishu8/YXTNetworking"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "linlishu8" => "linlishu8@163.com" }

  s.ios.deployment_target = "14.0"
  s.swift_versions = ["5.7", "5.8", "5.9", "5.10"]

  # 源代码位置（必须指向可访问的 Git 仓库 + 正确的 tag）
  s.source       = { :git => "https://github.com/linlishu8/YXTNetworking.git", :tag => s.version.to_s }
  s.source_files = "Sources/YXTNetworking/**/*.{swift}"

  s.requires_arc = true

  # 代码中使用了 Security / Network，务必显式链接
  s.frameworks = "Security", "Network"

  # 可选：如希望作为静态 framework
  # s.static_framework = true
end
