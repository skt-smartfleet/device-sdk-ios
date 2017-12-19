#import "AppDelegate.h"     // Header
#import "ViewController.h"

static int s_prgCounter;

@implementation AppDelegate
@synthesize strLogMeg;
@synthesize strHost, strPort, strUserName, strClientId, strTopic, nQos, isRetained;

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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    // Override point for customization after application launch.
    if([AppDelegate loadFromUserDefaults:@"Host"] == nil){
        strHost = MQTT_SERVER_HOST;
        strPort = MQTT_SERVER_PORT;
        strUserName = MQTT_USER_NAME;
        strTopic = SUBSCRIBE_TOPIC;
        
        [AppDelegate saveFromUserDefaults:strHost forKey:@"Host"];
        [AppDelegate saveFromUserDefaults:strPort forKey:@"Port"];
        [AppDelegate saveFromUserDefaults:strUserName forKey:@"UserName"];
        [AppDelegate saveFromUserDefaults:strTopic forKey:@"Topic"];
    }
    else{
        strHost = [AppDelegate loadFromUserDefaults:@"Host"];
        strPort = [AppDelegate loadFromUserDefaults:@"Port"];
        strUserName = [AppDelegate loadFromUserDefaults:@"UserName"];
        strTopic = [AppDelegate loadFromUserDefaults:@"Topic"];
    }
    
    nQos = 1;
    
    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"yyyyMMddhhmmss"];
    NSString *logTimestamp = [DateFormatter stringFromDate:[NSDate date]];
    
    strClientId = [NSString stringWithFormat:@"TRE%@",logTimestamp];
    isRetained = NO;
    
    [AppDelegate instance].strLogMeg = [[NSMutableString alloc] initWithCapacity:100000];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    ViewController* vc = [[ViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication*)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication*)application
{
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
