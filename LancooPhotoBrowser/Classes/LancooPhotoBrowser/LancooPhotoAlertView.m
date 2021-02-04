//
//  LancooPhotoAlertView.m
//  LancooPhotoBrowserDemo
//
//  Created by lancoo on 2021/1/21.
//  Copyright © 2021 lancoo. All rights reserved.
//

#import "LancooPhotoAlertView.h"
#import "LancooPhotoManager.h"
#import "LancooPhotoNavigationController.h"
#import "LancooAlbumListController.h"
#import "LancooThumbnailListController.h"
#import "LancooCustomCameraController.h"

@interface LancooPhotoAlertView ()

@property (nonatomic, strong) LancooPhotoManager *manager;

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, strong) UIView *backView;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIViewController *sender;

@property (nonatomic, copy) void (^selectedCompletion)(NSArray *assets);

@end

@implementation LancooPhotoAlertView

+ (void)showPhotoLibraryWithSelectedAssets:(NSArray *)selectedAssets configuration:(void (^)(LancooPhotoConfiguration *configuration))configuration fromController:(UIViewController *)sender completion:(void (^)(NSArray *assets))completion {
    LancooPhotoAlertView *alertView = [[LancooPhotoAlertView alloc] init];
    alertView.manager.selectedAssets = [selectedAssets mutableCopy];
    configuration(alertView.manager.configuration);
    alertView.sender = sender;
    alertView.selectedCompletion = ^(NSArray *assets) {
        if (completion) completion(assets);
    };
    alertView.hidden = YES;
    [UIApplication.sharedApplication.delegate.window addSubview:alertView];
    [alertView gotoCameraRollThumbnailList];
}

+ (void)showPhotoAlertWithConfiguration:(void (^)(LancooPhotoConfiguration *configuration))configuration fromController:(UIViewController *)sender completion:(void (^)(NSArray *assets))completion {
    LancooPhotoAlertView *alertView = [[LancooPhotoAlertView alloc] init];
    configuration(alertView.manager.configuration);
    alertView.sender = sender;
    alertView.selectedCompletion = ^(NSArray *assets) {
        if (completion) completion(assets);
    };
    [alertView show];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _manager = LancooPhotoManager.defaultManager;
        
        self.frame = UIScreen.mainScreen.bounds;
        self.backgroundColor = UIColor.clearColor;
        
        self.backView = UIView.alloc.init;
        self.backView.backgroundColor = UIColor.blackColor;
        self.backView.frame = self.bounds;
        self.backView.alpha = 0.0f;
        [self addSubview:self.backView];
        
        UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
        [self.backView addGestureRecognizer:tapGR];
        
        self.contentView = UIView.alloc.init;
//        self.contentView.backgroundColor = UIColor.lightGrayColor;
        [self addSubview:self.contentView];
        
        UIView *subContentView = [[UIView alloc] init];
        subContentView.backgroundColor = UIColor.whiteColor;
        subContentView.layer.cornerRadius = 4.0f;
        subContentView.layer.masksToBounds = YES;
        [self.contentView addSubview:subContentView];
        
        UIButton *albumButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [albumButton addTarget:self action:@selector(albumButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [albumButton setTitle:@"相册" forState:UIControlStateNormal];
        [albumButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        albumButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        [subContentView addSubview:albumButton];
        
        UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cameraButton addTarget:self action:@selector(cameraButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [cameraButton setTitle:@"相机" forState:UIControlStateNormal];
        [cameraButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        cameraButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        [subContentView addSubview:cameraButton];
        
        UIView *middleLineView = [[UIView alloc] init];
        middleLineView.backgroundColor = UIColor.grayColor;
        [subContentView addSubview:middleLineView];
        
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cancelButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [cancelButton setTitleColor:UIColor.grayColor forState:UIControlStateNormal];
        cancelButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        cancelButton.backgroundColor = UIColor.whiteColor;
        cancelButton.layer.cornerRadius = 4.0f;
        cancelButton.layer.masksToBounds = YES;
        [self.contentView addSubview:cancelButton];
        
        CGFloat contentWidth = CGRectGetWidth(self.bounds) - 40.0f;
        CGFloat buttonHeight = 50.0f;
        
        albumButton.frame = CGRectMake(0, 0, contentWidth, buttonHeight);
        middleLineView.frame = CGRectMake(0, CGRectGetMaxY(albumButton.frame), contentWidth, 0.5);
        cameraButton.frame = CGRectMake(0, CGRectGetMaxY(albumButton.frame), contentWidth, buttonHeight);
        subContentView.frame = CGRectMake(20.0f, 0, contentWidth, CGRectGetMaxY(cameraButton.frame));
        cancelButton.frame = CGRectMake(20.0f, CGRectGetMaxY(subContentView.frame) + 10.0f, contentWidth, buttonHeight);
        self.contentView.frame = CGRectMake(0, CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds), CGRectGetMaxY(cancelButton.frame) + 10.0f);
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(hide) name:LancooPhotoNotificationNavigationWillDismiss object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(ensureNotificationAction) name:LancooPhotoNotificationEnsureCompletion object:nil];
    }
    return self;
}
 
- (void)show {
    __weak typeof(self) weakSelf = self;
    [UIApplication.sharedApplication.delegate.window addSubview:self];
    [UIView animateWithDuration:0.25 animations:^{
        weakSelf.backView.alpha = 0.05;
        weakSelf.contentView.frame = CGRectMake(CGRectGetMinX(weakSelf.contentView.frame), CGRectGetHeight(UIScreen.mainScreen.bounds) - CGRectGetHeight(weakSelf.contentView.frame), CGRectGetWidth(weakSelf.contentView.frame), CGRectGetHeight(weakSelf.contentView.frame));
    }];
}

- (void)hide {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.25 animations:^{
        weakSelf.backView.alpha = 0.0f;
        weakSelf.contentView.frame = CGRectMake(CGRectGetMinX(weakSelf.contentView.frame), CGRectGetHeight(UIScreen.mainScreen.bounds), CGRectGetWidth(weakSelf.contentView.frame), CGRectGetHeight(weakSelf.contentView.frame));
    } completion:^(BOOL finished) {
        [weakSelf destroy];
        [weakSelf removeFromSuperview];
    }];
}

- (void)destroy {
    [NSNotificationCenter.defaultCenter removeObserver:self name:LancooPhotoNotificationNavigationWillDismiss object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:LancooPhotoNotificationEnsureCompletion object:nil];
    
    [LancooPhotoManager destroy];
}

- (void)dealloc {
    NSLog(@"LancooPhotoAlertView dealloc");
}

#pragma mark - Notification

- (void)ensureNotificationAction {
    NSLog(@"selectedAssets: %@", LancooPhotoManager.defaultManager.selectedAssets);
    if (self.selectedCompletion) self.selectedCompletion(LancooPhotoManager.defaultManager.selectedAssets);
    [self hide];
}

#pragma mark - Private Method

- (void)albumButtonAction {
    [self gotoCameraRollThumbnailList];
}

- (void)cameraButtonAction {
    [self gotoCustomCamera];
}

- (void)gotoCameraRollThumbnailList {
    self.hidden = YES;
    __weak typeof(self) weakSelf = self;
    LancooPhotoAuthorizationStatus(^(BOOL isAuthorized) {
        if (isAuthorized) {
            __block LancooAlbumListController *albumListVC = [[LancooAlbumListController alloc] init];
            albumListVC.dataSource = LancooPhotoManager.defaultManager.albumDataSource;
            LancooThumbnailListController *thumbnailListVC = [[LancooThumbnailListController alloc] init];
            thumbnailListVC.albumModel = albumListVC.dataSource.firstObject;
            thumbnailListVC.updateDataSource = ^(void (^ _Nonnull completion)(LancooAlbumModel * _Nonnull)) {
                albumListVC.dataSource = LancooPhotoManager.defaultManager.albumDataSource;
                if (completion) completion(albumListVC.dataSource.firstObject);
            };
            LancooPhotoNavigationController *navigationController = [[LancooPhotoNavigationController alloc] initWithRootViewController:albumListVC];
            [navigationController pushViewController:thumbnailListVC animated:NO];
            [weakSelf.sender presentViewController:navigationController animated:YES completion:nil];
        } else {
            [weakSelf hide];
            UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:@"您暂未设置相册权限" message:@"相册权限未开启，暂时无法使用相册功能，请点击“设置”开启相册权限" preferredStyle:UIAlertControllerStyleAlert];
            [alertViewController addAction:[UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    if (@available(iOS 10.0, *)) {
                        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                    } else {
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }
            }]];
            [alertViewController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            [weakSelf.sender presentViewController:alertViewController animated:YES completion:nil];
        }
    });
}

- (void)gotoCustomCamera {
    self.hidden = YES;
    __weak typeof(self) weakSelf = self;
    LancooAVAuthorizationStatus(^(BOOL isAuthorized) {
        if (isAuthorized) {
            LancooPhotoConfiguration *configuration = weakSelf.manager.configuration;
            LancooCustomCameraController *camera = [[LancooCustomCameraController alloc] init];
            camera.allowTakePhoto = configuration.allowSelectImage;
            camera.allowRecordVideo = configuration.allowSelectVideo && configuration.allowRecordVideo;
            camera.sessionPreset = configuration.sessionPreset;
            camera.videoType = configuration.exportVideoType;
            camera.circleProgressColor = configuration.cameraProgressColor;
            camera.maxRecordDuration = configuration.maxRecordDuration;
            camera.doneBlock = ^(UIImage *image, NSURL *videoUrl) {
                [weakSelf saveImage:image videoUrl:videoUrl];
            };
            camera.dismissCompletionHandler = ^{
                [weakSelf hide];
            };
            [weakSelf.sender presentViewController:camera animated:YES completion:nil];
        } else {
            [weakSelf hide];
            UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:@"您暂未设置相机权限" message:@"相机权限未开启，暂时无法使用相机功能，请点击“设置”开启相机权限" preferredStyle:UIAlertControllerStyleAlert];
            [alertViewController addAction:[UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    if (@available(iOS 10.0, *)) {
                        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                    } else {
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }
            }]];
            [alertViewController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            [weakSelf.sender presentViewController:alertViewController animated:YES completion:nil];
        }
    });
}

- (void)saveImage:(UIImage *)image videoUrl:(NSURL *)videoUrl {
    if (image) {
        [LancooPhotoManager saveImageToAblum:image completion:^(BOOL success, PHAsset * _Nonnull asset) {
            if (success) {
                if (self.selectedCompletion) self.selectedCompletion(@[asset]);
            }
        }];
    } else if (videoUrl) {
        [LancooPhotoManager saveVideoToAblum:videoUrl completion:^(BOOL success, PHAsset * _Nonnull asset) {
            if (success) {
                if (self.selectedCompletion) self.selectedCompletion(@[asset]);
            }
        }];
    }
}

@end
