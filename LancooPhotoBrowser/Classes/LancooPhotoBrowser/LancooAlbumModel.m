//
//  LancooAlbumModel.m
//  LancooPhotoBrowserDemo
//
//  Created by lancoo on 2021/1/19.
//  Copyright © 2021 lancoo. All rights reserved.
//

#import "LancooAlbumModel.h"

@implementation LancooAlbumModel

+ (LancooAlbumModel * (^)(PHFetchOptions *options, PHAssetCollection *collection, PHFetchResult<PHAsset *> *result))album {
    return ^(PHFetchOptions *options, PHAssetCollection *collection, PHFetchResult<PHAsset *> *result) {
        LancooAlbumModel *albumModel = [[LancooAlbumModel alloc] init];
        albumModel.albumName = collection.localizedTitle;
        albumModel.photoCount = result.count;
        albumModel.options = options;
        albumModel.collection = collection;
        albumModel.result = result;
        return albumModel;
    };
}

- (void)setResult:(PHFetchResult<PHAsset *> *)result {
    _result = result;
    
    __block NSMutableArray *photoDataSource = [NSMutableArray array];
    [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        LancooPhotoModel *photoModel = LancooPhotoModel.photo(asset);
        [photoDataSource addObject:photoModel];
    }];
    _photos = photoDataSource;
}

@end

@implementation LancooPhotoModel

+ (LancooPhotoModel * (^)(PHAsset *asset))photo {
    return ^(PHAsset *asset) {
        LancooPhotoModel *photoModel = [[LancooPhotoModel alloc] init];
        photoModel.asset = asset;
        if (asset.mediaType == PHAssetMediaTypeVideo) {
            photoModel.videoDuration = asset.duration;
        }
        return photoModel;
    };
}

@end
