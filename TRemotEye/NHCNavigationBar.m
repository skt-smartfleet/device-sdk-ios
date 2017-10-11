//
//  NHCNavigationBar.m
//  NHCardPay
//
//  Created by boxer on 2016. 8. 17..
//  Copyright © 2016년 Nonghyup. All rights reserved.
//

#import "NHCNavigationBar.h"

@implementation NHCNavigationBar

+ (void)navigationBarTitleViewController:(UIViewController *)controller withTitle:(NSString *)title {
    [controller.navigationController setNavigationBarHidden:NO];
    
    UILabel *lbTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    lbTitle.text = title;
    lbTitle.textColor = RGB(51, 51, 51);
    lbTitle.textAlignment = NSTextAlignmentCenter;
    lbTitle.font = [UIFont systemFontOfSize:16.0f];
    lbTitle.contentMode = UIViewContentModeCenter;
    
    controller.navigationController.navigationBar.translucent = NO;
    controller.navigationController.navigationBar.barTintColor = RGB(255, 255, 255);
    [controller.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    controller.navigationController.navigationBar.shadowImage = [UIImage new];
    [controller.navigationItem setTitleView:lbTitle];
    controller.navigationItem.titleView.alpha = 0.f;
    
    controller.navigationController.navigationBar.shadowImage = [UIImage imageNamed:@"img_title_shadow"];
    
    [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        controller.navigationItem.titleView.alpha = 1.f;
    } completion:nil];
}

+ (void)navigationBarTitleViewController:(UIViewController *)controller withImage:(NSString *)imgName {
    
    UIImageView *imgTitle = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgName]];
    imgTitle.frame = CGRectMake(0, 0, 200, 44);
    imgTitle.contentMode = UIViewContentModeCenter;
     
    controller.navigationController.navigationBar.translucent = NO;
    controller.navigationController.navigationBar.barTintColor = RGB(255, 255, 255);
    [controller.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    controller.navigationController.navigationBar.shadowImage = [UIImage imageNamed:@"img_title_shadow"];
    [controller.navigationItem setTitleView:imgTitle];
}

+ (UIBarButtonItem *)hideLeftButton:(UIViewController *)controller {
    UIBarButtonItem* barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIView alloc] init]];
    barButtonItem.enabled = NO;
    barButtonItem.tintColor = [UIColor clearColor];
    
    [controller.navigationItem setHidesBackButton:YES];
    [controller.navigationItem setLeftBarButtonItems:@[barButtonItem] animated:NO];
    
    return barButtonItem;
}

+ (UIBarButtonItem *)hideRightButton:(UIViewController *)controller {
    UIBarButtonItem* barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIView alloc] init]];
    barButtonItem.enabled = NO;
    barButtonItem.tintColor = [UIColor clearColor];
    
    [controller.navigationItem setHidesBackButton:YES];
    [controller.navigationItem setRightBarButtonItems:@[barButtonItem] animated:NO];
    
    return barButtonItem;
}


+ (UIBarButtonItem *)createBarButtonItemForViewController:(UIViewController *)controller
                                            withImageName:(NSString *)imageName
                                               withAction:(SEL)action {
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 15, 16)];
    
    NSString *nomalImageName = [NSString stringWithFormat:@"%@", imageName];
    NSString *highlightedImageName = [NSString stringWithFormat:@"%@", imageName];
    
    [button setBackgroundImage:[UIImage imageNamed:nomalImageName]
                      forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:highlightedImageName]
                      forState:UIControlStateHighlighted];
    
    [button addTarget:controller
               action:action
     forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return barButtonItem;
}

+ (UIBarButtonItem *)drawMainMenuButton:(UIViewController *)controller withAction:(SEL)action {
    
    //이전 버튼
    UIBarButtonItem *barButtonItem = [NHCNavigationBar createBarButtonItemForViewController:controller withImageName:@"top_home" withAction:action];
    
    [controller.navigationItem setHidesBackButton:YES];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)
        [negativeSpacer setWidth:-16];
    
    [controller.navigationItem setLeftBarButtonItems:@[negativeSpacer, barButtonItem] animated:NO];
    
    [barButtonItem setAccessibilityLabel:@"이전"];
    
    return barButtonItem;
}

+ (UIBarButtonItem *)drawBackButton:(UIViewController *)controller withAction:(SEL)action {
    
    //이전 버튼
    UIBarButtonItem *barButtonItem = [NHCNavigationBar createBarButtonItemForViewController:controller withImageName:@"top_pre" withAction:action];
    
    [controller.navigationItem setHidesBackButton:YES];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    
    [controller.navigationItem setLeftBarButtonItems:@[negativeSpacer, barButtonItem] animated:NO];
    
    [barButtonItem setAccessibilityLabel:@"이전"];
    
    return barButtonItem;
}

+ (UIBarButtonItem *)drawCloseButton:(UIViewController *)controller withAction:(SEL)action {
    
    NSString *imgName = @"btn_main_close";
    if ([NSStringFromClass([controller class]) isEqualToString:@"NHCQuickPayViewController"]) {
        imgName = @"btn_main_cancel";
    }
    
    //닫기 버튼
    UIBarButtonItem *barButtonItem = [NHCNavigationBar createBarButtonItemForViewController:controller withImageName:imgName withAction:action];
    
    [controller.navigationItem setHidesBackButton:YES];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)
        [negativeSpacer setWidth:-16];
    
    [controller.navigationItem setRightBarButtonItems:@[negativeSpacer, barButtonItem] animated:NO];
    
    [barButtonItem setAccessibilityLabel:@"닫기"];
    
    return barButtonItem;
}


+ (UIBarButtonItem *)drawNextButton:(UIViewController *)controller withAction:(SEL)action {
    
    //다음 버튼
    UIBarButtonItem *barButtonItem = [NHCNavigationBar createBarButtonItemForViewController:controller withImageName:@"btn_title_next" withAction:action];
    
    [controller.navigationItem setHidesBackButton:YES];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)
        [negativeSpacer setWidth:-16];
    
    [controller.navigationItem setRightBarButtonItems:@[negativeSpacer, barButtonItem] animated:NO];
    
    [barButtonItem setAccessibilityLabel:@"다음"];
    
    return barButtonItem;
}

+ (UIBarButtonItem *)drawReloadButton:(UIViewController *)controller withAction:(SEL)action {
    
    //확인 버튼
    UIBarButtonItem *barButtonItem = [NHCNavigationBar createBarButtonItemForViewController:controller withImageName:@"top_reload" withAction:action];
    
    [controller.navigationItem setHidesBackButton:YES];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    
    [controller.navigationItem setRightBarButtonItems:@[negativeSpacer, barButtonItem] animated:NO];
    
    [barButtonItem setAccessibilityLabel:@"확인"];
    
    return barButtonItem;
}

+ (UIBarButtonItem *)drawCompleteButton:(UIViewController *)controller withAction:(SEL)action {
    
    //완료 버튼
    UIBarButtonItem *barButtonItem = [NHCNavigationBar createBarButtonItemForViewController:controller withImageName:@"btn_title_complete" withAction:action];
    
    [controller.navigationItem setHidesBackButton:YES];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)
        [negativeSpacer setWidth:-16];
    
    [controller.navigationItem setRightBarButtonItems:@[negativeSpacer, barButtonItem] animated:NO];
    
    [barButtonItem setAccessibilityLabel:@"완료"];
    
    return barButtonItem;
}

+ (UIBarButtonItem *)drawCancelButton:(UIViewController *)controller withAction:(SEL)action {
    
    //취소 버튼
    UIBarButtonItem *barButtonItem = [NHCNavigationBar createBarButtonItemForViewController:controller withImageName:@"btn_title_cancel" withAction:action];
    
    [controller.navigationItem setHidesBackButton:YES];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)
        [negativeSpacer setWidth:-16];
    
    [controller.navigationItem setLeftBarButtonItems:@[negativeSpacer, barButtonItem] animated:NO];
    
    [barButtonItem setAccessibilityLabel:@"취소"];
    
    return barButtonItem;
}

+ (UIBarButtonItem *)drawHomeButton:(UIViewController *)controller withAction:(SEL)action {
    
    //홈 버튼
    UIBarButtonItem *barButtonItem = [NHCNavigationBar createBarButtonItemForViewController:controller withImageName:@"top_home" withAction:action];
    
    [controller.navigationItem setHidesBackButton:YES];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    
    [controller.navigationItem setLeftBarButtonItems:@[negativeSpacer, barButtonItem] animated:NO];
    
    [barButtonItem setAccessibilityLabel:@"홈"];
    
    return barButtonItem;
}



+ (UIBarButtonItem *)drawBackButton:(UIViewController *)controller withTitle:(NSString *)title withAction:(SEL)action {
    
    NSString *paddedTitle = [NSString stringWithFormat:@"  %@", title];
    
    UIBarButtonItem *barButtonItem = [NHCNavigationBar createBarButtonItemForViewController:controller withTitle:paddedTitle withImageName:@"title_btn_back_bg" withAction:action];
    
    [controller.navigationItem setHidesBackButton:YES];
    [controller.navigationItem setLeftBarButtonItem:barButtonItem];
    
    [barButtonItem setAccessibilityLabel:@"이전"];
    
    return barButtonItem;
}

+ (UIBarButtonItem *)drawNextButton:(UIViewController *)controller withTitle:(NSString *)title withAction:(SEL)action {
    
    UIBarButtonItem *barButtonItem = [NHCNavigationBar createBarButtonItemForViewController:controller withTitle:title withImageName:@"title_btn_next_bg" withAction:action];
    
    [controller.navigationItem setRightBarButtonItem:barButtonItem];
    
    [barButtonItem setAccessibilityLabel:@"다음"];
    
    return barButtonItem;
}

+ (UIBarButtonItem *)drawCancelButton:(UIViewController *)controller withTitle:(NSString *)title withAction:(SEL)action {
    
    UIBarButtonItem *barButtonItem = [NHCNavigationBar createBarButtonItemForViewController:controller withTitle:title withImageName:@"title_btn_ok_bg" withAction:action];
    
    [controller.navigationItem setHidesBackButton:YES];
    [controller.navigationItem setLeftBarButtonItem:barButtonItem];
    
    return barButtonItem;
}

+ (UIBarButtonItem *)drawRightButton:(UIViewController *)controller withTitle:(NSString *)title withAction:(SEL)action {
    
    UIBarButtonItem *barButtonItem = [NHCNavigationBar createBarButtonItemForViewController:controller withTitle:title withImageName:@"title_btn_ok_bg" withAction:action];
    
    [controller.navigationItem setRightBarButtonItem:barButtonItem];
    
    return barButtonItem;
}

+ (UIBarButtonItem *)drawRightImageButton:(UIViewController *)controller withImageName:(NSString *)imageName withAction:(SEL)action {
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 44)];
    
    NSString *highlightedImageName = [NSString stringWithFormat:@"%@_ov", imageName];
    
    [button setBackgroundImage:[UIImage imageNamed:imageName]
                      forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:highlightedImageName]
                      forState:UIControlStateHighlighted];
    
    [button addTarget:controller
               action:action
     forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)
        [negativeSpacer setWidth:-12];
    
    [controller.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:negativeSpacer, barButtonItem, nil]];
    
    return barButtonItem;
}

+ (UIBarButtonItem *)createBarButtonItemForViewController:(UIViewController *)controller
                                                withTitle:(NSString *)title
                                            withImageName:(NSString *)imageName
                                               withAction:(SEL)action {
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 43, 28)];
    
    NSString *highlightedImageName = [NSString stringWithFormat:@"%@_ov", imageName];
    
    [button setBackgroundImage:[UIImage imageNamed:imageName]
                      forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:highlightedImageName]
                      forState:UIControlStateHighlighted];
    
    button.titleLabel.font = [UIFont systemFontOfSize:12];
    button.titleLabel.adjustsFontSizeToFitWidth = TRUE;
    [button setTitle:title forState:UIControlStateNormal];
    
    UIColor *textColor = [UIColor colorWithRed:(100.0 / 255) green:(100.0 / 255) blue:(100.0 / 255) alpha:1.0f];
    [button setTitleColor:textColor forState:UIControlStateNormal];
    
    [button addTarget:controller
               action:action
     forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return barButtonItem;
}


@end
