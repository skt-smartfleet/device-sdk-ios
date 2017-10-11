//
//  AppDelegate.m
//  TRemotEye
//
//  Created by boxer on 2017. 9. 20..
//  Copyright © 2017년 Park. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

static int s_prgCounter;

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize strLogMeg;
@synthesize strHost, strPort, strToken, strClientId, strTopic, nQos, isRetained;

+ (AppDelegate*)instance {
    return (AppDelegate*) [UIApplication sharedApplication].delegate;
}

#pragma mark - NSUserDefault
+ (id) loadFromUserDefaults:(id)key{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    id returnVal = nil;
    if(userDefaults && key){
        returnVal = [userDefaults objectForKey:key];
    }
    return returnVal;
}

+ (BOOL) saveFromUserDefaults:(id)object forKey:(id)key{
    BOOL isReturnVal = NO;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    @synchronized (userDefaults) {
        if(userDefaults && key && object){
            [userDefaults setObject:object forKey:key];
        }else{
            [userDefaults removeObjectForKey:key];
        }
        
        isReturnVal = [userDefaults synchronize];
    }
    
    return isReturnVal;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if([AppDelegate loadFromUserDefaults:@"Host"] == nil){
        strHost = @"iot.eclipse.org";
        strPort = @"1883";
        strToken = @"A1_TEST_TOKEN";
        strTopic = @"planets/earth";//@"rpc/request"; //rpc/request/+ , /v1/sensors/me/rpc/request/+
        
        [AppDelegate saveFromUserDefaults:strHost forKey:@"Host"];
        [AppDelegate saveFromUserDefaults:strPort forKey:@"Port"];
        [AppDelegate saveFromUserDefaults:strToken forKey:@"Token"];
        [AppDelegate saveFromUserDefaults:strTopic forKey:@"Topic"];
    }
    else{
        strHost = [AppDelegate loadFromUserDefaults:@"Host"];
        strPort = [AppDelegate loadFromUserDefaults:@"Port"];
        strToken = [AppDelegate loadFromUserDefaults:@"Token"];
        strTopic = [AppDelegate loadFromUserDefaults:@"Topic"];
    }
    
    nQos = 1;
    
    isRetained = NO;
    
    [AppDelegate instance].strLogMeg = [[NSMutableString alloc] initWithCapacity:100000];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    ViewController* vc = [[ViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - MBProgressHUD IndicatorView

+ (void)showProgressIndicator:(NSObject*)caller {
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [appDelegate _showProgressIndicator:caller];
    });
}

+ (void)dismissProgressIndicator:(NSObject*)caller {
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [appDelegate _dismissProgressIndicator:caller];
    });
}

+ (void)disableProgressIndicator:(BOOL)disable {
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [appDelegate _disableProgressIndicator:disable];
    });
}

- (void)_showProgressIndicator:(NSObject*)caller {
    if (s_prgCounter == 0) {
        if (self.prgIndicatorView){
            [self.prgIndicatorView hideAnimated:NO];
        }
        
        self.prgIndicatorView = [MBProgressHUD showHUDAddedTo:self.window animated:NO];
        self.prgIndicatorView.delegate = self;
    }
    
    ++s_prgCounter;
}

- (void)_dismissProgressIndicator:(NSObject*)caller {
    if (s_prgCounter > 0){
        --s_prgCounter;
    }
    
    if (s_prgCounter == 0) {
        [self.prgIndicatorView hideAnimated:NO];
        self.prgIndicatorView = nil;
    }
}

-(void)_disableProgressIndicator:(BOOL)disable {
    if (disable) {
        s_prgCounter = 99999;
        [self.prgIndicatorView hideAnimated:NO];
        self.prgIndicatorView = nil;
    }
    else {
        s_prgCounter = 0;
    }
}

@end
