//
//  LancooPhotoManager.h
//  LancooPhotoBrowserDemo
//
//  Created by lancoo on 2021/1/18.
//  Copyright © 2021 lancoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "LancooPhotoConfiguration.h"
#import "LancooAlbumModel.h"

static inline void LancooPhotoAuthorizationStatus(void (^ _Nullable completion)(BOOL isAuthorized)) {
    switch (PHPhotoLibrary.authorizationStatus) {
        case PHAuthorizationStatusNotDetermined: {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                LancooPhotoAuthorizationStatus(completion);
            }];
        }
            break;
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO);
            });
        }
            break;
        case PHAuthorizationStatusAuthorized: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(YES);
            });
        }
            break;
    }
}

static inline void LancooAVAuthorizationStatus(void (^ _Nullable completion)(BOOL isAuthorized)) {
    AVAuthorizationStatus microPhoneStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (microPhoneStatus) {
        case AVAuthorizationStatusNotDetermined: { // 没弹窗
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                LancooAVAuthorizationStatus(completion);
            }];
        }
            break;
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted: { // 被拒绝
            if (completion) completion(NO);
        }
            break;
        case AVAuthorizationStatusAuthorized: { // 有授权
            if (completion) completion(YES);
        }
            break;
    }
}

static inline NSString * _Nullable LancooAssetDurationFormat(PHAsset * _Nonnull asset) {
    if (asset.mediaType != PHAssetMediaTypeVideo) return @"";
    
    NSInteger duration = (NSInteger)round(asset.duration);
    
    if (duration < 60) {
        return [NSString stringWithFormat:@"00:%02ld", duration];
    } else if (duration < 3600) {
        NSInteger m = duration / 60;
        NSInteger s = duration % 60;
        return [NSString stringWithFormat:@"%02ld:%02ld", m, s];
    } else {
        NSInteger h = duration / 3600;
        NSInteger m = (duration % 3600) / 60;
        NSInteger s = duration % 60;
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", h, m, s];
    }
}

NS_ASSUME_NONNULL_BEGIN

@interface LancooPhotoManager : NSObject

+ (instancetype)defaultManager;

+ (void)destroy;

+ (void)saveImageToAblum:(UIImage *)image completion:(void (^)(BOOL success, PHAsset *asset))completion;

+ (void)saveVideoToAblum:(NSURL *)url completion:(void (^)(BOOL success, PHAsset *asset))completion;

@property (nonatomic, strong, readonly) LancooPhotoConfiguration *configuration;

@property (nonatomic, strong, readonly) NSMutableArray *albumDataSource;

@property (nonatomic, strong) NSMutableArray *selectedAssets;

@end

NS_ASSUME_NONNULL_END
