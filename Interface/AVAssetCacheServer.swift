//
//  AVAssetCacheServer.swift
//  AVAssetCacheServer
//
//  Created by chai chai on 2025/5/12.
//

import Foundation
@_implementationOnly import AVAssetCacheServer.Internal

public enum AVAssetCacheError: Error {
    case invalidURL
}

public final class AVAssetCacheServer {
    /// 是否允许打印日志
    public static var logEnabled: Bool {
        get {
            SJMediaCacheServer.shared().isEnabledConsoleLog
        }
        
        set {
            SJMediaCacheServer.shared().isEnabledConsoleLog = newValue
        }
    }
    
    /// 最大缓存过期时间
    public static var cacheMaxDiskAge: TimeInterval {
        get {
            return SJMediaCacheServer.shared().cacheMaxDiskAge
        }
        set {
            SJMediaCacheServer.shared().cacheMaxDiskAge = newValue
        }
    }
}

/// 边下边播
public extension AVAssetCacheServer {
    
    static func cache(
        url: URL,
        progress: ((Float) -> Void)?
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { config in
            prefetch(
                url: url,
                progress: progress
            ) { err in
                if let e = err {
                    config.resume(throwing: e)
                } else {
                    if let res = redirect(url: url) {
                        config.resume(returning: res)
                    } else {
                        config.resume(throwing: AVAssetCacheError.invalidURL)
                    }
                }
            }
        }
    }
}

// MARK: - 预加载
extension AVAssetCacheServer {
    private static func prefetch(
        url: URL,
        progress: ((Float) -> Void)?,
        completion: ((Error?) -> Void)?
    ) {
        SJMediaCacheServer.shared().prefetch(
            with: url,
            prefetchFileCount: 1,
            progress: progress,
            completion: completion
        )
    }
    
    /// Convert the original URL to a proxy URL
    private static func redirect(url: URL) -> URL? {
        return SJMediaCacheServer.shared().proxyURL(
            from: url
        )
    }
}
