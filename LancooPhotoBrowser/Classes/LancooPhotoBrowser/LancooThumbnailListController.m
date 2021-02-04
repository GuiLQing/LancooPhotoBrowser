//
//  LancooThumbnailListController.m
//  LancooPhotoBrowserDemo
//
//  Created by lancoo on 2021/1/20.
//  Copyright © 2021 lancoo. All rights reserved.
//

#import "LancooThumbnailListController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreText/CoreText.h>
#import "LancooPhotoManager.h"
#import "LancooCustomCameraController.h"

static CGFloat const LancooThumbnailListFooterViewHeight = 50.0f;

@protocol LancooThumbnailListFooterViewDelegate <NSObject>

@optional

- (void)ensureButtonDidClicked;

@end

@interface LancooThumbnailListFooterView : UIView

@property (nonatomic, strong) UIButton *editButton;

@property (nonatomic, strong) UIButton *originalButton;

@property (nonatomic, strong) UIButton *ensureButton;

@property (nonatomic, assign) NSInteger selectedCount;

@property (nonatomic, weak) id<LancooThumbnailListFooterViewDelegate> delegate;

@end

@implementation LancooThumbnailListFooterView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.grayColor;
        
        [self addSubview:self.ensureButton];
        [self addSubview:self.editButton];
        [self addSubview:self.originalButton];
    }
    return self;
}

- (void)setSelectedCount:(NSInteger)selectedCount {
    _selectedCount = selectedCount;
    
    self.ensureButton.enabled = selectedCount != 0;
    [self.ensureButton setTitle:selectedCount == 0 ? @"确定" : [NSString stringWithFormat:@"确定(%zd/%zd)", selectedCount, LancooPhotoManager.defaultManager.configuration.maxSelectCount] forState:UIControlStateNormal];
    
    [self layoutIfNeeded];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize ensureButtonSize = [self.ensureButton sizeThatFits:CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - 15.0f)];
    self.ensureButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - ensureButtonSize.width - 40.0f, 7.5f, ensureButtonSize.width + 20.0f, CGRectGetHeight(self.bounds) - 15.0f);
    
}

- (void)ensureButtonAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(ensureButtonDidClicked)]) {
        [self.delegate ensureButtonDidClicked];
    }
}

- (UIButton *)ensureButton {
    if (!_ensureButton) {
        _ensureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_ensureButton addTarget:self action:@selector(ensureButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_ensureButton setTitle:@"确定" forState:UIControlStateNormal];
        [_ensureButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _ensureButton.backgroundColor = [UIColor colorWithRed:11/255.0 green:175/255.0 blue:251/255.0 alpha:1.0];
        _ensureButton.layer.cornerRadius = 4.0f;
        _ensureButton.layer.masksToBounds = YES;
        _ensureButton.enabled = NO;
    }
    return _ensureButton;
}

- (UIButton *)editButton {
    if (!_editButton) {
        _editButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_editButton setTitle:@"编辑" forState:UIControlStateNormal];
        [_editButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _editButton.hidden = YES;
    }
    return _editButton;
}

- (UIButton *)originalButton {
    if (!_originalButton) {
        _originalButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_originalButton setTitle:@"原图" forState:UIControlStateNormal];
        [_originalButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _originalButton.hidden = YES;
    }
    return _originalButton;
}

@end

@interface LancooThumbnailListTickView : UIView

@property (nonatomic, assign) BOOL isSelected;

@property (nonatomic, assign) BOOL isAnimation;

@property (nonatomic, strong) CAShapeLayer *tickLayer;

@property (nonatomic, strong) LancooPhotoModel *photoModel;

@end

@implementation LancooThumbnailListTickView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tickTapAction)]];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(assetDidChangedNotification) name:LancooPhotoNotificationSelectedAssetsDidChanged object:nil];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)assetDidChangedNotification {
    [self setIsSelected:self.isSelected];
}

- (void)tickTapAction {
    if (_isSelected) { // 当前选中状态，设置为未选中
        for (PHAsset *asset in LancooPhotoManager.defaultManager.selectedAssets) {
            if ([asset.localIdentifier isEqualToString:self.photoModel.asset.localIdentifier]) {
                [LancooPhotoManager.defaultManager.selectedAssets removeObject:asset];
                [NSNotificationCenter.defaultCenter postNotificationName:LancooPhotoNotificationSelectedAssetsDidChanged object:nil];
                break;
            }
        }
    } else { // 当前未选中，设置为选中
        if (LancooPhotoManager.defaultManager.selectedAssets.count >= LancooPhotoManager.defaultManager.configuration.maxSelectCount) {
            NSLog(@"最多只能选%zd个", LancooPhotoManager.defaultManager.configuration.maxSelectCount);
            return;
        }
        [LancooPhotoManager.defaultManager.selectedAssets addObject:self.photoModel.asset];
        [NSNotificationCenter.defaultCenter postNotificationName:LancooPhotoNotificationSelectedAssetsDidChanged object:nil];
    }
    [self setIsSelected:!_isSelected isAnimation:YES];
}

- (void)setIsSelected:(BOOL)isSelected isAnimation:(BOOL)isAnimation {
    _isSelected = isSelected;
    _isAnimation = isAnimation;
    
    self.photoModel.selected = isSelected;
    
    [self setNeedsDisplay];
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    _isAnimation = NO;
    
    [self setNeedsDisplay];
}

- (void)setPhotoModel:(LancooPhotoModel *)photoModel {
    _photoModel = photoModel;
    
    self.isSelected = photoModel.selected;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (self.tickLayer) {
        [self.tickLayer removeAllAnimations];
        [self.tickLayer removeFromSuperlayer];
        self.tickLayer = nil;
    }
    
    if (self.isSelected) {
        CGPoint center = CGPointMake(rect.size.width*0.5,rect.size.height*0.5);
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:rect.size.width*0.5 startAngle:0 endAngle:M_PI*2 clockwise:YES];
        [[UIColor colorWithRed:11/255.0 green:175/255.0 blue:251/255.0 alpha:1.0] setFill];
        [path fill];
        
        if (LancooPhotoManager.defaultManager.configuration.showSelectedIndex) {
            CGMutablePathRef letters = CGPathCreateMutable();   //创建path
            
            CTFontRef font = CTFontCreateWithName(CFSTR("Helvetica-Bold"), 18.0f, NULL);       //设置字体
            NSInteger index = [LancooPhotoManager.defaultManager.selectedAssets indexOfObject:self.photoModel.asset] + 1;
            if (index >= 10) {
                font = CTFontCreateWithName(CFSTR("Helvetica-Bold"), 16.0f, NULL);
            }
            
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   (__bridge id)font, kCTFontAttributeName,
                                   nil];
            NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%zd", index] attributes:attrs];
            CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attrString);   //创建line
            CFArrayRef runArray = CTLineGetGlyphRuns(line);     //根据line获得一个数组
            
            // 获得每一个 run
            for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runArray); runIndex++) {
                // 获得 run 的字体
                CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
                CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
                
                // 获得 run 的每一个形象字
                for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++) {
                    // 获得形象字
                    CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
                    //获得形象字信息
                    CGGlyph glyph;
                    CGPoint position;
                    CTRunGetGlyphs(run, thisGlyphRange, &glyph);
                    CTRunGetPositions(run, thisGlyphRange, &position);
                    
                    // 获得形象字外线的path
                    CGPathRef letter = CTFontCreatePathForGlyph(runFont, glyph, NULL);
                    CGAffineTransform t = CGAffineTransformMakeTranslation(position.x, position.y);
                    CGPathAddPath(letters, &t, letter);
                    CGPathRelease(letter);
                }
            }
            CFRelease(line);
            
            //根据构造出的 path 构造 bezier 对象
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointZero];
            [path appendPath:[UIBezierPath bezierPathWithCGPath:letters]];
            
            CGPathRelease(letters);
            CFRelease(font);
            
            //根据 bezier 创建 shapeLayer对象
            CAShapeLayer *pathLayer = [CAShapeLayer layer];
            self.tickLayer = pathLayer;
            pathLayer.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
            pathLayer.bounds = CGPathGetBoundingBox(path.CGPath);
            pathLayer.geometryFlipped = YES;
            pathLayer.path = path.CGPath;
            pathLayer.strokeColor = [[UIColor whiteColor] CGColor];
            pathLayer.fillColor = nil;
            pathLayer.lineWidth = 1.0f;
            pathLayer.lineJoin = kCALineJoinBevel;
            [self.layer addSublayer:pathLayer];
            
            if (self.isAnimation) {
                CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
                pathAnimation.duration = 0.25;
                pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
                pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
                [pathLayer addAnimation:pathAnimation forKey:nil];
            }
        } else {
            UIBezierPath *tickPath = [UIBezierPath bezierPath];
            tickPath.lineWidth = rect.size.width*0.06;
            [tickPath moveToPoint:CGPointMake(rect.size.width*0.25, rect.size.height*0.5)];
            [tickPath addLineToPoint:CGPointMake(rect.size.width*0.45, rect.size.height*0.7)];
            [tickPath addLineToPoint:CGPointMake(rect.size.width*0.79, rect.size.height*0.35)];
            
            //2、创建CAShapeLayer
            CAShapeLayer *tickLayer=[CAShapeLayer layer];
            self.tickLayer = tickLayer;//记录以便重绘时移除
            tickLayer.path = tickPath.CGPath;
            tickLayer.lineWidth = tickPath.lineWidth;
            tickLayer.fillColor = UIColor.clearColor.CGColor;
            tickLayer.strokeColor = UIColor.whiteColor.CGColor;
            tickLayer.lineCap = kCALineCapRound;//线帽(线的端点)呈圆角状
            tickLayer.lineJoin = kCALineJoinRound;//线连接处呈圆角状
            
            if (self.isAnimation) {
                //3、给CAShapeLayer添加动画
                CABasicAnimation *checkAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
                checkAnimation.duration = 0.25;
                checkAnimation.fromValue = @(0.0f);
                checkAnimation.toValue = @(1.0f);
                [tickLayer addAnimation:checkAnimation forKey:nil];
            }
            
            //4、把CAShapeLayer添加给自己view的layer
            [self.layer addSublayer:tickLayer];
        }
    } else {
        CGPoint center = CGPointMake(rect.size.width*0.5,rect.size.height*0.5);
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:(rect.size.width*0.5 - rect.size.width*0.03) startAngle:0 endAngle:M_PI*2 clockwise:YES];
        [[UIColor.blackColor colorWithAlphaComponent:0.3] setFill];
        [path fill];
        [UIColor.lightGrayColor setStroke];
        [path stroke];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect touchRect = CGRectInset(self.bounds, -20, -20);
    if (CGRectContainsPoint(touchRect, point)) {
        for (UIView *subView in [self.subviews reverseObjectEnumerator]) {
            CGPoint convertedPoint = [subView convertPoint:point fromView:self];
            UIView *hitTestView = [subView hitTest:convertedPoint withEvent:event];
            if(hitTestView) return hitTestView;
        }
        return self;
    }
    return nil;
}

@end

@interface LancooThumbnailListVideoView : UIView

@property (nonatomic, strong) UIImageView *videoBackIV;

@property (nonatomic, strong) UIImageView *videoIconIV;

@property (nonatomic, strong) UILabel *videoTimeLabel;

@end

@implementation LancooThumbnailListVideoView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.videoBackIV];
        
        [self addSubview:self.videoIconIV];
        
        [self addSubview:self.videoTimeLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.videoBackIV.frame = self.bounds;
    
    self.videoIconIV.frame = CGRectMake(5, CGRectGetHeight(self.bounds) - 14.0, 16.0, 12.0);
    
    self.videoTimeLabel.frame = CGRectMake(30.0, CGRectGetHeight(self.bounds) - 14.0, CGRectGetWidth(self.bounds) - 35.0, 12.0);
}

- (UIImageView *)videoBackIV {
    if (!_videoBackIV) {
        _videoBackIV = [[UIImageView alloc] initWithImage:LancooPhotoImage(@"lancoo_videoView")];
    }
    return _videoBackIV;
}

- (UIImageView *)videoIconIV {
    if (!_videoIconIV) {
        _videoIconIV = [[UIImageView alloc] initWithImage:LancooPhotoImage(@"lancoo_video")];
    }
    return _videoIconIV;
}

- (UILabel *)videoTimeLabel {
    if (!_videoTimeLabel) {
        _videoTimeLabel = [[UILabel alloc] init];
        _videoTimeLabel.textAlignment = NSTextAlignmentRight;
        _videoTimeLabel.font = [UIFont systemFontOfSize:13.0f];
        _videoTimeLabel.textColor = UIColor.whiteColor;
    }
    return _videoTimeLabel;
}

@end

@interface LancooThumbnailListCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) LancooThumbnailListTickView *tickView;

@property (nonatomic, strong) LancooThumbnailListVideoView *videoView;

@property (nonatomic, strong) LancooPhotoModel *photoModel;

@property (nonatomic, strong) NSString *assetIdentifier;

@property (nonatomic, assign) PHImageRequestID imageRequestID;

@end

static CGFloat const LancooThumbnailListTickViewSize = 25.0f;

@implementation LancooThumbnailListCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] init];
        _imageView.layer.masksToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_imageView];
        
        _tickView = [[LancooThumbnailListTickView alloc] init];
        [self.contentView addSubview:_tickView];
        
        _videoView = [[LancooThumbnailListVideoView alloc] init];
        _videoView.hidden = YES;
        [self.contentView addSubview:_videoView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _imageView.frame = self.contentView.bounds;
    
    _tickView.frame = CGRectMake(CGRectGetWidth(self.contentView.bounds) - LancooThumbnailListTickViewSize - 5.0f, 5.0f, LancooThumbnailListTickViewSize, LancooThumbnailListTickViewSize);
    
    _videoView.frame = CGRectMake(0, CGRectGetHeight(self.contentView.bounds) - 20.0f, CGRectGetWidth(self.contentView.bounds), 20.0f);
}

- (void)setPhotoModel:(LancooPhotoModel *)photoModel {
    _photoModel = photoModel;
    
    if (photoModel.asset && self.imageRequestID > PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
    }
    self.assetIdentifier = photoModel.asset.localIdentifier;
    self.imageView.image = nil;
    
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    option.networkAccessAllowed = YES;
    __weak typeof(self) weakSelf = self;
    self.imageRequestID = [[PHCachingImageManager defaultManager] requestImageForAsset:photoModel.asset targetSize:CGSizeMake(CGRectGetWidth(self.contentView.bounds) * 2.0, CGRectGetHeight(self.contentView.bounds) * 2.0) contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
        BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey];
        if (downloadFinined && [weakSelf.assetIdentifier isEqualToString:photoModel.asset.localIdentifier]) {
            weakSelf.imageView.image = image;
        }
        if (![[info objectForKey:PHImageResultIsDegradedKey] boolValue]) {
            weakSelf.imageRequestID = -1;
        }
    }];
    
    _tickView.photoModel = photoModel;
    
    _videoView.hidden = YES;
    if (photoModel.asset.mediaType == PHAssetMediaTypeVideo) {
        _videoView.hidden = NO;
        _videoView.videoTimeLabel.text = LancooAssetDurationFormat(photoModel.asset);
    }
}

@end

@interface LancooThumbnailCameraCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutPut;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

- (void)startCapture;

- (void)restartCapture;

@end

@implementation LancooThumbnailCameraCell

- (void)dealloc {
    if ([_session isRunning]) {
        [_session stopRunning];
    }
    _session = nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithImage:LancooPhotoImage(@"lancoo_takePhoto")];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        CGFloat width = CGRectGetHeight(self.bounds) / 3;
        self.imageView.frame = CGRectMake(0, 0, width, width);
        self.imageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        [self addSubview:self.imageView];
        self.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    }
    return self;
}

- (void)restartCapture {
    [self.session stopRunning];
    [self startCapture];
}

- (void)startCapture {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ||
        status == AVAuthorizationStatusRestricted ||
        status == AVAuthorizationStatusDenied) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (!granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.session stopRunning];
                [weakSelf.previewLayer removeFromSuperlayer];
            });
        }
    }];
    
    if (self.session && [self.session isRunning]) {
        return;
    }
    
    [self.session stopRunning];
    [self.session removeInput:self.videoInput];
    [self.session removeOutput:self.stillImageOutPut];
    self.session = nil;
    [self.previewLayer removeFromSuperlayer];
    self.previewLayer = nil;
    
    self.session = [[AVCaptureSession alloc] init];
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[self backCamera] error:nil];
    self.stillImageOutPut = [[AVCaptureStillImageOutput alloc] init];
    
    //这是输出流的设置参数AVVideoCodecJPEG参数表示以JPEG的图片格式输出图片
    NSDictionary *dicOutputSetting = [NSDictionary dictionaryWithObject:AVVideoCodecJPEG forKey:AVVideoCodecKey];
    [self.stillImageOutPut setOutputSettings:dicOutputSetting];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutPut]) {
        [self.session addOutput:self.stillImageOutPut];
    }
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.contentView.layer setMasksToBounds:YES];
    
    self.previewLayer.frame = self.contentView.layer.bounds;
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.contentView.layer insertSublayer:self.previewLayer atIndex:0];

    [self.session startRunning];
}

- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

@end

@interface LancooThumbnailListController () <UICollectionViewDataSource, UICollectionViewDelegate, LancooThumbnailListFooterViewDelegate>

@property (nonatomic, strong) LancooThumbnailListFooterView *footerView;

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, assign) BOOL allowTakePhoto;

@end

@implementation LancooThumbnailListController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(assetDidChangedNotification) name:LancooPhotoNotificationSelectedAssetsDidChanged object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSNotificationCenter.defaultCenter removeObserver:self name:LancooPhotoNotificationSelectedAssetsDidChanged object:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationItem.title = self.albumModel.albumName;
    
    self.footerView.selectedCount = LancooPhotoManager.defaultManager.selectedAssets.count;
    [self.view addSubview:self.footerView];
    
    [self.view addSubview:self.collectionView];
    
    if (@available(iOS 11.0, *)) {
        UIScrollView.appearance.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
}

- (void)cancelAction {
    [NSNotificationCenter.defaultCenter postNotificationName:LancooPhotoNotificationNavigationWillDismiss object:nil];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.footerView.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - LancooThumbnailListFooterViewHeight, CGRectGetWidth(self.view.bounds), LancooThumbnailListFooterViewHeight);
    
    self.collectionView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - LancooThumbnailListFooterViewHeight);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self scrollToBottom];
}

#pragma mark - Notification

- (void)assetDidChangedNotification {
    self.footerView.selectedCount = LancooPhotoManager.defaultManager.selectedAssets.count;
}

#pragma mark - Private Method

- (void)setAlbumModel:(LancooAlbumModel *)albumModel {
    _albumModel = albumModel;
    
    for (LancooPhotoModel *photoModel in albumModel.photos) {
        [LancooPhotoManager.defaultManager.selectedAssets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([photoModel.asset.localIdentifier isEqualToString:obj.localIdentifier]) {
                photoModel.selected = YES;
                *stop = YES;
            }
        }];
    }
    
    LancooPhotoConfiguration *configuration = LancooPhotoManager.defaultManager.configuration;
    if (albumModel.isCameraRoll &&
        configuration.allowTakePhotoInLibrary &&
        (configuration.allowSelectImage || configuration.allowSelectVideo)) {
        self.allowTakePhoto = YES;
    }
}

- (void)scrollToBottom {
    if (!LancooPhotoManager.defaultManager.configuration.sortAscending) {
        return;
    }
    
    if (self.allowTakePhoto) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.albumModel.photos.count inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    } else if (self.albumModel.photos.count > 0) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.albumModel.photos.count - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    }
}

- (void)gotoCustomCamera {
    __weak typeof(self) weakSelf = self;
    LancooAVAuthorizationStatus(^(BOOL isAuthorized) {
        if (isAuthorized) {
            LancooPhotoConfiguration *configuration = LancooPhotoManager.defaultManager.configuration;
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
                
            };
            [weakSelf presentViewController:camera animated:YES completion:nil];
        } else {
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
            [weakSelf presentViewController:alertViewController animated:YES completion:nil];
        }
    });
}

- (void)saveImage:(UIImage *)image videoUrl:(NSURL *)videoUrl {
    if (image) {
        __weak typeof(self) weakSelf = self;
        [LancooPhotoManager saveImageToAblum:image completion:^(BOOL success, PHAsset * _Nonnull asset) {
            if (success) {
                [weakSelf handleDataSource:asset];
            }
        }];
    } else if (videoUrl) {
        __weak typeof(self) weakSelf = self;
        [LancooPhotoManager saveVideoToAblum:videoUrl completion:^(BOOL success, PHAsset * _Nonnull asset) {
            if (success) {
                [weakSelf handleDataSource:asset];
            }
        }];
    }
}

- (void)handleDataSource:(PHAsset *)asset {
    LancooPhotoConfiguration *configuration = LancooPhotoManager.defaultManager.configuration;
    if (LancooPhotoManager.defaultManager.selectedAssets.count < configuration.maxSelectCount) {
        if ((asset.mediaType == PHAssetMediaTypeImage && configuration.allowSelectImage) ||
            (asset.mediaType == PHAssetMediaTypeVideo && configuration.allowSelectVideo)) {
            [LancooPhotoManager.defaultManager.selectedAssets addObject:asset];
            [NSNotificationCenter.defaultCenter postNotificationName:LancooPhotoNotificationSelectedAssetsDidChanged object:nil];
        }
    }
    
    if (self.updateDataSource) self.updateDataSource(^(LancooAlbumModel * _Nonnull albumModel) {
        self.albumModel = albumModel;
        [self.collectionView reloadData];
    });
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.allowTakePhoto) {
        return self.albumModel.photos.count + 1;;
    }
    return self.albumModel.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.allowTakePhoto) {
        LancooPhotoConfiguration *configuration = LancooPhotoManager.defaultManager.configuration;
        if ((configuration.sortAscending && indexPath.row == self.albumModel.photos.count) ||
            (!configuration.sortAscending && indexPath.row == 0)) {
            LancooThumbnailCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(LancooThumbnailCameraCell.class) forIndexPath:indexPath];
            if (configuration.showCaptureImageOnTakePhotoBtn) {
                [cell startCapture];
            }
            return cell;
        }
    }
    LancooThumbnailListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(LancooThumbnailListCell.class) forIndexPath:indexPath];
    cell.photoModel = self.albumModel.photos[indexPath.row];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    if (self.allowTakePhoto) {
        LancooPhotoConfiguration *configuration = LancooPhotoManager.defaultManager.configuration;
        if ((configuration.sortAscending && indexPath.row == self.albumModel.photos.count) ||
            (!configuration.sortAscending && indexPath.row == 0)) { // 拍照
            [self gotoCustomCamera];
            return;
        }
    }
}

#pragma mark - LancooThumbnailListFooterViewDelegate

- (void)ensureButtonDidClicked {
    [NSNotificationCenter.defaultCenter postNotificationName:LancooPhotoNotificationEnsureCompletion object:nil];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - LazyLoading

- (LancooThumbnailListFooterView *)footerView {
    if (!_footerView) {
        _footerView = [[LancooThumbnailListFooterView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - LancooThumbnailListFooterViewHeight, CGRectGetWidth(self.view.frame), LancooThumbnailListFooterViewHeight)];
        _footerView.delegate = self;
    }
    return _footerView;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat itemWidth = (UIScreen.mainScreen.bounds.size.width - 5 * 4) / 3.0;
        flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);
        flowLayout.minimumLineSpacing = 5.0f;
        flowLayout.minimumInteritemSpacing = 5.0f;
        flowLayout.sectionInset = UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f);
        flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.bounces = YES;
        _collectionView.showsVerticalScrollIndicator = YES;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.backgroundColor = UIColor.whiteColor;
        [_collectionView registerClass:LancooThumbnailListCell.class forCellWithReuseIdentifier:NSStringFromClass(LancooThumbnailListCell.class)];
        [_collectionView registerClass:LancooThumbnailCameraCell.class forCellWithReuseIdentifier:NSStringFromClass(LancooThumbnailCameraCell.class)];
    }
    return _collectionView;
}

@end
