//
//  HLSAssetContentReader.h
//  SJMediaCacheServer
//
//  Created by 畅三江 on 2021/7/19.
//

#import "MCSAssetContentReader.h"
#import "HLSAssetDefines.h"
@class HLSAsset;

NS_ASSUME_NONNULL_BEGIN

@interface HLSAssetPlaylistContentReader : MCSAssetContentReader

- (instancetype)initWithAsset:(HLSAsset *)asset request:(NSURLRequest *)request networkTaskPriority:(float)networkTaskPriority delegate:(id<MCSAssetContentReaderDelegate>)delegate;

@end


@interface HLSAssetKeyContentReader : MCSAssetContentReader

- (instancetype)initWithAsset:(HLSAsset *)asset request:(NSURLRequest *)request networkTaskPriority:(float)priority delegate:(id<MCSAssetContentReaderDelegate>)delegate;
;

@end


@interface HLSAssetSubtitlesContentReader : MCSAssetContentReader

- (instancetype)initWithAsset:(HLSAsset *)asset request:(NSURLRequest *)request networkTaskPriority:(float)priority delegate:(id<MCSAssetContentReaderDelegate>)delegate;

@end


@interface HLSAssetInitializationContentReader : MCSAssetContentReader

- (instancetype)initWithAsset:(HLSAsset *)asset request:(NSURLRequest *)request networkTaskPriority:(float)priority delegate:(id<MCSAssetContentReaderDelegate>)delegate;

@end
NS_ASSUME_NONNULL_END
