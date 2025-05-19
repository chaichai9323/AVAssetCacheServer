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
    
    public typealias CacheResult = Result<URL, Error>
    
    private static var completeHandle: ((CacheResult) -> Void)?
}

/// 边下边播
extension AVAssetCacheServer {
    
    public static func cancelCache() {
        completeHandle = nil
        SJMediaCacheServer.shared().cancelAllPrefetchTasks()
    }
    
    public static func cache(
        url: URL,
        progress: ((Float) -> Void)?,
        completion: ((CacheResult) -> Void)?
    ) {
        completeHandle = completion
        SJMediaCacheServer.shared().prefetch(
            with: url,
            prefetchFileCount: 1,
            progress: progress
        ) { err in
            if let e = err {
                AVAssetCacheServer.completeHandle?(.failure(e))
            } else if let res = AVAssetCacheServer.redirect(url: url) {
                AVAssetCacheServer.completeHandle?(.success(res))
            } else {
                AVAssetCacheServer.completeHandle?(
                    .failure(AVAssetCacheError.invalidURL)
                )
            }
        }
    }
    
    /// Convert the original URL to a proxy URL
    private static func redirect(url: URL) -> URL? {
        return SJMediaCacheServer.shared().proxyURL(
            from: url
        )
    }
}
