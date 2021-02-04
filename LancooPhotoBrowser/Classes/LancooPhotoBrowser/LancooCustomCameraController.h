//
//  LancooCustomCameraController.h
//  LancooPhotoBrowserDemo
//
//  Created by lancoo on 2021/1/26.
//  Copyright © 2021 lancoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LancooPhotoConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface LancooCustomCameraController : UIViewController

//是否允许拍照 默认YES
@property (nonatomic, assign) BOOL allowTakePhoto;
//是否允许录制视频 默认YES
@property (nonatomic, assign) BOOL allowRecordVideo;

//最大录制时长 默认15s
@property (nonatomic, assign) NSInteger maxRecordDuration;

//视频分辨率 默认 ZLCaptureSessionPreset1280x720
@property (nonatomic, assign) LancooCaptureSessionPreset sessionPreset;

//视频格式 默认 ZLExportVideoTypeMp4
@property (nonatomic, assign) LancooExportVideoType videoType;

//录制视频时候进度条颜色 默认 rgb(80, 169, 56)
@property (nonatomic, strong) UIColor *circleProgressColor;

/**
 确定回调，如果拍照则videoUrl为nil，如果视频则image为nil
 */
@property (nonatomic, copy) void (^doneBlock)(UIImage *image, NSURL *videoUrl);

@property (nonatomic, copy) void (^dismissCompletionHandler)(void);

@end

NS_ASSUME_NONNULL_END
