//
//  AVAssetCacheServer+download.swift
//  Pods
//
//  Created by chai chai on 2025/5/16.
//
import Foundation

extension AVAssetCacheServer {
    static func resumeDownload(
        exp: NSObjectProtocol?
    ) {
        guard let export = exp as? MCSExporterProtocol else {
            return
        }
        export.resume()
    }
    
    static func pauseDownload(
        exp: NSObjectProtocol?
    ) {
        guard let export = exp as? MCSExporterProtocol else {
            return
        }
        export.suspend()
    }
    
    static func cancelDownload(
        exp: NSObjectProtocol?
    ) {
        guard let export = exp as? MCSExporterProtocol else {
            return
        }
        export.cancel()
    }
    
    static func deleteDownload(
        url: URL
    ) {
        SJMediaCacheServer.shared().removeExportAsset(
            with: url
        )
        
        SJMediaCacheServer.shared().removeCache(
            for: url
        )
    }
    
    static func download(
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
