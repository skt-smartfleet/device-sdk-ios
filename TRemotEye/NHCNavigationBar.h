//
//  NHCNavigationBar.h
//  NHCardPay
//
//  Created by boxer on 2016. 8. 17..
//  Copyright © 2016년 Nonghyup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NHCNavigationBar : NSObject

+ (void)navigationBarTitleViewController:(UIViewController *)controller withTitle:(NSString *)title;
+ (void)navigationBarTitleViewController:(UIViewController *)controller withImage:(NSString *)imgName;

+ (UIBarButtonItem *)hideLeftButton:(UIViewController *)controller;
+ (UIBarButtonItem *)hideRightButton:(UIViewController *)controller;

+ (UIBarButtonItem *)drawBackButton:(UIViewController *)controller withAction:(SEL)action;
+ (UIBarButtonItem *)drawCloseButton:(UIViewController *)controller withAction:(SEL)action;
+ (UIBarButtonItem *)drawNextButton:(UIViewController *)controller withAction:(SEL)action;
+ (UIBarButtonItem *)drawReloadButton:(UIViewController *)controller withAction:(SEL)action;
+ (UIBarButtonItem *)drawCompleteButton:(UIViewController *)controller withAction:(SEL)action;
+ (UIBarButtonItem *)drawCancelButton:(UIViewController *)controller withAction:(SEL)action;
+ (UIBarButtonItem *)drawHomeButton:(UIViewController *)controller withAction:(SEL)action;

+ (UIBarButtonItem *)drawBackButton:(UIViewController *)controller withTitle:(NSString *)title withAction:(SEL)action;
+ (UIBarButtonItem *)drawNextButton:(UIViewController *)controller withTitle:(NSString *)title withAction:(SEL)action;
+ (UIBarButtonItem *)drawCancelButton:(UIViewController *)controller withTitle:(NSString *)title withAction:(SEL)action;
+ (UIBarButtonItem *)drawRightButton:(UIViewController *)controller withTitle:(NSString *)title withAction:(SEL)action;
+ (UIBarButtonItem *)drawRightImageButton:(UIViewController *)controller withImageName:(NSString *)imageName withAction:(SEL)action;

+ (UIBarButtonItem *)drawMainMenuButton:(UIViewController *)controller withAction:(SEL)action;
@end
