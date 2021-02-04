//
//  LancooPhotoManager.m
//  LancooPhotoBrowserDemo
//
//  Created by lancoo on 2021/1/18.
//  Copyright © 2021 lancoo. All rights reserved.
//

#import "LancooPhotoManager.h"

@interface LancooPhotoManager ()

@property (nonatomic, strong) LancooPhotoConfiguration *configuration;

@end

@implementation LancooPhotoManager

static LancooPhotoManager *_manager = nil;
static dispatch_once_t onceToken;

+ (instancetype)defaultManager {
    dispatch_once(&onceToken, ^{
        _manager = [[super allocWithZone:NULL] init];
        _manager.configuration = [LancooPhotoConfiguration configuration];
    });
    return _manager;
}

+ (void)destroy {
    onceToken = 0;
    _manager = nil;
}

- (void)dealloc {
    NSLog(@"LancooPhotoManager dealloc");
}

#pragma mark - 保存图片到系统相册

+ (void)saveImageToAblum:(UIImage *)image completion:(void (^)(BOOL, PHAsset *))completion {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied) {
        if (completion) completion(NO, nil);
    } else if (status == PHAuthorizationStatusRestricted) {
        if (completion) completion(NO, nil);
    } else {
        __block PHObjectPlaceholder *placeholderAsset=nil;
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *newAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            placeholderAsset = newAssetRequest.placeholderForCreatedAsset;
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    PHAsset *asset = [LancooPhotoManager getAssetFromlocalIdentifier:placeholderAsset.localIdentifier];
                    if (completion) completion(YES, asset);
                } else {
                    if (completion) completion(NO, nil);
                }
            });
        }];
    }
}

+ (void)saveVideoToAblum:(NSURL *)url completion:(void (^)(BOOL, PHAsset *))completion
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied) {
        if (completion) completion(NO, nil);
    } else if (status == PHAuthorizationStatusRestricted) {
        if (completion) completion(NO, nil);
    } else {
        __block PHObjectPlaceholder *placeholderAsset=nil;
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *newAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
            placeholderAsset = newAssetRequest.placeholderForCreatedAsset;
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    PHAsset *asset = [LancooPhotoManager getAssetFromlocalIdentifier:placeholderAsset.localIdentifier];
                    if (completion) completion(YES, asset);
                } else {
                    if (completion) completion(NO, nil);
                }
            });
        }];
    }
}

+ (PHAsset *)getAssetFromlocalIdentifier:(NSString *)localIdentifier{
    if(localIdentifier == nil){
        NSLog(@"Cannot get asset from localID because it is nil");
        return nil;
    }
    PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
    if(result.count){
        return result[0];
    }
    return nil;
}

- (NSMutableArray *)albumDataSource {
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    if (!self.configuration.allowSelectVideo) options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    if (!self.configuration.allowSelectImage) options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",PHAssetMediaTypeVideo];
    if (!self.configuration.sortAscending) options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.configuration.sortAscending]];
    
    //获取所有智能相册
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHFetchResult *streamAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
    PHFetchResult *userAlbums = [PHAssetCollection fetchTopLevelUserCollectionsWithOptions:nil];
    PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
    NSArray *allAlbums = @[smartAlbums, streamAlbums, userAlbums, syncedAlbums, sharedAlbums];
    
    __block NSMutableArray *dataSource = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    [allAlbums enumerateObjectsUsingBlock:^(PHFetchResult<PHAssetCollection *> * _Nonnull album, NSUInteger idx, BOOL * _Nonnull stop) {
        [album enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
            //过滤最近删除和已隐藏
            if (@available(iOS 11, *)) {
                if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumLongExposures) {
                    return ;
                }
            }
            if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) {
                return;
            }
            
            //获取相册内asset result
            PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            if (result.count == 0) {
                return;
            }
            
            LancooAlbumModel *albumModel = LancooAlbumModel.album(options, collection, result);
            if (weakSelf.configuration.sortAscending) {
                albumModel.coverAsset = result.lastObject;
            } else {
                albumModel.coverAsset = result.firstObject;
            }
            if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) { // 相机相册
                albumModel.isCameraRoll = YES;
                [dataSource insertObject:albumModel atIndex:0];
            } else {
                [dataSource addObject:albumModel];
            }
        }];
    }];
    return dataSource;
}

#pragma mark - LazyLoading

- (NSMutableArray *)selectedAssets {
    if (!_selectedAssets) {
        _selectedAssets = [NSMutableArray array];
    }
    return _selectedAssets;
}

 //用alloc返回也是唯一实例
+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self.class defaultManager];
}
//对对象使用copy也是返回唯一实例
- (id)copyWithZone:(NSZone *)zone {
    return [self.class defaultManager];
}
//对对象使用mutablecopy也是返回唯一实例
- (id)mutableCopyWithZone:(NSZone *)zone {
    return [self.class defaultManager];
}

@end
