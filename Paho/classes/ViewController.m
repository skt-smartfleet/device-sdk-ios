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

#import <MQTT/MQTTClient.h> // MQTT
#import <MQTT/MQTTAsync.h>  // MQTT

#pragma mark - C Private prototypes
void mqttConnectionSucceeded(void* context, MQTTAsync_successData* response);
void mqttConnectionFailed(void* context, MQTTAsync_failureData* response);
void mqttConnectionLost(void* context, char* cause);

void mqttSubscriptionSucceeded(void* context, MQTTAsync_successData* response);
void mqttSubscriptionFailed(void* context, MQTTAsync_failureData* response);

void mqttDeliveryComplete(void* context, MQTTAsync_token token);
int mqttMessageArrived(void* context, char* topicName, int topicLen, MQTTAsync_message* message);

void mqttUnsubscriptionSucceeded(void* context, MQTTAsync_successData* response);
void mqttUnsubscriptionFailed(void* context, MQTTAsync_failureData* response);

void mqttPublishSucceeded(void* context, MQTTAsync_successData* response);
void mqttPublishFailed(void* context, MQTTAsync_failureData* response);

void mqttDisconnectionSucceeded(void* context, MQTTAsync_successData* response);
void mqttDisconnectionFailed(void* context, MQTTAsync_failureData* response);


// Micro Trip Payload
// em value
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

// HFD Capability Information
// cm value
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

typedef enum
{
    TYPT_DEVICE_ACTIVATION,
    TYPT_FIRMWARE_UPDATE,
    TYPT_OBD_RESET,
    TYPT_DEVICE_SERIAL_NUMBER_CHECK,
    TYPT_CLEAR_DEVICE_DATA,
    TYPT_FIRMWARE_UPDATE_CHUNK
} RPCType;

static const int RETRY_COUNT = 6;

@interface ViewController () <UITextViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
{
    IBOutlet UITextView *tvfLog;
    IBOutlet UILabel *lblTrip;
    IBOutlet UIPickerView *pickerView;
    IBOutlet UIView *viewCombo;
    
    NSDictionary *dicPayload;
    NSString *strSelectTrip;
    NSString *strTempSelectTrip;
    
    int nAutoCount;
    int nRetryConnect;
    
    BOOL isAutoPublish;
    BOOL isTimerCheck;
    
    NSTimer *imeoutTimer;
    NSTimer *timer;
    
    NSMutableAttributedString *mas;
}

@property (unsafe_unretained,nonatomic) MQTTAsync mqttClient;
@property (unsafe_unretained,nonatomic) NSString *strPublishTopic;
@property (unsafe_unretained,nonatomic) IBOutlet UIButton *btnConnect;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [NHCNavigationBar navigationBarTitleViewController:self withTitle:@"T-RemotEye"];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"payload" ofType:@"plist"];
    dicPayload = [[NSDictionary alloc] initWithContentsOfFile:path];

    lblTrip.text = [dicPayload objectForKey:@"TRE1"];
    strSelectTrip = @"TRE1";
    
    nAutoCount = 1;
    nRetryConnect = 0;
    
    mas = [[NSMutableAttributedString alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LogReload" object:nil];
}

#pragma mark - IBAction
/**
 * MQTT Config 화면 이동
 */
-(IBAction)onConfig:(id)sender{
    ConfigViewController* configViewController = [[ConfigViewController alloc] initWithNibName:@"ConfigViewController" bundle:nil];
    [self.navigationController pushViewController:configViewController animated:YES];
}

/**
 * MQTT Broker에 연결
 */
- (IBAction)onConnect:(UIButton*)button{
    [self serverConnect];
}

/**
 * MQTT Broker에 Publish
 */
- (IBAction)onPublish:(id)sender{
    if([self.btnConnect.titleLabel.text isEqualToString:@"Connect"]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"No connected server" delegate:self cancelButtonTitle:@"확인" otherButtonTitles:nil, nil];
        [alert show];

        return;
    }
    
    if(!isAutoPublish){
        NSString *path = [[NSBundle mainBundle] pathForResource:strSelectTrip ofType:@"plist"];
        
        if([strSelectTrip isEqualToString:@"TRE1"] || [strSelectTrip isEqualToString:@"TRE2"]){
            self.strPublishTopic = PUBLISH_TOPIC_TRE;
        }
        else if([strSelectTrip isEqualToString:@"TRE3"] || [strSelectTrip isEqualToString:@"TRE4"] || [strSelectTrip isEqualToString:@"TRE5"] || [strSelectTrip isEqualToString:@"TRE6"]){
            self.strPublishTopic = PUBLISH_TOPIC_TELEMETRY;
        }
        else if([strSelectTrip isEqualToString:@"TRE7"] || [strSelectTrip isEqualToString:@"TRE8"] || [strSelectTrip isEqualToString:@"TRE9"]){
            self.strPublishTopic = PUBLISH_TOPIC_ATTRIBUTES;
        }
        
        if([strSelectTrip isEqualToString:@"TRE2"]){
            // Micro Trip 일경우 QoS = 0;
            [AppDelegate instance].nQos = 0;
        }
        else{
            [AppDelegate instance].nQos = 1;
        }
        
        __weak ViewController* weakSelf = self;
        
        MQTTAsync_message message = MQTTAsync_message_initializer;
        NSString *strPayload = [self setPayload:path];
        
        message.payloadlen = (int)[strPayload lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        const char *payload = [strPayload UTF8String];
        
        message.payload = (char*)payload;
        
        MQTTAsync_responseOptions pubOptions = MQTTAsync_responseOptions_initializer;
        
        pubOptions.onSuccess = mqttPublishSucceeded;
        pubOptions.onFailure = mqttPublishFailed;
        pubOptions.context = (__bridge void*)weakSelf;
        
        [self setLogMsg:@"Pulbish" logString:[NSString stringWithFormat:@"Message Publishing[%@]%@ Qos:%d", self.strPublishTopic, strPayload, [AppDelegate instance].nQos]];
        
        int status = MQTTAsync_sendMessage(_mqttClient, self.strPublishTopic.UTF8String, &message, &pubOptions);
        
        if (status != MQTTASYNC_SUCCESS) {
        }
    }
}

/**
 * MQTT Broker에 Trip 리스트 자동 Publish
 */
- (IBAction)onAutoPublish:(id)sender{
    if([self.btnConnect.titleLabel.text isEqualToString:@"Connect"]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"No connected server" delegate:self cancelButtonTitle:@"확인" otherButtonTitles:nil, nil];
        [alert show];
        
        return;
    }

    strTempSelectTrip = strSelectTrip;
    
    if(!isAutoPublish){
        isAutoPublish = YES;
        imeoutTimer = [NSTimer scheduledTimerWithTimeInterval:2
                                                            target:self
                                                          selector:@selector(timeoutHandler:)
                                                          userInfo:nil
                                                           repeats:YES];
    }
}

- (IBAction)onComboBox:(id)sender{
    if(viewCombo.isHidden){
        viewCombo.hidden = NO;
    }
}

- (IBAction)onComboClose:(id)sender{
    viewCombo.hidden = YES;
}

#pragma mark - Business Methods
/**
 * MQTT Broker에 연결
 */
- (void)serverConnect{
    int status;

    __weak ViewController* weakSelf = self;
    
    if (_mqttClient == NULL)
    {
        NSLog(@"_mqttClientID[%@] _mqttUsername[%@]", [AppDelegate instance].strClientId, [AppDelegate instance].strUserName);
        
        status = MQTTAsync_create(&_mqttClient, [AppDelegate instance].strHost.UTF8String, [AppDelegate instance].strClientId.UTF8String, MQTTCLIENT_PERSISTENCE_NONE, NULL);
        
        if (status != MQTTASYNC_SUCCESS) {
            return;
        }
        
        status = MQTTAsync_setCallbacks(_mqttClient, (__bridge void*)weakSelf, mqttConnectionLost, mqttMessageArrived, mqttDeliveryComplete);
        
        if (status != MQTTASYNC_SUCCESS) {
            mqttDestroy((__bridge void*)weakSelf);
        }
        
        MQTTAsync_connectOptions connOptions = MQTTAsync_connectOptions_initializer;
        connOptions.onSuccess = mqttConnectionSucceeded;
        connOptions.onFailure = mqttConnectionFailed;
        connOptions.context = (__bridge void*)weakSelf;
        connOptions.username = [AppDelegate instance].strUserName.UTF8String;
        
        [self.btnConnect setTitle:@"Connecting" forState:UIControlStateNormal];
        
        status = MQTTAsync_connect(_mqttClient, &connOptions);
        
        if (status != MQTTASYNC_SUCCESS) {
            mqttDestroy((__bridge void*)weakSelf);
        }
    }
    else
    {
        [self serverDisConnect];
    }
}

/**
 * MQTT Broker에 연결 재시도
 */
- (void)serverRetryConnect{
    if(nRetryConnect != RETRY_COUNT){
        int status;
        
        __weak ViewController* weakSelf = self;
        NSLog(@"_mqttClientID[%@] _mqttUsername[%@]", [AppDelegate instance].strClientId, [AppDelegate instance].strUserName);
        
        status = MQTTAsync_create(&_mqttClient, [AppDelegate instance].strHost.UTF8String, [AppDelegate instance].strClientId.UTF8String, MQTTCLIENT_PERSISTENCE_NONE, NULL);
        
        if (status != MQTTASYNC_SUCCESS) {
            return;
        }
        
        status = MQTTAsync_setCallbacks(_mqttClient, (__bridge void*)weakSelf, mqttConnectionLost, mqttMessageArrived, NULL);
        
        if (status != MQTTASYNC_SUCCESS) {
            mqttDestroy((__bridge void*)weakSelf);
        }
        
        MQTTAsync_connectOptions connOptions = MQTTAsync_connectOptions_initializer;
        connOptions.onSuccess = mqttConnectionSucceeded;
        connOptions.onFailure = mqttConnectionFailed;
        connOptions.context = (__bridge void*)weakSelf;
        connOptions.username = [AppDelegate instance].strUserName.UTF8String;
        
        [self.btnConnect setTitle:@"Connecting" forState:UIControlStateNormal];
        
        status = MQTTAsync_connect(_mqttClient, &connOptions);
        
        if (status != MQTTASYNC_SUCCESS) {
            mqttDestroy((__bridge void*)weakSelf);
        }
        
        if(!isTimerCheck){
            nRetryConnect++;
            NSLog(@"");
        }
    }
    
    // 10초 간격 재시도 6번
    // 이후 24시간 동안 10분 단위 재시도
    if(nRetryConnect == 6){
        isTimerCheck = YES;
        [self stopRetryConnectTimer];
        [self startRetryTimer:600];   // 10분
        [self startRetryEndTimer];    // 24시간크체크
    }
}

/**
 * MQTT Broker에 연결 종료
 */
- (void)serverDisConnect{
    int status;
    
    __weak ViewController* weakSelf = self;
    
    [self stopRetryConnectTimer];
    [self stopAutoTimer];
    
    [self.btnConnect setTitle:@"Disconnecting" forState:UIControlStateNormal];
    
    MQTTAsync_disconnectOptions disconnOptions = MQTTAsync_disconnectOptions_initializer;
    disconnOptions.onSuccess = mqttDisconnectionSucceeded;
    disconnOptions.onFailure = mqttDisconnectionFailed;
    disconnOptions.context = (__bridge void*)weakSelf;
    status = MQTTAsync_disconnect(_mqttClient, &disconnOptions);
}

/**
 * MQTT Broker에 연결 재시도 Timer
 */
-(void)startRetryTimer:(int)interval{
    timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self
                                           selector:@selector(serverRetryConnect)
                                           userInfo:nil
                                            repeats:YES];
}

/**
 * MQTT Broker에 연결 재시도 Timer (24시간 Check)
 */
-(void)startRetryEndTimer{
    timer = [NSTimer scheduledTimerWithTimeInterval:86400 target:self
                                           selector:@selector(stopRetryConnectTimer)
                                           userInfo:nil
                                            repeats:YES];
}


/**
 * MQTT Broker에 연결 재시도
 */
-(void)stopRetryConnectTimer{
    nRetryConnect = 0;
    [timer invalidate];
    timer = nil;
}

/**
 * MQTT Broker에 Trip 리스트 자동 Publish 핸들러
 */
- (void)timeoutHandler:(NSTimer*)timer
{
    NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"TRE%d", nAutoCount] ofType:@"plist"];
    NSString *strTre = [NSString stringWithFormat:@"TRE%d", nAutoCount];
    strSelectTrip = strTre;
    
    if([strTre isEqualToString:@"TRE1"] || [strTre isEqualToString:@"TRE2"]){
        self.strPublishTopic = PUBLISH_TOPIC_TRE;
    }
    else if([strTre isEqualToString:@"TRE3"] || [strTre isEqualToString:@"TRE4"] || [strTre isEqualToString:@"TRE5"] || [strTre isEqualToString:@"TRE6"]){
        self.strPublishTopic = PUBLISH_TOPIC_TELEMETRY;
    }
    else if([strTre isEqualToString:@"TRE7"] || [strTre isEqualToString:@"TRE8"] || [strTre isEqualToString:@"TRE9"]){
        self.strPublishTopic = PUBLISH_TOPIC_ATTRIBUTES;
    }
    NSLog(@"nAutoCount [%d]", nAutoCount);
    NSLog(@"strTre [%@] strPublishTopic [%@]", strTre, self.strPublishTopic);
    
    if([strSelectTrip isEqualToString:@"TRE2"]){
        [AppDelegate instance].nQos = 0;
    }
    else{
        [AppDelegate instance].nQos = 1;
    }
    
    NSLog(@"strSelectTrip [%@]", strSelectTrip);
    
    __weak ViewController* weakSelf = self;
    
    MQTTAsync_message message = MQTTAsync_message_initializer;
    NSString *strPayload = [self setPayload:path];
    
    message.payloadlen = (int)[strPayload lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    const char *payload = [strPayload UTF8String];
    
    message.payload = (char*)payload;
    
    MQTTAsync_responseOptions pubOptions = MQTTAsync_responseOptions_initializer;
    
    pubOptions.onSuccess = mqttPublishSucceeded;
    pubOptions.onFailure = mqttPublishFailed;
    pubOptions.context = (__bridge void*)weakSelf;
    
    [self setLogMsg:@"Pulbish" logString:[NSString stringWithFormat:@"Message Publishing[%@]%@ Qos:%d", self.strPublishTopic, strPayload, [AppDelegate instance].nQos]];
    
    int status = MQTTAsync_sendMessage(_mqttClient, self.strPublishTopic.UTF8String, &message, &pubOptions);
    
    if (status != MQTTASYNC_SUCCESS) {
    }
    
    if(++nAutoCount > 9){
        [self stopAutoTimer];
    }
}

/**
 * MQTT Broker에 Trip 리스트 자동 Publish Timer
 */
- (void)stopAutoTimer{
    strSelectTrip = strTempSelectTrip;
    nAutoCount = 1;
    isAutoPublish = NO;
    [imeoutTimer invalidate];
}

// setting Payload
- (NSString *)setPayload:(NSString *)path{
    NSMutableDictionary *dicTripPayload = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    int nTy = 0;
    int nAp = 0;
    
    nTy = [[strSelectTrip stringByReplacingOccurrencesOfString:@"TRE" withString:@""] intValue];
    
    if([strSelectTrip isEqualToString:@"TRE2"]){
        // Micro-Trip
        // 급유턴 | 급가속 | 급정지
        NSString *strEM = [[NSString alloc] initWithFormat:@"%02x", TripEm3 | TripEm5 | TripEm6];
        
        [dicTripPayload removeObjectForKey:@"em"];
        [dicTripPayload setValue:@([strEM intValue]) forKey:@"em"];
        
        nAp = 0;
    }
    else if([strSelectTrip isEqualToString:@"TRE4"]){
        // 엔진 부하
        NSString *strCM = [[NSString alloc] initWithFormat:@"%02x", HFDcm0];
        
        [dicTripPayload removeObjectForKey:@"cm"];
        [dicTripPayload setValue:@([strCM intValue]) forKey:@"cm"];
    }
    
    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"hhmmss"];
    NSString *strTs = [DateFormatter stringFromDate:[NSDate date]];

    NSDictionary *dicHeaderpayload = @{@"ty":@(nTy), @"ts":@([strTs intValue]), @"pld":dicTripPayload};
    
    NSString *jsonString = @"";
    
    
    NSError *error;
    
    if(![strSelectTrip isEqualToString:@"TRE1"] && ![strSelectTrip isEqualToString:@"TRE2"]){
        dicHeaderpayload = dicTripPayload;
    }
    
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

/**
 * MQTT Broker에 subscribe
 */
- (void)subscribe
{
    if (_mqttClient==NULL) {
        return;
    }
    
    int status;
    [self.view endEditing:YES];
    __weak ViewController* weakSelf = self;
    
    MQTTAsync_responseOptions subOptions = MQTTAsync_responseOptions_initializer;
    subOptions.onSuccess = mqttSubscriptionSucceeded;
    subOptions.onFailure = mqttSubscriptionFailed;
    subOptions.context = (__bridge void*)weakSelf;
    
    status = MQTTAsync_subscribe(_mqttClient, [AppDelegate instance].strTopic.UTF8String,
                                 [AppDelegate instance].nQos,
                                 &subOptions);
}

/**
 * 로그를 처리한다.
 * @param logType
 * @param logString
 */
- (void)setLogMsg:(NSString *)logType logString:(NSString *)logString{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
        [DateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
        NSString *logTimestamp = [DateFormatter stringFromDate:[NSDate date]];
        
        NSString *strLog = [NSString stringWithFormat:@"[%@] %@ \n%@\n",logType, logString, logTimestamp];
        NSDictionary *valueAttribute;
        NSAttributedString *valueString;
        
        if([logType isEqualToString:@"MessageArrived"]){
            valueAttribute = @{NSForegroundColorAttributeName:RGB(255, 147, 0)};
        }
        else if([logType isEqualToString:@"Pulbish_Request"] || [logType isEqualToString:@"Pulbish_Response"]){
            valueAttribute = @{NSForegroundColorAttributeName:RGB(200, 0, 0)};
        }
        else{
            valueAttribute = @{NSForegroundColorAttributeName:RGB(0, 0, 0)};
        }
        
        valueString = [[NSAttributedString alloc] initWithString:strLog attributes:valueAttribute];
        [mas appendAttributedString:valueString];
        tvfLog.attributedText = mas;
        
        if(tvfLog.text.length > 0 ) {
            NSRange bottom = NSMakeRange(tvfLog.text.length, 1);
            [tvfLog scrollRangeToVisible:bottom];
        }
    });
}

/**
 * OBDReset RPC 요청에 대한 처리 결과(response)를 publish 한다.
 * @param topic
 * @param rpcType
 */
- (void) publishResponse:(NSString *)topic rpcType:(int)rpcType{
    __weak ViewController* weakSelf = self;
    
    MQTTAsync_message message = MQTTAsync_message_initializer;
    
    NSMutableDictionary *dicpayload = (NSMutableDictionary *)@{@"result":@([SUCCESS_RESPONSE intValue])};
    NSString *jsonString = @"";
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dicpayload
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    message.payloadlen = (int)[jsonString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    const char *payload = [jsonString UTF8String];
    
    message.payload = (char*)payload;
    
    MQTTAsync_responseOptions pubOptions = MQTTAsync_responseOptions_initializer;
    
    pubOptions.onSuccess = mqttPublishSucceeded;
    pubOptions.onFailure = mqttPublishFailed;
    pubOptions.context = (__bridge void*)weakSelf;
    
    [self setLogMsg:@"Pulbish_Response" logString:[NSString stringWithFormat:@"Message Publishing[%@]%s Qos:%d",
                                          topic,
                                          message.payload,
                                          [AppDelegate instance].nQos]];
    
    int status = MQTTAsync_sendMessage(_mqttClient, topic.UTF8String, &message, &pubOptions);
    
    if (status != MQTTASYNC_SUCCESS) {
    }
}

/**
 * OBDReset RPC 요청에 대한 처리 결과(result)를 publish 한다.
 * @param topic
 * @param rpcType
 */
- (void) publishResult:(NSString *)topic rpcType:(int)rpcType{
    __weak ViewController* weakSelf = self;
    
    MQTTAsync_message message = MQTTAsync_message_initializer;
    
    NSMutableDictionary *dicpayload = (NSMutableDictionary *)@{@"results":@([SUCCESS_RESULT intValue])};
    NSString *jsonString = @"";
    
    if (rpcType == TYPT_DEVICE_ACTIVATION) {
        dicpayload = (NSMutableDictionary *)@{@"results":@([SUCCESS_RESULT intValue]),
                                              @"additionalInfo":@{@"vid":@"00가0000"}};
    } else if (rpcType == TYPT_FIRMWARE_UPDATE) {
    } else if (rpcType == TYPT_OBD_RESET) {
    } else if (rpcType == TYPT_DEVICE_SERIAL_NUMBER_CHECK) {
        dicpayload = (NSMutableDictionary *)@{@"results":@([SUCCESS_RESULT intValue]),
                                              @"additionalInfo":@{@"sn":@"70d71b00-71c9-11e7-b3e0-e5673983c7b9"}};
    } else if (rpcType == TYPT_CLEAR_DEVICE_DATA) {
    } else if (rpcType == TYPT_FIRMWARE_UPDATE_CHUNK) {
    }
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dicpayload
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    message.payloadlen = (int)[jsonString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    const char *payload = [jsonString UTF8String];
    
    message.payload = (char*)payload;
    
    MQTTAsync_responseOptions pubOptions = MQTTAsync_responseOptions_initializer;
    
    pubOptions.onSuccess = mqttPublishSucceeded;
    pubOptions.onFailure = mqttPublishFailed;
    pubOptions.context = (__bridge void*)weakSelf;
    
    [self setLogMsg:@"Pulbish_Request" logString:[NSString stringWithFormat:@"Message Publishing[%@]%s Qos:%d",
                                          topic,
                                          message.payload,
                                          [AppDelegate instance].nQos]];
    
    int status = MQTTAsync_sendMessage(_mqttClient, topic.UTF8String, &message, &pubOptions);
    
    if (status != MQTTASYNC_SUCCESS) {
    }
}

- (NSArray*) parseCommaList:(NSString*)field {
    return [field componentsSeparatedByString:@","];
}


#pragma mark - PickerView Delegate Methods
// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return (NSInteger)1;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return (NSInteger)dicPayload.count;
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [dicPayload objectForKey:[NSString stringWithFormat:@"TRE%d", (int)row + 1]];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    lblTrip.text = [dicPayload objectForKey:[NSString stringWithFormat:@"TRE%d", (int)row + 1]];
    strSelectTrip = [NSString stringWithFormat:@"TRE%d", (int)row + 1];
    NSLog(@"strSelectTrip[%@]", strSelectTrip);
}

#pragma mark MQTT functions
/**
 * 지정된 서버 정보로 TRE 플랫폼에 MQTT 프로토콜로 접속에 성공했을 경우 호출
 *
 * @param context          현재 ViewController Context
 * @param response         Success Call Back 함수
 * @return N/A
 */
void mqttConnectionSucceeded(void* context, MQTTAsync_successData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        printf("MQTT connection to broker succeeded.\n");
        
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        if (!strongSelf) {
            return;
        }
        [strongSelf stopRetryConnectTimer];
        
        [strongSelf setLogMsg:@"Connect" logString:@"Connected to server!"];
        [strongSelf setLogMsg:@"Connect" logString:[NSString stringWithFormat:@"connect Complete: %@: %@",
                                                    [AppDelegate instance].strHost, [AppDelegate instance].strPort]];
        
        [strongSelf subscribe];
        
        [strongSelf.btnConnect setTitle:@"Disconnect" forState:UIControlStateNormal];
    });
}

/**
 * 지정된 서버 정보로 TRE 플랫폼에 MQTT 프로토콜로 접속에 실패했을 경우 호출
 *
 * @param context          현재 ViewController Context
 * @param response         Success Call Back 함수
 * @return N/A
 */
void mqttConnectionFailed(void* context, MQTTAsync_failureData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        printf("MQTT connection to broker failed.\n");
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        if (!strongSelf) {
            return;
        }
        
        [strongSelf setLogMsg:@"Connect" logString:@"Connect fail to server!"];
        [strongSelf.btnConnect setTitle:@"Connect" forState:UIControlStateNormal];

        mqttDestroy(context);
    });
}

/**
 * 지정된 서버 연결 이후 연결이 끊겼을 때 호출
 *
 * @param context          현재 ViewController Context
 * @param response         Connect Lost Cause
 * @return N/A
 */
void mqttConnectionLost(void* context, char* cause)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        printf("MQTT connection was lost with cause: %s\n", cause);
        
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        if (!strongSelf) {
            return;
        }
        
        [strongSelf setLogMsg:@"Connect" logString:@"Connect lost to server!"];

        mqttDestroy(context);
        
        [strongSelf stopRetryConnectTimer];
        [strongSelf startRetryTimer:10]; // 10초
    });
}

/**
 * Subscription 성공 시 호출
 *
 * @param context          현재 ViewController Context
 * @param response         Success Call Back 함수
 * @return N/A
 */
void mqttSubscriptionSucceeded(void* context, MQTTAsync_successData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        
        if (!strongSelf) {
            return;
        }
        printf("MQTT subscription succeeded to topic: %s\n", [AppDelegate instance].strTopic.UTF8String);
        [strongSelf setLogMsg:@"Subscribe" logString:@"onSuccess"];
        [strongSelf setLogMsg:@"Subscribe" logString:[NSString stringWithFormat:@"Subscribe success to %@, Qos:%d",
                                                      [AppDelegate instance].strTopic, [AppDelegate instance].nQos]];
    });
}

/**
 * Subscription 실패 시 호출
 *
 * @param context          현재 ViewController Context
 * @param response         Success Call Back 함수
 * @return N/A
 */
void mqttSubscriptionFailed(void* context, MQTTAsync_failureData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        
        if (!strongSelf) {
            return;
        }
        
        printf("MQTT subscription fail to topic: %s\n", [AppDelegate instance].strTopic.UTF8String);
        [strongSelf setLogMsg:@"Subscribe" logString:@"onFail"];
        [strongSelf setLogMsg:@"Subscribe" logString:[NSString stringWithFormat:@"Subscribe fail to %@, Qos:%d",
                                                      [AppDelegate instance].strTopic, [AppDelegate instance].nQos]];
        
        [strongSelf.btnConnect setTitle:@"Disconnect" forState:UIControlStateNormal];
    });
}


/**
 * Delivery 성공 시 호출
 *
 * @param context          현재 ViewController Context
 * @param token            MQTT ASync Token
 * @return N/A
 */
void mqttDeliveryComplete(void* context, MQTTAsync_token token){
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        
        if (!strongSelf) {
            return;
        }
        
        printf("MQTT mqttDelivery Complete.\n");
    });
}

/**
 * Broker로 부터 클라이언트로 메시지를 전달 할 때 호출
 *
 * @param context          현재 ViewController Context
 * @param topicName        Topic Name
 * @param topicLen         Topic Length
 * @param message          메시지 Json
 * @return N/A
 */
int mqttMessageArrived(void* context, char* topicName, int topicLen, MQTTAsync_message* message)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        printf("MQTT message arrived from topic: %s with body: %s\n", topicName, message->payload);
        
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        
        if (!strongSelf) {
            return;
        }
        
        [strongSelf setLogMsg:@"MessageArrived" logString:[NSString stringWithFormat:@"topicName : %s  message : %s", topicName, message->payload]];
        
        NSString *strPayload = [NSString stringWithFormat:@"%s", message->payload];
       
        // Garbage 처리
        strPayload = [strPayload stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
       
        strPayload = [strPayload stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
        
        NSData *jsonData = [strPayload dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        
        id  json = [NSJSONSerialization JSONObjectWithData:jsonData
                                                      options:kNilOptions
                                                        error:&error];
        
        NSString *strMethod = [json objectForKey:@"method"];
        
        NSString *rpcReqId = [[NSString stringWithFormat:@"%s", topicName]
                              stringByReplacingOccurrencesOfString:RPC_REQUEST_TOPIC
                              withString:@""];
        
        if ([strMethod isEqualToString:DEVICE_ACTIVATION]) {
            [strongSelf publishResponse:[NSString stringWithFormat:@"%@%@", RPC_RESONSE_TOPIC, rpcReqId] rpcType:TYPT_DEVICE_ACTIVATION];
            [strongSelf publishResult:[NSString stringWithFormat:@"%@%@", RPC_RESULT_TOPIC, rpcReqId] rpcType:TYPT_DEVICE_ACTIVATION];
        } else if ([strMethod isEqualToString:FIRMWARE_UPDATE]) {
            [strongSelf publishResponse:[NSString stringWithFormat:@"%@%@", RPC_RESONSE_TOPIC, rpcReqId] rpcType:TYPT_FIRMWARE_UPDATE];
            [strongSelf publishResult:[NSString stringWithFormat:@"%@%@", RPC_RESULT_TOPIC, rpcReqId] rpcType:TYPT_FIRMWARE_UPDATE];
        } else if ([strMethod isEqualToString:OBD_RESET]) {
            [strongSelf publishResponse:[NSString stringWithFormat:@"%@%@", RPC_RESONSE_TOPIC, rpcReqId] rpcType:TYPT_OBD_RESET];
            [strongSelf publishResult:[NSString stringWithFormat:@"%@%@", RPC_RESULT_TOPIC, rpcReqId] rpcType:TYPT_OBD_RESET];
        } else if ([strMethod isEqualToString:DEVICE_SERIAL_NUMBER_CHECK]) {
            [strongSelf publishResponse:[NSString stringWithFormat:@"%@%@", RPC_RESONSE_TOPIC, rpcReqId] rpcType:TYPT_DEVICE_SERIAL_NUMBER_CHECK];
            [strongSelf publishResult:[NSString stringWithFormat:@"%@%@", RPC_RESULT_TOPIC, rpcReqId] rpcType:TYPT_DEVICE_SERIAL_NUMBER_CHECK];
        } else if ([strMethod isEqualToString:CLEAR_DEVICE_DATA]) {
            [strongSelf publishResponse:[NSString stringWithFormat:@"%@%@", RPC_RESONSE_TOPIC, rpcReqId] rpcType:TYPT_CLEAR_DEVICE_DATA];
            [strongSelf publishResult:[NSString stringWithFormat:@"%@%@", RPC_RESULT_TOPIC, rpcReqId] rpcType:TYPT_CLEAR_DEVICE_DATA];
        } else if ([strMethod isEqualToString:FIRMWARE_UPDATE_CHUNK]) {
            [strongSelf publishResponse:[NSString stringWithFormat:@"%@%@", RPC_RESONSE_TOPIC, rpcReqId] rpcType:TYPT_FIRMWARE_UPDATE_CHUNK];
            [strongSelf publishResult:[NSString stringWithFormat:@"%@%@", RPC_RESULT_TOPIC, rpcReqId] rpcType:TYPT_FIRMWARE_UPDATE_CHUNK];
        }
    });
    return true;
}

/**
 * UnSubscription 성공 시 호출
 *
 * @param context          현재 ViewController Context
 * @param response         Success Call Back 함수
 * @return N/A
 */
void mqttUnsubscriptionSucceeded(void* context, MQTTAsync_successData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        
        if (!strongSelf) {
            return;
        }
        
        printf("MQTT unsubscription succeeded.\n");
    });
}

/**
 * UnSubscription 실패 시 호출
 *
 * @param context          현재 ViewController Context
 * @param response         Success Call Back 함수
 * @return N/A
 */
void mqttUnsubscriptionFailed(void* context, MQTTAsync_failureData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        
        if (!strongSelf) {
            return;
        }
        
        printf("MQTT unsubscription failed.\n");
        [strongSelf.btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
    });
}

/**
 * Publish 성공 시 호출
 *
 * @param context          현재 ViewController Context
 * @param response         Success Call Back 함수
 * @return N/A
 */
void mqttPublishSucceeded(void* context, MQTTAsync_successData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        if (!strongSelf) {
            return;
        }
        
        printf("MQTT publish message succeeded.\n");
        [strongSelf setLogMsg:@"Publish" logString:@"onSuccess"];
    });
}

/**
 * UnSubscription 실패 시 호출
 *
 * @param context          현재 ViewController Context
 * @param response         Success Call Back 함수
 * @return N/A
 */
void mqttPublishFailed(void* context, MQTTAsync_failureData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        if (!strongSelf) { return; }
        
        printf("MQTT publish message failed.\n");
        [strongSelf setLogMsg:@"Publish" logString:@"onFail"];
        [strongSelf.btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
    });
}

/**
 * Disconnect 성공 시 호출
 *
 * @param context          현재 ViewController Context
 * @param response         Success Call Back 함수
 * @return N/A
 */
void mqttDisconnectionSucceeded(void* context, MQTTAsync_successData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        printf("MQTT disconnection succeeded.\n");
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        if (!strongSelf) { return; }
        
        [strongSelf setLogMsg:@"Disconnect" logString:@"onSuccess"];
        [strongSelf.btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
        mqttDestroy(context);
    });
}

/**
 * Disconnect 실패 시 호출
 *
 * @param context          현재 ViewController Context
 * @param response         Success Call Back 함수
 * @return N/A
 */
void mqttDisconnectionFailed(void* context, MQTTAsync_failureData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        printf("MQTT disconnection failed.\n");
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        if (!strongSelf) { return; }
        
        [strongSelf setLogMsg:@"Disconnect" logString:@"onFail"];
        mqttDestroy(context);
    });
}

/**
 * MQTT 객체 초기화 할 때 호출
 *
 * @param context          현재 ViewController Context
 * @return N/A
 */
void mqttDestroy(void* context)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        printf("MQTT handler destroyed.\n");
        
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        if (!strongSelf) { return; }
        
        MQTTAsync mqttClient = strongSelf.mqttClient;
        MQTTAsync_destroy(&mqttClient);
        strongSelf.mqttClient = NULL;
    });
}
@end
