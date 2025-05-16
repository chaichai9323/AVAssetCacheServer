//
//  WorkoutAssetManager.swift
//  Pods
//
//  Created by chai chai on 2025/5/14.
//

import Foundation
import Combine

@MainActor
public class WorkoutAssetManager {
    public static let shared = WorkoutAssetManager()
    
    private var disBag = Set<AnyCancellable>()
    
    private lazy var fileURL: URL = {
        let path = AVAssetCacheServer.ServerConfig.offlineDir + "/WorkoutAssetList.json"
        return URL(fileURLWithPath: path)
    }()
    
    private var downloadList = [WorkoutAsset]()
    private(set) var downloadMap = [String: WorkoutAsset]()
    
    private var downloadQueue = [WorkoutAsset]()
    private var currentTask: WorkoutAssetDownloader?
    
    private init() {
        if FileManager.default.fileExists(
            atPath: fileURL.path
        ), let data = try? Data(
            contentsOf: fileURL
        ), let list = try? JSONDecoder().decode(
            [WorkoutAsset].self,
            from: data
        ) {
            downloadList = list
            for asset in list {
                downloadMap[asset.id] = asset
                if !asset.isDownloaded {
                    downloadQueue.append(asset)
                }
            }
        }
    }
    
    public func start() {
        currentTask?.start()
    }
    
    public func pause() {
        currentTask?.pause()
    }
    
    public func download(item: WorkoutAssetDownloadable) {
        let id = item.assetUniqueId
        
        /// 只添加进下载列表中一次
        guard downloadMap[id] == nil else {
            checkDownloadTask()
            return
        }
        
        let asset = WorkoutAsset(asset: item)
        if let data = try? JSONEncoder().encode (
            item.assetModel
        ) {
            let path = asset.localModelPath
            try? data.write(
                to: URL(fileURLWithPath: path)
            )
        }
        downloadList.append(asset)
        downloadMap[id] = asset
        downloadQueue.append(asset)
        
        if let data = try? JSONEncoder().encode(
            downloadList
        ) {
            try? data.write(to: fileURL)
        }
        
        checkDownloadTask()
    }
    
    private func checkDownloadTask() {
        guard currentTask == nil else {
            return
        }
        guard downloadQueue.count > 0 else {
            return
        }
        let asset = downloadQueue.removeFirst()
        let task = WorkoutAssetDownloader(
            asset: asset
        )
        task.$state
            .receive(on: DispatchQueue.main)
            .sink { state in
                switch state {
                case .downloaded:
                    self.finishedDownload()
                case .download(let error):
                    self.errorDownload(error: error)
                case .downloading(let p):
#if DEBUG
                    print("下载进度：%\(Int(p * 100.0))")
#endif
                    break
                default:
                    break
                }
            }.store(in: &disBag)
        
        task.start()
        currentTask = task
    }
    
    private func finishedDownload() {
#if DEBUG
        print("下载完成")
#endif
        guard let id = currentTask?.id,
              let index = downloadList.firstIndex(where: {
                  $0.id == id
              }) else {
            return
        }
        
        downloadList[index].complete = true
        downloadMap[id] = downloadList[index]
        
        if let data = try? JSONEncoder().encode(
            downloadList
        ) {
            try? data.write(to: fileURL)
        }
        disBag.forEach{ $0.cancel() }
        disBag = []
        currentTask = nil
        checkDownloadTask()
    }
    
    private func errorDownload(error: Error) {
#if DEBUG
        print("下载失败")
#endif
        guard let id = currentTask?.id,
              let index = downloadList.firstIndex(where: {
                  $0.id == id
              }) else {
            return
        }
        let item = downloadList.remove(at: index)
        downloadQueue.append(item)
        
        if let data = try? JSONEncoder().encode(
            downloadList
        ) {
            try? data.write(to: fileURL)
        }
        disBag.forEach{ $0.cancel() }
        disBag = []
        currentTask = nil
        checkDownloadTask()
    }
}
