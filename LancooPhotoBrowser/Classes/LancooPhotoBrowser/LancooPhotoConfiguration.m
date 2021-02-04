//
//  LancooPhotoConfiguration.m
//  LancooPhotoBrowserDemo
//
//  Created by lancoo on 2021/1/19.
//  Copyright © 2021 lancoo. All rights reserved.
//

#import "LancooPhotoConfiguration.h"

@implementation LancooPhotoConfiguration

+ (instancetype)configuration {
    LancooPhotoConfiguration *configuration = [[LancooPhotoConfiguration alloc] init];
    configuration.maxSelectCount = 9;
    configuration.allowSelectImage = YES;
    configuration.allowSelectVideo = YES;
    configuration.allowTakePhotoInLibrary = YES;
    configuration.allowEditImage = YES;
    configuration.saveNewImageAfterEdit = YES;
    configuration.allowSelectOriginal = YES;
    configuration.allowEditVideo = NO;
    configuration.maxEditVideoTime = 10;
    configuration.maxVideoDuration = 120;
    configuration.allowSlideSelect = YES;
    configuration.showCaptureImageOnTakePhotoBtn = YES;
    configuration.sortAscending = YES;
    configuration.showSelectedIndex = YES;
    
    configuration.allowRecordVideo = YES;
    configuration.maxRecordDuration = 10;
    configuration.sessionPreset = LancooCaptureSessionPreset1280x720;
    configuration.exportVideoType = LancooExportVideoTypeMov;
    configuration.cameraProgressColor = [UIColor colorWithRed:80/255.0 green:169/255.0 blue:56/255.0 alpha:1.0];
    return configuration;
}

@end
