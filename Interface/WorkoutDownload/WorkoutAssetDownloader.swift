//
//  WorkoutAssetDownloader.swift
//  Pods
//
//  Created by chai chai on 2025/5/14.
//

import Foundation
import Alamofire

public enum WorkoutAssetDownloadState {
    case notDownload
    case downloading(p: Double)
    case download(error: Error)
    case downloaded
}

@MainActor
class WorkoutAssetDownloader {
    var id: String {
        return asset.id
    }
    
    private let asset: WorkoutAsset
    
    private var queue: [DownloadTask] = []
    
    private var audioProgress: Double = 0.0 {
        didSet {
            state = .downloading(p: progress)
        }
    }
    
    private var videoProgress: Double = 0.0 {
        didSet {
            state = .downloading(p: progress)
        }
    }
    
    private var audioFinish: Bool = false {
        didSet {
            if audioFinish, videoFinish {
                state = .downloaded
            }
        }
    }
    
    private var videoFinish: Bool = false {
        didSet {
            if audioFinish, videoFinish {
                state = .downloaded
            }
        }
    }
    
    private var progress: Double {
        let v = videoProgress * 0.5
        let a = audioProgress * 0.5
        return v + a
    }
    
    @Published
    var state: WorkoutAssetDownloadState = .notDownload
    
    private var audioTask: Task<(), Never>?
    private var videoTask: NSObjectProtocol?
    
    init(asset: WorkoutAsset) {
        self.asset = asset
    }
    
    func pause() {
        audioTask?.cancel()
        AVAssetCacheServer.pauseDownload(
            exp: videoTask
        )
    }
    
    func start() {
        guard let videoUrl = URL(
            string: asset.videoUrl
        ) else {
            state = .download(
                error: NetworkRequest.ErrorCode.videoDownloadError
            )
            return
        }
        
        audioTask = Task { @MainActor [weak self] in
            do {
                try await self?.downloadAudios()
                self?.audioFinish = true
            } catch {
                self?.state = .download(error: error)
                AVAssetCacheServer.cancelDownload(
                    exp: self?.videoTask
                )
            }
        }
        
        videoTask = AVAssetCacheServer.download(
            url: videoUrl
        ) { [weak self] p in
            self?.videoProgress = Double(p)
        } completion: { [weak self] suc in
            if suc {
                self?.videoFinish = true
            } else {
                self?.state =
                    .download(error: NetworkRequest.ErrorCode.videoDownloadError)
                self?.audioTask?.cancel()
            }
        }
        state = .downloading(p: 0)
    }
    
    @MainActor
    private func downloadAudios(
        
    ) async throws {
        let list = try await prepareDownloadFiles()
        let arr = list.compactMap { $0.builer }
        let queue = Set(arr).map{ $0.task }
        self.queue = queue
        let total = Double(queue.count)
        var finish: Double = 0.0
        
        for task in queue {
            try await task.start { [weak self] p in
                let percent = (finish + p) / total
                self?.audioProgress = percent
            }
            finish += 1.0
        }
    }
}

extension WorkoutAssetDownloader {
    
    private func prepareDownloadFiles(
        
    ) async throws -> [DownloadTaskConvert] {
        let id = asset.id
        let list = try await NetworkRequest.request(
            audioJson: asset.audioJsonUrl,
            id: id
        )
        let sound: [DownloadTaskConvert]
        if let url = asset.soundUrl {
            sound = try await NetworkRequest.request(
                sound: url,
                id: id
            )
        } else {
            sound = []
        }
        
        let welcomSound: [DownloadTaskConvert]
        if let url = asset.welcomSoundUrl {
            welcomSound = try await NetworkRequest.request(
                welcomSound: url,
                id: id
            )
        } else {
            welcomSound = []
        }
        
        let completeSound: [DownloadTaskConvert]
        if let url = asset.completeSoundUrl {
            completeSound = try await NetworkRequest.request(
                completeSound: url,
                id: id
            )
        } else {
            completeSound = []
        }
        
        return list + sound + welcomSound + completeSound
    }
}
