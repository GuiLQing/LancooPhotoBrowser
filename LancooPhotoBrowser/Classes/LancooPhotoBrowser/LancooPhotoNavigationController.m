//
//  LancooPhotoNavigationController.m
//  LancooPhotoBrowserDemo
//
//  Created by lancoo on 2021/1/20.
//  Copyright © 2021 lancoo. All rights reserved.
//

#import "LancooPhotoNavigationController.h"

@interface LancooPhotoNavigationController ()

@end

@implementation LancooPhotoNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        
        self.navigationBar.translucent = NO;
        self.navigationBar.tintColor = [UIColor blackColor];
        self.navigationBar.topItem.title = @"";
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

@end
