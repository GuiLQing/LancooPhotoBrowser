//
//  LancooPhotoAlertView.h
//  LancooPhotoBrowserDemo
//
//  Created by lancoo on 2021/1/21.
//  Copyright © 2021 lancoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LancooPhotoConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface LancooPhotoAlertView : UIView

+ (void)showPhotoLibraryWithSelectedAssets:(NSArray *)selectedAssets configuration:(void (^)(LancooPhotoConfiguration *configuration))configuration fromController:(UIViewController *)sender completion:(void (^)(NSArray *assets))completion;

+ (void)showPhotoAlertWithConfiguration:(void (^)(LancooPhotoConfiguration *configuration))configuration fromController:(UIViewController *)sender completion:(void (^)(NSArray *assets))completion;

@end

NS_ASSUME_NONNULL_END
