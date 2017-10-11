//
//  ViewController.m
//  TRemotEye
//
//  Created by boxer on 2017. 9. 20..
//  Copyright © 2017년 Park. All rights reserved.
//
#include <stdlib.h>

#import "ViewController.h"
#import "AppDelegate.h"
#import "NHCNavigationBar.h"
#import "ConfigViewController.h"
#import "Messenger.h"
#import "LogMessage.h"
#import "TripListCell.h"

typedef enum
{
    TripEm0       = 1 << 0, // 급출발
    TripEm1       = 1 << 1, // 급좌회전
    TripEm2       = 1 << 2, // 급우회전
    TripEm3       = 1 << 3, // 급유턴
    TripEm4       = 1 << 4, // 급감속
    TripEm5       = 1 << 5, // 급가속
    TripEm6       = 1 << 6, // 급정지
    TripEm7       = 1 << 7, // Reserved

} TripEm;

typedef enum
{
    HFDcm0       = 1 << 0, // 엔진 부하
    HFDcm1       = 1 << 1, // TBD
    HFDcm2       = 1 << 2, // TBD
    HFDcm3       = 1 << 3, // TBD
    HFDcm4       = 1 << 4, // TBD
    HFDcm5       = 1 << 5, // TBD
    HFDcm6       = 1 << 6, // TBD
    HFDcm7       = 1 << 7, // TBD
    
} HFDcm;

@interface ViewController () <UITextViewDelegate, UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UITextView *tvfLog;
    IBOutlet UITableView *tvTrip;
    IBOutlet UILabel *lblTrip;
    IBOutlet UIButton *btnConnect;
    
    NSDictionary *dicPayload;
    
    IBOutlet UIView *viewCombo;
    NSString *strSelectTrip;
    
    int nAutoCount;
    BOOL isAutoPublic;
    
    NSTimer *imeoutTimer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [NHCNavigationBar navigationBarTitleViewController:self withTitle:@"T-RemotEye"];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"payload" ofType:@"plist"];
    dicPayload = [[NSDictionary alloc] initWithContentsOfFile:path];
    nAutoCount = 1;
    lblTrip.text = [dicPayload objectForKey:@"TRE4"];
    strSelectTrip = @"TRE4";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadLogMeg:) name:@"LogReload" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LogReload" object:nil];
}

- (NSString *)setPayload:(NSString *)path{
    NSMutableDictionary *dicTripPayload = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    
    if([strSelectTrip isEqualToString:@"TRE3"]){
        // 급유턴 | 급가속 | 급정지
        NSString *strEM = [[NSString alloc] initWithFormat:@"%02x", TripEm3 | TripEm5 | TripEm6];
        
        [dicTripPayload removeObjectForKey:@"em"];
        [dicTripPayload setValue:strEM forKey:@"em"];
    }
    else if([strSelectTrip isEqualToString:@"TRE6"]){
        // 엔진 부하
        NSString *strCM = [[NSString alloc] initWithFormat:@"%02x", HFDcm0];
        
        [dicTripPayload removeObjectForKey:@"cm"];
        [dicTripPayload setValue:strCM forKey:@"cm"];
    }
    
    NSDictionary *dicHeaderpayload = @{@"ty":@"1", @"ts":@"", @"ap":@"", @"pld":dicTripPayload};
    NSString *jsonString = @"";
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dicHeaderpayload
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return jsonString;
}

#pragma mark - IBAction
-(IBAction)onConfig:(id)sender{
    ConfigViewController* configViewController = [[ConfigViewController alloc] initWithNibName:@"ConfigViewController" bundle:nil];
    [self.navigationController pushViewController:configViewController animated:YES];
}

- (IBAction)onConnect:(UIButton*)button{
    if ([[button currentTitle]  isEqual:@"Connect"]) {
     
        NSArray *servers = [self parseCommaList:[AppDelegate instance].strHost];
        NSArray *ports = [self parseCommaList:[AppDelegate instance].strPort];
        
        // Only generate a new unique clientID if this client doesn't already have one.
        NSString *clientID = [[Messenger sharedMessenger] clientID];
        if (clientID == NULL) {
            clientID = [self uniqueId];
            [[Messenger sharedMessenger] setClientID:clientID];  
        }
        [[Messenger sharedMessenger] connectWithHosts:servers
                                                ports:ports
                                             clientId:clientID
                                             userName:[AppDelegate instance].strToken
                                         cleanSession:YES];
    } else {
        [[Messenger sharedMessenger] disconnectWithTimeout:5];
        [self stopTimer];
    }
}

- (IBAction)onPublish:(id)sender{
    if([btnConnect.titleLabel.text isEqualToString:@"Connect"]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"No connected server" delegate:self cancelButtonTitle:@"확인" otherButtonTitles:nil, nil];
        [alert show];
        
        return;
    }
    
    if(!isAutoPublic){
        NSString *path = [[NSBundle mainBundle] pathForResource:strSelectTrip ofType:@"plist"];
        
        if(path != nil){
            [[Messenger sharedMessenger] publish:[AppDelegate instance].strTopic
                                         payload:[self setPayload:path]
                                             qos:[AppDelegate instance].nQos
                                        retained:[AppDelegate instance].isRetained];
        }
        else{
            [[Messenger sharedMessenger] publish:[AppDelegate instance].strTopic
                                         payload:@"No Trip"
                                             qos:[AppDelegate instance].nQos
                                        retained:[AppDelegate instance].isRetained];
        }
        
    }
}

- (IBAction)onAutoPublish:(id)sender{
    if([btnConnect.titleLabel.text isEqualToString:@"Connect"]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"No connected server" delegate:self cancelButtonTitle:@"확인" otherButtonTitles:nil, nil];
        [alert show];
        
        return;
    }

    if(!isAutoPublic){
        isAutoPublic = YES;
        imeoutTimer = [NSTimer scheduledTimerWithTimeInterval:2
                                                            target:self
                                                          selector:@selector(timeoutHandler:)
                                                          userInfo:nil
                                                           repeats:YES]; //10초
    }
}

- (void)timeoutHandler:(NSTimer*)timer
{
    NSLog(@"nAutoCount [%d]", nAutoCount);

    NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"TRE%d", nAutoCount] ofType:@"plist"];
    
    if(path != nil){
        [[Messenger sharedMessenger] publish:[AppDelegate instance].strTopic
                                     payload:[self setPayload:path]
                                         qos:[AppDelegate instance].nQos
                                    retained:[AppDelegate instance].isRetained];
    }
    else{
        [[Messenger sharedMessenger] publish:[AppDelegate instance].strTopic
                                     payload:@"No Trip"
                                         qos:[AppDelegate instance].nQos
                                    retained:[AppDelegate instance].isRetained];
    }
    
    if(++nAutoCount > 12){
        [self stopTimer];
    }
}

- (void)stopTimer{
    nAutoCount = 1;
    isAutoPublic = NO;
    [imeoutTimer invalidate];
}

- (IBAction)onComboBox:(id)sender{
    if(viewCombo.isHidden){
        viewCombo.hidden = NO;
    }
}

- (IBAction)onComboClose:(id)sender{
    viewCombo.hidden = YES;
}

- (NSString*) uniqueId {
    return [NSString stringWithFormat: @"MQTTTest.%d", arc4random_uniform(10000)];
}

- (NSArray*) parseCommaList:(NSString*)field {
    return [field componentsSeparatedByString:@","];
}

- (void)reloadLogMeg:(id)sender{
    NSLog(@"reloadLogMeg!!!!!!!!!!!!");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        Messenger *messenger = [Messenger sharedMessenger];
        
        LogMessage *message = [messenger.logMessages objectAtIndex:messenger.logMessages.count - 1];
        
        if([message.type isEqualToString:@"Connect"]){
            [btnConnect setTitle:@"Disconnect" forState:UIControlStateNormal];
            
            [[Messenger sharedMessenger] subscribe:[AppDelegate instance].strTopic
                                               qos:[AppDelegate instance].nQos];
        }
        else if([message.type isEqualToString:@"ConnectFail"] || [message.type isEqualToString:@"DisConnect"]){
            [btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
        }
        
        [[AppDelegate instance].strLogMeg appendFormat:@"[%@] %@ %@\n",message.type, message.data, message.timestamp];
        
        tvfLog.text = [AppDelegate instance].strLogMeg;
        
        if(tvfLog.text.length > 0 ) {
            NSRange bottom = NSMakeRange(tvfLog.text.length -1, 1);
            [tvfLog scrollRangeToVisible:bottom];
        }
    });
}

#pragma mark - Table View Data Source Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return dicPayload.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"TripListCell";
    TripListCell *cell = (TripListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TripListCell" owner:self options:nil];
        
        cell = (TripListCell *)[nib objectAtIndex:0];
    }
    
    cell.lblName.text = [dicPayload objectForKey:[NSString stringWithFormat:@"TRE%ld", indexPath.row + 1]];
    
    if([strSelectTrip isEqualToString:[NSString stringWithFormat:@"TRE%ld", indexPath.row + 1]]){
        cell.btnSelect.selected = YES;
    }
    else{
        cell.btnSelect.selected = NO;
    }
    
    return cell;
}

#pragma mark - Table Delegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    viewCombo.hidden = YES;
    lblTrip.text = [dicPayload objectForKey:[NSString stringWithFormat:@"TRE%ld", indexPath.row + 1]];
    strSelectTrip = [NSString stringWithFormat:@"TRE%ld", indexPath.row + 1];
    [tvTrip reloadData];
}

@end
