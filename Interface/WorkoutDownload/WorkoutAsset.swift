//
//  WorkoutAsset.swift
//  Pods
//
//  Created by chai chai on 2025/5/14.
//
import Foundation

public protocol WorkoutAssetDownloadable {
    /// 模型数据，保证完全离线可用
    var assetModel: Codable { get }
    /// 模块标识，用于区分不同模块 例如: toppicks, popular ...
    var assetCategory: Int { get }
    /// 资源的唯一ID
    var assetUniqueId: String { get }
    /// video的链接
    var assetM3u8Url: String { get }
    /// audioJson的链接
    var assetAudioJsonUrl: String { get }
    /// 系统音的API请求地址，应该是104 program专属，其他App应该不涉及
    var assetSoundUrl: String? { get }
    /// welcom系统音的API请求地址
    /// 例如:  "lang=en&soundSource=female&soundSubType=Welcome&soundType=OOG104 Regular Fitness"
    var assetWelcomSoundUrl: String? { get }
    /// complete系统音的API请求地址
    /// 例如:  "lang=en&soundSource=female&soundSubType=Complete&soundType=OOG104 Regular Fitness"
    var assetCompleteSoundUrl: String? { get }
    /// 封面图链接
    var assetCoverUrl: String { get }
    /// 名字
    var assetName: String { get }
    /// 时长，单位是秒
    var assetSeconds: Double { get }
    /// 卡路里
    var assetCalories: Double { get }
}

extension WorkoutAssetDownloadable {
    @MainActor
    public var dl: WorkoutAsset? {
        return WorkoutAssetManager.shared.downloadMap[assetUniqueId]
    }
    /// 是否已经下载
    @MainActor
    public var isDownloaded: Bool {
        return dl?.isDownloaded == true
    }
}

//MARK: - Workout
public struct WorkoutAsset: Codable{
    
    let modelName: String
    let id: String
    let videoUrl: String
    let audioJsonUrl: String
    let soundUrl: String?
    let welcomSoundUrl: String?
    let completeSoundUrl: String?
    
    var complete: Bool = false
    
    public let coverUrl: String
    public let name: String
    public let seconds: Double
    public let calories: Double
    public let modelCategoay: Int
    
    init(asset: WorkoutAssetDownloadable) {
        self.modelName = "\(asset.assetUniqueId)_localModel.json"
        self.id = asset.assetUniqueId
        self.videoUrl = asset.assetM3u8Url
        self.audioJsonUrl = asset.assetAudioJsonUrl
        self.soundUrl = asset.assetSoundUrl
        self.welcomSoundUrl = asset.assetWelcomSoundUrl
        self.completeSoundUrl = asset.assetCompleteSoundUrl
        
        self.coverUrl = asset.assetCoverUrl
        self.name = asset.assetName
        self.seconds = asset.assetSeconds
        self.calories = asset.assetCalories
        self.modelCategoay = asset.assetCategory
    }
}

//MARK: - Public
extension WorkoutAsset: Equatable {
    
    public static func == (lhs: WorkoutAsset, rhs: WorkoutAsset) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// 是否下载
    public var isDownloaded: Bool {
        return complete
    }
    
    /// 获取离线的资源
    public func offlineAsset<T: Codable>(
        _ type: T.Type
    ) -> T? {
        guard isDownloaded,
            let data = try? Data(
                contentsOf: URL(fileURLWithPath: localModelPath)
            ) else {
            return nil
        }
        return try? JSONDecoder().decode(
            type,
            from: data
        )
    }
    
    /// 获取离线的音频列表
    public func offlineAudioModel<T: Codable>(
        _ type: T.Type
    ) -> [T]? {
        return getAudioSoundList(
            type,
            path: NetworkRequest.audioPath(id: id),
            hasWrapper: false
        )
    }
    
    /// 获取离线的系统音列表
    public func offlineSoundList<T: Codable>(
        _ type: T.Type
    ) -> [T]? {
        return getAudioSoundList(
            type,
            path: NetworkRequest.soundPath(id: id),
            hasWrapper: true
        )
    }
    
    /// 获取离线的 welcom系统音列表
    public func offlineWelcomSoundList<T: Codable>(
        _ type: T.Type
    ) -> [T]? {
        return getAudioSoundList(
            type,
            path: NetworkRequest.welcomSoundPath(id: id),
            hasWrapper: true
        )
    }
    
    /// 获取离线的complete系统音列表
    public func offlineCompleteSoundList<T: Codable>(
        _ type: T.Type
    ) -> [T]? {
        return getAudioSoundList(
            type,
            path: NetworkRequest.completeSoundPath(id: id),
            hasWrapper: true
        )
    }
}

//MARK: - Private
extension WorkoutAsset {
    private static let parentDir: String = {
        AVAssetCacheServer.ServerConfig.offlineDir
    }()
    
    internal var localModelPath: String {
        return Self.parentDir + "/" + modelName
    }
    
    private func getAudioSoundList<T: Codable>(
        _ type: T.Type,
        path: String,
        hasWrapper: Bool
    ) -> [T]? {
        guard isDownloaded,
            let data = try? Data(
                contentsOf: URL(fileURLWithPath: path)
            ) else {
            return nil
        }
        if hasWrapper {
            return try? JSONDecoder().decode(
                NetworkRequest.WrapperListModel<T>.self,
                from: data
            ).data
        } else {
            return try? JSONDecoder().decode(
                [T].self,
                from: data
            )
        }
    }
}
