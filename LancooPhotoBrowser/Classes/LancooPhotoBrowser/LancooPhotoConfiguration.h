//
//  LancooPhotoConfiguration.h
//  LancooPhotoBrowserDemo
//
//  Created by lancoo on 2021/1/19.
//  Copyright © 2021 lancoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static inline UIImage * _Nonnull LancooPhotoImage(NSString * _Nonnull imageName) {
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:NSClassFromString(@"LancooPhotoConfiguration")] pathForResource:@"LancooPhotoBrowser" ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
}

//录制视频及拍照分辨率
typedef NS_ENUM(NSUInteger, LancooCaptureSessionPreset) {
    LancooCaptureSessionPreset320x240,
    LancooCaptureSessionPreset325x288,
    LancooCaptureSessionPreset640x480,
    LancooCaptureSessionPreset960x540,
    LancooCaptureSessionPreset1280x720,
    LancooCaptureSessionPreset1920x1080,
    LancooCaptureSessionPreset3840x2160,
};

//导出视频类型
typedef NS_ENUM(NSUInteger, LancooExportVideoType) {
    //default
    LancooExportVideoTypeMov,
    LancooExportVideoTypeMp4,
};

NS_ASSUME_NONNULL_BEGIN

@interface LancooPhotoConfiguration : NSObject

+ (instancetype)configuration;

/** 最大选择数 默认9张，最小 1 */
@property (nonatomic, assign) NSInteger maxSelectCount;
/** 是否允许选择照片 默认YES */
@property (nonatomic, assign) BOOL allowSelectImage;
/** 是否允许选择视频 默认YES */
@property (nonatomic, assign) BOOL allowSelectVideo;
/** 是否允许相册内部拍照 默认YES */
@property (nonatomic, assign) BOOL allowTakePhotoInLibrary;
/** 是否允许编辑图片，选择一张时候才允许编辑，默认YES */
@property (nonatomic, assign) BOOL allowEditImage;
/** 编辑图片后是否保存编辑后的图片至相册，默认YES */
@property (nonatomic, assign) BOOL saveNewImageAfterEdit;
/** 是否允许选择原图，默认YES */
@property (nonatomic, assign) BOOL allowSelectOriginal;
/** 是否允许编辑视频，选择一张时候才允许编辑，默认NO */
@property (nonatomic, assign) BOOL allowEditVideo;
/** 编辑视频时最大裁剪时间，单位：秒，默认10s 且最小5s。（当该参数为10s时，所选视频时长必须大于等于10s才允许进行编辑） */
@property (nonatomic, assign) NSInteger maxEditVideoTime;
/** 允许选择视频的最大时长，单位：秒， 默认 120s */
@property (nonatomic, assign) NSInteger maxVideoDuration;
/** 是否允许滑动选择 默认 YES */
@property (nonatomic, assign) BOOL allowSlideSelect;
/** 是否在相册内部拍照按钮上面实时显示相机俘获的影像 默认 YES */
@property (nonatomic, assign) BOOL showCaptureImageOnTakePhotoBtn;
/** 是否升序排列，预览界面不受该参数影响，默认升序 YES */
@property (nonatomic, assign) BOOL sortAscending;
/** 是否显示选中图片的index 默认YES */
@property (nonatomic, assign) BOOL showSelectedIndex;

/** 是否允许录制视频，默认YES */
@property (nonatomic, assign) BOOL allowRecordVideo;
/** 最大录制时长，默认 10s，最小为 1s */
@property (nonatomic, assign) NSInteger maxRecordDuration;
/** 视频清晰度，默认ZLCaptureSessionPreset1280x720 */
@property (nonatomic, assign) LancooCaptureSessionPreset sessionPreset;
/** 录制视频及编辑视频时候的视频导出格式，默认ZLExportVideoTypeMov */
@property (nonatomic, assign) LancooExportVideoType exportVideoType;
/** 长按拍照按钮进行录像时的progress color 默认rgb(80, 169, 56) */
@property (nonatomic, strong) UIColor *cameraProgressColor;

@end

NS_ASSUME_NONNULL_END
