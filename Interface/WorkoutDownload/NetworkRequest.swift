//
//  NetworkRequest.swift
//  Pods
//
//  Created by chai chai on 2025/5/14.
//

import Foundation
import Alamofire

struct NetworkRequest {
    enum ErrorCode: Error {
        case unknown
        case fileDownloadError
        case videoDownloadError
    }
    
    private struct RespSoundModel: Codable {
        let code: Int

        let message: String?

        let data: [SoundModel]
    }
    
    private struct SoundModel: Codable, DownloadTaskConvert {

        let id: Int
        let soundName: String
        let soundUrl: String
        let soundUrlName: String
        
        var remoteURL: String {
            return soundUrl
        }

        var resSuffix: String {
            return (soundUrlName as NSString).pathExtension
        }
    }
    
    private struct AudioModel: Codable, DownloadTaskConvert {
        let url: String
        let name: String
        
        var remoteURL: String {
            return url
        }

        var resSuffix: String {
            return (name as NSString).pathExtension
        }
        
    }
    
    private static func request(
        url: String
    ) async throws -> Data {
        try await withCheckedThrowingContinuation { config in
            AF.request(url).response { resp in
                if let data = resp.data,
                   resp.error == nil {
                    config.resume(returning: data)
                } else {
                    if let e = resp.error {
                        config.resume(throwing: e)
                    } else {
                        config.resume(throwing: ErrorCode.unknown)
                    }
                }
            }
        }
    }
    
    private static func cachedJson<T: Decodable>(
        _ type: T.Type,
        path: String
    ) -> T? {
        guard FileManager.default.fileExists(
            atPath: path
        ), let data = try? Data(
            contentsOf: URL(fileURLWithPath: path)
        ), let res = try? JSONDecoder().decode(
            type,
            from: data
        ) else {
            return nil
        }
        return res
    }
    
    private static var dir: String {
        AVAssetCacheServer.ServerConfig.offlineDir
    }
    
    @MainActor
    static func request(
        audioJson url: String,
        id: String
    ) async throws -> [DownloadTaskConvert] {
        let path = dir + "/\(id)_audio.json"
        if let cache = cachedJson(
            [AudioModel].self,
            path: path
        ) {
            return cache
        }
        let res = try await request(url: url)
        try res.write(to: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(
            [AudioModel].self,
            from: res
        )
    }
    
    @MainActor
    static func request(
        sound url: String,
        id: String
    ) async throws -> [DownloadTaskConvert] {
        let path = dir + "/\(id)_sound.json"
        if let cache = cachedJson(
            RespSoundModel.self,
            path: path
        ) {
            return cache.data
        }
        let res = try await request(
            url: AVAssetCacheServer.ServerConfig.generate(sound: url)
        )
        try res.write(to: URL(fileURLWithPath: path))
        let item = try JSONDecoder().decode(
            RespSoundModel.self,
            from: res
        )
        return item.data
    }
    
    @MainActor
    static func request(
        welcomSound url: String,
        id: String
    ) async throws -> [DownloadTaskConvert] {
        let path = dir + "/\(id)_welcomSound.json"
        if let cache = cachedJson(
            RespSoundModel.self,
            path: path
        ) {
            return cache.data
        }
        let res = try await request(
            url: AVAssetCacheServer.ServerConfig.generate(sound: url)
        )
        try res.write(to: URL(fileURLWithPath: path))
        let item = try JSONDecoder().decode(
            RespSoundModel.self,
            from: res
        )
        return item.data
    }
    
    @MainActor
    static func request(
        completeSound url: String,
        id: String
    ) async throws -> [DownloadTaskConvert] {
        let path = dir + "/\(id)_completeSound.json"
        if let cache = cachedJson(
            RespSoundModel.self,
            path: path
        ) {
            return cache.data
        }
        let res = try await request(
            url: AVAssetCacheServer.ServerConfig.generate(sound: url)
        )
        try res.write(to: URL(fileURLWithPath: path))
        let item = try JSONDecoder().decode(
            RespSoundModel.self,
            from: res
        )
        return item.data
    }
}
