//
//  LancooAlbumModel.h
//  LancooPhotoBrowserDemo
//
//  Created by lancoo on 2021/1/19.
//  Copyright © 2021 lancoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

static NSString * _Nonnull const LancooPhotoNotificationNavigationWillDismiss = @"LancooPhotoNotificationNavigationWillDismiss";
static NSString * _Nonnull const LancooPhotoNotificationSelectedAssetsDidChanged = @"LancooPhotoNotificationSelectedAssetsDidChanged";
static NSString * _Nonnull const LancooPhotoNotificationEnsureCompletion = @"LancooPhotoNotificationEnsureCompletion";

@class LancooPhotoModel;

NS_ASSUME_NONNULL_BEGIN

@interface LancooAlbumModel : NSObject

/** 相簿名称 */
@property (nonatomic, strong) NSString *albumName;
/** 资源数量 */
@property (nonatomic, assign) NSInteger photoCount;
/** 资源数据 */
@property (nonatomic, strong) NSMutableArray<LancooPhotoModel *> *photos;
/** 是否相机相册 */
@property (nonatomic, assign) BOOL isCameraRoll;
/** 相簿封面 */
@property (nonatomic, strong) PHAsset *coverAsset;

@property (nonatomic, strong) PHFetchOptions *options;

@property (nonatomic, strong) PHAssetCollection *collection;

@property (nonatomic, strong) PHFetchResult<PHAsset *> *result;

+ (LancooAlbumModel * (^)(PHFetchOptions *options, PHAssetCollection *collection, PHFetchResult<PHAsset *> *result))album;

@end

@interface LancooPhotoModel : NSObject

/** 资源对象 */
@property (nonatomic, strong) PHAsset *asset;
/** 视频时长 */
@property (nonatomic, assign) NSTimeInterval videoDuration;
/** 是否选中状态 */
@property (nonatomic, assign) BOOL selected;

+ (LancooPhotoModel * (^)(PHAsset *asset))photo;

@end

NS_ASSUME_NONNULL_END
