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
    
    let asset: WorkoutAsset
    
    private var queue: [DownloadTask] = []
    private var totalTaskCount: Int = 0
    private var finishTaskCount: Int = 0
    
    private var audioProgress: Double = 0.0 {
        didSet {
            state = .downloading(p: progress)
#if DEBUG
            print("audio下载进度：%\(Int(audioProgress * 100.0))")
#endif
        }
    }
    
    private var videoProgress: Double = 0.0 {
        didSet {
            state = .downloading(p: progress)
#if DEBUG
            print("video下载进度：%\(Int(videoProgress * 100.0))")
#endif
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
    
    private var isPaused = false
    
    @Published
    var state: WorkoutAssetDownloadState = .notDownload
    
    private var audioTask: DownloadTask?
    private var videoTask: NSObjectProtocol?
    
    init(asset: WorkoutAsset) {
        self.asset = asset
    }
    
    func pause() {
        isPaused = true
        stopDownloadAudio()
        AVAssetCacheServer.pauseDownload(
            exp: videoTask
        )
    }
    
    func resume() {
        isPaused = false
        startDownloadAudio()
        AVAssetCacheServer.resumeDownload(
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
        
        let ast = asset
        Task { @MainActor [weak self] in
            do {
                let (list, complete) = try await Self.prepareDownloadFiles(
                    asset: ast
                )
                self?.queue = list
                self?.totalTaskCount = list.count + complete
                self?.finishTaskCount = complete
                self?.startDownloadAudio()
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
                self?.stopDownloadAudio()
            }
        }
        state = .downloading(p: 0)
    }
    
    private func startDownloadAudio() {
        guard queue.count > 0,
              totalTaskCount > 0 else {
            if !audioFinish {
                audioProgress = 1.0
                audioFinish = true
            }
            return
        }
        guard let task = queue.first else {
            return
        }
        audioTask = task
        
        let t = Double(totalTaskCount)
        let a = Double(finishTaskCount)
        task.start { [weak self] p in
            self?.audioProgress = (p + a) / t
        } completion: { [weak self] err in
            if let e = err {
                if self?.isPaused != true {
                    self?.state = .download(error: e)
                    AVAssetCacheServer.cancelDownload(
                        exp: self?.videoTask
                    )
                }
            } else {
                self?.finishTaskCount += 1
                self?.queue.removeFirst()
                self?.startDownloadAudio()
            }
        }
    }
    
    private func stopDownloadAudio() {
        audioTask?.cancel()
    }
}

extension WorkoutAssetDownloader {
    
    private static func prepareDownloadFiles(
        asset: WorkoutAsset
    ) async throws -> ([DownloadTask], Int) {
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
        
        let taskList = list + sound + welcomSound + completeSound
        let arr = taskList.map { $0.builer }
        let total = Array(Set(arr))
        let queue = total.compactMap { $0.task }
        let finishCount = total.count - queue.count
        return (queue, finishCount)
    }
}
