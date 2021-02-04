//
//  LancooThumbnailListController.h
//  LancooPhotoBrowserDemo
//
//  Created by lancoo on 2021/1/20.
//  Copyright © 2021 lancoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LancooAlbumModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LancooThumbnailListController : UIViewController

@property (nonatomic, strong) LancooAlbumModel *albumModel;

@property (nonatomic, copy) void (^updateDataSource)(void (^completion)(LancooAlbumModel *albumModel));

@end

NS_ASSUME_NONNULL_END
