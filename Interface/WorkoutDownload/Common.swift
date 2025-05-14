//
//  Common.swift
//  Pods
//
//  Created by chai chai on 2025/5/14.
//

import Foundation
import CryptoKit

internal extension String {
    var urlPathMD5: String {
        guard let data = data(using: .utf8) else { return "" }
        let res = Insecure.MD5.hash(data: data).map { d in
            String(format: "%02hhx", d)
        }.joined()
        
        return res
    }
}



extension AVAssetCacheServer {
    public struct ServerConfig {
        private static let offlineDirName = "M3u8Downloads"
        
        static let offlineDir: String = {
            let dir = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0].path + "/\(offlineDirName)"
            let fm = FileManager.default
            var isDir = ObjCBool(false)
            if fm.fileExists(
                atPath: dir,
                isDirectory: &isDir
            ), isDir.boolValue {
                return dir
            } else {
                try? fm.createDirectory(
                    at: URL(fileURLWithPath: dir),
                    withIntermediateDirectories: true
                )
                return dir
            }
        }()
        
        public static var host: String = "https://core-app-test.7mfitness.com"
        public static var app: String = "cmsApp/oog104"
        public static var soundPath: String = "sound/v1/list"
        
        internal static func generate(
            sound url: String
        ) -> String {
            return "\(host)/\(app)/\(soundPath)?\(url)"
        }
    }
}
