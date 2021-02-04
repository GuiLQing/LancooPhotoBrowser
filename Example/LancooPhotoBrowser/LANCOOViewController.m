//
//  LANCOOViewController.m
//  LancooPhotoBrowser
//
//  Created by gui950823@126.com on 02/04/2021.
//  Copyright (c) 2021 gui950823@126.com. All rights reserved.
//

#import "LANCOOViewController.h"
#import "LancooPhotoAlertView.h"

@interface LANCOOViewController ()

@property (nonatomic, strong) NSArray *assets;

@end

@implementation LANCOOViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
	self.view.backgroundColor = UIColor.redColor;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    __weak typeof(self) weakSelf = self;
    [LancooPhotoAlertView showPhotoLibraryWithSelectedAssets:self.assets configuration:^(LancooPhotoConfiguration * _Nonnull configuration) {
//        configuration.allowSelectVideo = NO;
    } fromController:self completion:^(NSArray * _Nonnull assets) {
        weakSelf.assets = assets;
    }];
}

@end
