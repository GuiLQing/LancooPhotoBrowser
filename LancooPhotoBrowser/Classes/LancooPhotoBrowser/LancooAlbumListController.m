//
//  LancooAlbumListController.m
//  LancooPhotoBrowserDemo
//
//  Created by lancoo on 2021/1/18.
//  Copyright © 2021 lancoo. All rights reserved.
//

#import "LancooAlbumListController.h"
#import "LancooThumbnailListController.h"

@interface LancooAlbumListCell : UITableViewCell

@property (nonatomic, strong) UIImageView *coverImageView;

@property (nonatomic, strong) UILabel *albumNameLabel;

@property (nonatomic, strong) UILabel *photoCountLabel;

@property (nonatomic, strong) LancooAlbumModel *albumModel;

@property (nonatomic, strong) NSString *assetIdentifier;

@property (nonatomic, assign) PHImageRequestID imageRequestID;


@end

@implementation LancooAlbumListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.layer.masksToBounds = YES;
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_coverImageView];
        
        _albumNameLabel = [[UILabel alloc] init];
        _albumNameLabel.textColor = UIColor.blackColor;
        _albumNameLabel.font = [UIFont systemFontOfSize:16.0f];
        _albumNameLabel.numberOfLines = 2;
        _albumNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_albumNameLabel];
        
        _photoCountLabel = [[UILabel alloc] init];
        _photoCountLabel.textColor = UIColor.lightGrayColor;
        _photoCountLabel.font = [UIFont systemFontOfSize:16.0f];
        _photoCountLabel.numberOfLines = 1;
        [self.contentView addSubview:_photoCountLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _coverImageView.frame = CGRectMake(10.0f, 5.0f, CGRectGetHeight(self.contentView.bounds) - 10.0f, CGRectGetHeight(self.contentView.bounds) - 10.0f);
    
    CGSize photoCountSize = [_photoCountLabel sizeThatFits:CGSizeMake((CGRectGetWidth(self.contentView.bounds) - CGRectGetMaxX(_coverImageView.frame) - 10.0f * 3) * 0.5, CGRectGetHeight(_coverImageView.bounds))];
    CGSize albumNameSize = [_albumNameLabel sizeThatFits:CGSizeMake(CGRectGetWidth(self.contentView.bounds) - CGRectGetMaxX(_coverImageView.frame) - photoCountSize.width - 10.0f * 3, CGRectGetHeight(_coverImageView.bounds))];
    
    _albumNameLabel.frame = CGRectMake(CGRectGetMaxX(_coverImageView.frame) + 10.0f, (CGRectGetHeight(self.contentView.bounds) - albumNameSize.height) * 0.5, albumNameSize.width, albumNameSize.height);
    _photoCountLabel.frame = CGRectMake(CGRectGetMaxX(_albumNameLabel.frame), (CGRectGetHeight(self.contentView.bounds) - photoCountSize.height) * 0.5, photoCountSize.width, photoCountSize.height);
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    [UIView animateWithDuration:0.25 animations:^{
        if (highlighted) {
            self.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
        } else {
            self.backgroundColor = [UIColor whiteColor];
        }
    }];
}

- (void)setAlbumModel:(LancooAlbumModel *)albumModel {
    _albumModel = albumModel;
    
    if (albumModel.coverAsset && self.imageRequestID > PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
    }
    self.assetIdentifier = albumModel.coverAsset.localIdentifier;
    self.coverImageView.image = nil;
    
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    option.networkAccessAllowed = YES;
    self.imageRequestID = [[PHCachingImageManager defaultManager] requestImageForAsset:albumModel.coverAsset targetSize:CGSizeMake(CGRectGetWidth(self.coverImageView.bounds) * 2.0, CGRectGetHeight(self.coverImageView.bounds) * 2.0) contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
        BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey];
        if (downloadFinined && [self.assetIdentifier isEqualToString:albumModel.coverAsset.localIdentifier]) {
            self.coverImageView.image = image;
        }
        if (![[info objectForKey:PHImageResultIsDegradedKey] boolValue]) {
            self.imageRequestID = -1;
        }
    }];
    
    self.albumNameLabel.text = albumModel.albumName;
    self.photoCountLabel.text = [NSString stringWithFormat:@"（%zd）", albumModel.photoCount];
}

@end

@interface LancooAlbumListController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation LancooAlbumListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"照片";
    
    if (@available(iOS 11.0, *)) {
        UIScrollView.appearance.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        UITableView.appearance.estimatedRowHeight = 0;
        UITableView.appearance.estimatedSectionHeaderHeight = 0;
        UITableView.appearance.estimatedSectionFooterHeight = 0;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [self.view addSubview:self.tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
}

- (void)cancelAction {
    [NSNotificationCenter.defaultCenter postNotificationName:LancooPhotoNotificationNavigationWillDismiss object:nil];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.tableView.frame = self.view.bounds;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LancooAlbumListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(LancooAlbumListCell.class)];
    if (!cell) {
        cell = [[LancooAlbumListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass(LancooAlbumListCell.class)];
    }
    cell.albumModel = self.dataSource[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return UIView.alloc.init;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return UIView.alloc.init;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    LancooThumbnailListController *thumbnailListVC = [[LancooThumbnailListController alloc] init];
    thumbnailListVC.albumModel = self.dataSource[indexPath.row];
    [self.navigationController pushViewController:thumbnailListVC animated:YES];
}

#pragma mark - LazyLoading

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.showsVerticalScrollIndicator = YES;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.bounces = YES;
    }
    return _tableView;
}

@end
