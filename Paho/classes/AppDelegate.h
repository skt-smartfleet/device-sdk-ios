//
//  AppDelegate.h
//  TRemotEye
//
//  Created by boxer on 2017. 9. 20..
//  Copyright © 2017년 Park. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, MBProgressHUDDelegate>
{
    NSMutableString *strLogMeg;
    NSString *strHost;
    NSString *strPort;
    NSString *strUserName;
    NSString *strClientId;
    NSString *strTopic;
    int nQos;
    BOOL isRetained;
}

@property (nonatomic) MBProgressHUD* prgIndicatorView;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSMutableString *strLogMeg;
@property (strong, nonatomic) NSString *strHost;
@property (strong, nonatomic) NSString *strPort;
@property (strong, nonatomic) NSString *strUserName;
@property (strong, nonatomic) NSString *strClientId;
@property (strong, nonatomic) NSString *strTopic;
@property (nonatomic) int nQos;
@property (nonatomic) BOOL isRetained;

+ (AppDelegate*)instance;
+ (id)loadFromUserDefaults:(id)key;
+ (BOOL)saveFromUserDefaults:(id)object forKey:(id)key;

+ (void)showProgressIndicator:(NSObject*)caller;
+ (void)dismissProgressIndicator:(NSObject*)caller;
+ (void)disableProgressIndicator:(BOOL)disable;

@end

