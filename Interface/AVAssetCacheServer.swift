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

@MainActor
public class AVAssetCacheServer {
    
    public static let shared = AVAssetCacheServer()
    
    init() {
#if DEBUG
        SJMediaCacheServer.shared().isEnabledConsoleLog = true
        SJMediaCacheServer.shared().removeAllCaches()
#endif
    }
    
    
}

/// 边下边播
public extension AVAssetCacheServer {
    /// 最大缓存过期时间
    var cacheMaxDiskAge: TimeInterval {
        get {
            return SJMediaCacheServer.shared().cacheMaxDiskAge
        }
        set {
            SJMediaCacheServer.shared().cacheMaxDiskAge = newValue
        }
    }
    
    func startRedirect(
        url: URL,
        progress: ((Float) -> Void)?
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { config in
            Self.prefetch(
                url: url,
                progress: progress
            ) { err in
                if let e = err {
                    config.resume(throwing: e)
                } else {
                    if let res = Self.redirect(url: url) {
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

extension AVAssetCacheServer {
    internal static func resumeDownload(
        exp: NSObjectProtocol?
    ) {
        guard let export = exp as? MCSExporterProtocol else {
            return
        }
        export.resume()
    }
    
    internal static func pauseDownload(
        exp: NSObjectProtocol?
    ) {
        guard let export = exp as? MCSExporterProtocol else {
            return
        }
        export.suspend()
    }
    
    internal static func cancelDownload(
        exp: NSObjectProtocol?
    ) {
        guard let export = exp as? MCSExporterProtocol else {
            return
        }
        export.cancel()
    }
    
    internal static func download(
        url: URL,
        progress: ((Float) -> Void)?,
        completion: ((Bool) -> Void)?
    ) -> NSObjectProtocol? {
        let exp = SJMediaCacheServer.shared().exportAsset(
            with: url,
            shouldResume: true
        )
        if exp?.status == .finished {
            completion?(true)
            return exp
        }
        exp?.progressDidChangeExecuteBlock = { p in
            progress?(p.progress)
        }
        exp?.statusDidChangeExecuteBlock = { p in
            if p.status == .failed {
                completion?(false)
            } else if p.status == .finished {
                completion?(true)
            }
        }
        return exp
    }
}
