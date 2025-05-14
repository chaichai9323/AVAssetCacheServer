//
//  WorkoutAsset.swift
//  Pods
//
//  Created by chai chai on 2025/5/14.
//
import Foundation

public protocol WorkoutAssetDownloadable {
    
    var assetModel: Codable { get }
    
    var assetUniqueId: String { get }
    
    var assetM3u8Url: String { get }
    var assetAudioJsonUrl: String { get }
    var assetSoundUrl: String? { get }
    var assetWelcomSoundUrl: String? { get }
    var assetCompleteSoundUrl: String? { get }
    
    var assetCoverUrl: String { get }
    var assetName: String { get }
    var assetSeconds: Double { get }
    var assetCalories: Double { get }
}

public struct WorkoutAsset: Codable, Equatable {
    
    public static func == (lhs: WorkoutAsset, rhs: WorkoutAsset) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id: String
    let videoUrl: String
    let audioJsonUrl: String
    let soundUrl: String?
    let welcomSoundUrl: String?
    let completeSoundUrl: String?
    let modelName: String
    var complete: Bool = false
    
    public let coverUrl: String
    public let name: String
    public let seconds: Double
    public let calories: Double
   
    init(asset: WorkoutAssetDownloadable) {
        self.modelName = "\(asset.assetUniqueId)_localModel.json"
        self.id = asset.assetUniqueId
        self.coverUrl = asset.assetCoverUrl
        self.name = asset.assetName
        self.seconds = asset.assetSeconds
        self.calories = asset.assetCalories
        self.videoUrl = asset.assetM3u8Url
        self.audioJsonUrl = asset.assetAudioJsonUrl
        self.soundUrl = asset.assetSoundUrl
        self.welcomSoundUrl = asset.assetWelcomSoundUrl
        self.completeSoundUrl = asset.assetCompleteSoundUrl
    }
}


public extension WorkoutAsset {
    
    var localModelPath: String {
        let dir = AVAssetCacheServer.ServerConfig.offlineDir
        return "/\(dir)/\(modelName)"
    }
    
    var isFinished: Bool {
        return complete
    }
}
