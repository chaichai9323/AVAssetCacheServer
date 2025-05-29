#
# Be sure to run `pod lib lint SJMediaCacheServer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AVAssetCacheServer'
  s.version          = '1.0.2'
  s.summary          = <<-DESC
  MediaCacheServer 是一个高效的 HTTP 媒体缓存框架，旨在代理媒体数据请求并优先提供缓存数据，从而减少网络流量并增强播放的流畅性。该框架支持两种类型的远程资源：基于文件的媒体，如 MP3、AAC、WAV、FLAC、OGG、MP4 和 MOV 等常见格式，以及 HLS（HTTP Live Streaming）流。它会自动解析 HLS 播放列表并代理各个媒体片段。
  DESC

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'https://github.com/chaichai9323/AVAssetCacheServer/blob/master/README.md'

  s.homepage         = 'https://github.com/chaichai9323/AVAssetCacheServer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'chailintao' => 'chailintao@laien.io' }
  s.source           = { :git => 'https://github.com/chaichai9323/AVAssetCacheServer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '15.0'

  s.subspec 'Cache' do |cache|
    cache.source_files = 'SJMediaCacheServer/**/*.{h,m,swift}', 'SQLite3/**/*.{h,m}', 'Interface/AVAssetCacheServer.swift'
    cache.resource_bundles = {
      'SJMediaCacheServer' => ['SJMediaCacheServer/Assets/**/*']
    }
    cache.dependency 'YYModel'
  end
  
  s.subspec 'Download' do |down|
    down.source_files = 'Interface/WorkoutDownload/**/*.swift'
    down.dependency "Alamofire"
    down.dependency 'AVAssetCacheServer/Cache'
  end
  
  s.default_subspec = 'Cache'
end
