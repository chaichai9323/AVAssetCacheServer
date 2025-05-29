//
//  AVAssetCacheServer.swift
//  AVAssetCacheServer
//
//  Created by chai chai on 2025/5/12.
//

import Foundation

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
    
    public static func reloadServer(
        url: URL
    ) -> URL? {
        SJMediaCacheServer.shared().stop()
        return redirect(url: url)
    }
    
    public static func cancelCache() {
        completeHandle = nil
        SJMediaCacheServer.shared().cancelAllPrefetchTasks()
        SJMediaCacheServer.shared().stop()
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
            let res: CacheResult
            if err == nil,
               let local = AVAssetCacheServer.redirect(
                url: url
               ) {
                res = .success(local)
            } else {
                res = .failure(err ?? AVAssetCacheError.invalidURL)
            }
            AVAssetCacheServer.completeHandle?(res)
        }
    }
    
    /// Convert the original URL to a proxy URL
    private static func redirect(url: URL) -> URL? {
        return SJMediaCacheServer.shared().proxyURL(
            from: url
        )
    }
}
