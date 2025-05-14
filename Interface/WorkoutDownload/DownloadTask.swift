//
//  DownloadTask.swift
//  Pods
//
//  Created by chai chai on 2025/5/14.
//
import Foundation
import Alamofire

protocol DownloadTaskConvert {
    var remoteURL: String { get }
    var resSuffix: String { get }
}

extension DownloadTaskConvert {
    var builer: DownloadTask.Builder? {
        let name = remoteURL.urlPathMD5
        let dir = AVAssetCacheServer.ServerConfig.offlineDir
        let path = dir + "/\(name).\(resSuffix)"
        if FileManager.default.fileExists(
            atPath: path
        ) {
            return nil
        }        
        return .init(remote: remoteURL, local: path)
    }
}


class DownloadTask {
    
    struct Builder: Equatable, Hashable {
        let remote: String
        let local: String
        
        var task: DownloadTask {
            return .init(url: remote, localPath: local)
        }
    }
    
    /// 文件url地址
    let url: String
    
    /// 保存文件的本地路径
    let localPath: String
    
    private var request: DownloadRequest?
  
    init(url: String, localPath: String) {
        self.url = url
        self.localPath = localPath
    }
    
    deinit {
        request?.cancel()
#if DEBUG
        print("DownloadTask dealloc")
#endif
    }
    
    private func download(
        progress: ((Double) -> Void)?,
        completion: ((Error?) -> Void)?
    ) {
        let dst = URL(fileURLWithPath: localPath)
        self.request = AF.download(
            url,
            requestModifier: { req in
                req.timeoutInterval = 15.0
            },
            to: { _, _ in
                return (dst, [
                    .removePreviousFile,
                    .createIntermediateDirectories
                ])
            }
        )
        .validate()
        .downloadProgress { pro in
            progress?(pro.fractionCompleted)
        }
        .response { resp in
            if let err = resp.error {
                try? FileManager.default.removeItem(
                    at: dst
                )
                completion?(err)
            } else {
                progress?(1.0)
                completion?(nil)
            }
        }
    }

    @discardableResult
    func start(
        progress: ((Double) -> Void)?
    ) async throws -> Bool {
        return try await withCheckedThrowingContinuation { config in
            download(
                progress: progress
            ) { err in
                if let e = err {
                    config.resume(throwing: e)
                } else {
                    config.resume(returning: true)
                }
            }
        }
    }
}
