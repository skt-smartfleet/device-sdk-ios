//
//  Messenger.m
//  MQTTTest
//
//  Created by Bryan Boyd on 12/6/13.
//  Copyright (c) 2013 Bryan Boyd. All rights reserved.
//

#import "Messenger.h"
#import "AppDelegate.h"
#import "LogMessage.h"
#import "Subscription.h"

// Connect Callbacks
@interface ConnectCallbacks : NSObject <InvocationComplete>
- (void) onSuccess:(NSObject*) invocationContext;
- (void) onFailure:(NSObject*) invocationContext errorCode:(int) errorCode errorMessage:(NSString*) errorMessage;
@end
@implementation ConnectCallbacks
- (void) onSuccess:(NSObject*) invocationContext
{
    NSLog(@"%s:%d - invocationContext=%@", __func__, __LINE__, invocationContext);
    
    [AppDelegate dismissProgressIndicator:self];
    
    [[Messenger sharedMessenger] addLogMessage:@"Connected to server!" type:@"Connect"];
}
- (void) onFailure:(NSObject*) invocationContext errorCode:(int) errorCode errorMessage:(NSString*) errorMessage
{
    NSLog(@"%s:%d - invocationContext=%@  errorCode=%d  errorMessage=%@", __func__,
        __LINE__, invocationContext, errorCode, errorMessage);
    
    [AppDelegate dismissProgressIndicator:self];
    
    [[Messenger sharedMessenger] addLogMessage:@"Failed to connect!" type:@"ConnectFail"];
}
@end

// DisConnect Callbacks
@interface DisConnectCallbacks : NSObject <InvocationComplete>
- (void) onSuccess:(NSObject*) invocationContext;
- (void) onFailure:(NSObject*) invocationContext errorCode:(int) errorCode errorMessage:(NSString*) errorMessage;
@end
@implementation DisConnectCallbacks
- (void) onSuccess:(NSObject*) invocationContext
{
    NSLog(@"%s:%d - invocationContext=%@", __func__, __LINE__, invocationContext);
    
    [AppDelegate dismissProgressIndicator:self];
    
    [[Messenger sharedMessenger] addLogMessage:@"DisConnected to server!" type:@"DisConnect"];
}
- (void) onFailure:(NSObject*) invocationContext errorCode:(int) errorCode errorMessage:(NSString*) errorMessage
{
    NSLog(@"%s:%d - invocationContext=%@  errorCode=%d  errorMessage=%@", __func__,
          __LINE__, invocationContext, errorCode, errorMessage);
    
    [AppDelegate dismissProgressIndicator:self];
    
    [[Messenger sharedMessenger] addLogMessage:@"Failed to DisConnected!" type:@"DisConnect"];
}
@end

// Publish Callbacks
@interface PublishCallbacks : NSObject <InvocationComplete>
- (void) onSuccess:(NSObject*) invocationContext;
- (void) onFailure:(NSObject*) invocationContext errorCode:(int) errorCode errorMessage:(NSString *)errorMessage;
@end

@implementation PublishCallbacks
- (void) onSuccess:(NSObject *) invocationContext
{
    NSLog(@"PublishCallbacks - onSuccess");
}
- (void) onFailure:(NSObject *) invocationContext errorCode:(int) errorCode errorMessage:(NSString *)errorMessage
{
    NSLog(@"PublishCallbacks - onFailure");
    [[Messenger sharedMessenger] addLogMessage:errorMessage type:@"Publish"];
}
@end

// Subscribe Callbacks
@interface SubscribeCallbacks : NSObject <InvocationComplete>
- (void) onSuccess:(NSObject*) invocationContext;
- (void) onFailure:(NSObject*) invocationContext errorCode:(int) errorCode errorMessage:(NSString*) errorMessage;
@end
@implementation SubscribeCallbacks
- (void) onSuccess:(NSObject*) invocationContext
{
    NSLog(@"SubscribeCallbacks - onSuccess");
    NSString *topic = (NSString *)invocationContext;
    [[Messenger sharedMessenger] addLogMessage:[NSString stringWithFormat:@"Subscribed to %@", topic] type:@"Action"];
}
- (void) onFailure:(NSObject*) invocationContext errorCode:(int) errorCode errorMessage:(NSString*) errorMessage
{
    NSLog(@"SubscribeCallbacks - onFailure");
    [[Messenger sharedMessenger] addLogMessage:errorMessage type:@"Subscribe"];
}
@end

// Unsubscribe Callbacks
@interface UnsubscribeCallbacks : NSObject <InvocationComplete>
- (void) onSuccess:(NSObject*) invocationContext;
- (void) onFailure:(NSObject*) invocationContext errorCode:(int) errorCode errorMessage:(NSString*) errorMessage;
@end
@implementation UnsubscribeCallbacks
- (void) onSuccess:(NSObject*) invocationContext
{
    NSLog(@"%s:%d - invocationContext=%@", __func__, __LINE__, invocationContext);
    NSString *topic = (NSString *)invocationContext;
    [[Messenger sharedMessenger] addLogMessage:[NSString stringWithFormat:@"Unsubscribed to %@", topic] type:@"Action"];
}
- (void) onFailure:(NSObject*) invocationContext errorCode:(int) errorCode errorMessage:(NSString*) errorMessage
{
    NSLog(@"%s:%d - invocationContext=%@  errorCode=%d  errorMessage=%@", __func__, __LINE__, invocationContext, errorCode, errorMessage);
}
@end

@interface GeneralCallbacks : NSObject <MqttCallbacks>
- (void) onConnectionLost:(NSObject*)invocationContext errorMessage:(NSString*)errorMessage;
- (void) onMessageArrived:(NSObject*)invocationContext message:(MqttMessage*)msg;
- (void) onMessageDelivered:(NSObject*)invocationContext messageId:(int)msgId;
@end
@implementation GeneralCallbacks

- (void) onConnectionLost:(NSObject*)invocationContext errorMessage:(NSString*)errorMessage
{
    NSLog(@"%s:%d - onConnectionLost", __func__, __LINE__);
    
    [AppDelegate dismissProgressIndicator:self];
    [[[Messenger sharedMessenger] subscriptionData] removeAllObjects];
}
- (void) onMessageArrived:(NSObject*)invocationContext message:(MqttMessage*)msg
{
    [AppDelegate dismissProgressIndicator:self];
    
    int qos = msg.qos;
    BOOL retained = msg.retained;
    NSString *payload = [[NSString alloc] initWithBytes:msg.payload length:msg.payloadLength encoding:NSASCIIStringEncoding];
    NSString *topic = msg.destinationName;
    NSString *retainedStr = retained ? @" [retained]" : @"";
    NSString *logStr = [NSString stringWithFormat:@"MessageArrived [%@ QoS:%d] %@%@", topic, qos, payload, retainedStr];
    
    NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    NSString * test = [[json objectForKey:@"pld"] objectForKey:@"fwv"];
    NSLog(@"TEST IS %@", test);
    
    if([topic isEqualToString:@""] || topic == nil){
        topic = RPC_REQUEST_TOPIC;
    }
    
    NSLog(@"%s:%d - %@", __func__, __LINE__, logStr);
    NSLog(@"GeneralCallbacks - onMessageArrived!");
    [[Messenger sharedMessenger] addLogMessage:logStr type:@"Publish"];
}
- (void) onMessageDelivered:(NSObject*)invocationContext messageId:(int)msgId
{
    NSLog(@"GeneralCallbacks - onMessageDelivered!");
    [[Messenger sharedMessenger] addLogMessage:@"MessageDelivered" type:@"Publish"];
}
@end


@implementation Messenger

@synthesize client;

#pragma mark Singleton Methods

+ (id)sharedMessenger {
    static Messenger *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (id)init {
    if (self = [super init]) {
        self.client = [MqttClient alloc];
        self.clientID = nil;
        self.client.callbacks = [[GeneralCallbacks alloc] init];
        self.logMessages = [[NSMutableArray alloc] init];
        self.SubscriptionData = [[NSMutableArray alloc] init];
    }
    return self;
}

/**
 * 지정된 서버 정보로 TRE 플랫폼에 MQTT 프로토콜로 접속한다.
 * 접속 후 토픽 (v1/sensors/me/rpc/request/+) subscribe
 */
- (void)connectWithHosts:(NSArray *)hosts ports:(NSArray *)ports clientId:(NSString *)clientId userName:(NSString *)userName cleanSession:(BOOL)cleanSession
{
    client = [client initWithHosts:hosts ports:ports clientId:clientId];
    ConnectOptions *opts = [[ConnectOptions alloc] init];
    SSLOptions *ssl          = [[SSLOptions alloc] init];
    [opts setSslProperties:ssl];
    
    opts.timeout = 10;
    opts.keepAliveInterval = 1000;
    opts.cleanSession = cleanSession;
    opts.userName = userName;
    
    
    
//    NSBundle *mainBundle = [NSBundle mainBundle];
//    NSString *ksFile     = [mainBundle pathForResource: @"ClientKeyStore" ofType: @"pem"];
//    NSString *pkFile     = [mainBundle pathForResource: @"ClientKey" ofType: @"pem"];
//    NSString *tsFile     = [mainBundle pathForResource: @"RootCAKey" ofType: @"pem"];
//
//    if (DEBUG) {
//        NSLog(@"Bundle         ==> %@", mainBundle);
//        NSLog(@"ClientKeyStore ==> %@", ksFile);
//        NSLog(@"ClientKey      ==> %@", pkFile);
//        NSLog(@"TrustStore     ==> %@", tsFile);
//    }
    
//    ssl.keyStore             = ksFile;
//    ssl.privateKey           = pkFile;
//    ssl.privateKeyPassword   = @"******";
//    ssl.trustStore           = tsFile;
    
    
//    ssl.enableServerCertAuth = YES;
    
    [AppDelegate showProgressIndicator:self];
    NSLog(@"%s:%d host=%@, port=%@, clientId=%@ , userName=%@", __func__, __LINE__, hosts, ports, clientId, opts.userName);
    [client connectWithOptions:opts invocationContext:self onCompletion:[[ConnectCallbacks alloc] init]];
}

- (void)connectWithHost:(NSString *)host port:(int)port clientId:(NSString *)clientId userName:(NSString *)userName cleanSession:(BOOL)cleanSession
{
    NSLog(@"\n##### host port [%@:%d] \n##### userName [%@] \n##### clientID [%@]", host, port, userName, clientId);
    
    client = [client initWithHost:host port:port clientId:clientId];
    ConnectOptions *opts = [[ConnectOptions alloc] init];
    
    opts.timeout = 60;
    opts.keepAliveInterval = 6000;
    opts.cleanSession = YES;
    opts.userName = userName;
    
    SSLOptions *ssl          = [[SSLOptions alloc] init];
//    ssl.enableServerCertAuth = NO;
    opts.sslProperties = ssl;
    
    [AppDelegate showProgressIndicator:self];
    
    [client connectWithOptions:opts invocationContext:self onCompletion:[[ConnectCallbacks alloc] init]];
}

/**
 * MQTT Broker 연결 해제
 */
- (void)disconnectWithTimeout:(int)timeout {
    DisconnectOptions *opts = [[DisconnectOptions alloc] init];
    [opts setTimeout:timeout];
    
    [[self subscriptionData] removeAllObjects];
    [client disconnectWithOptions:opts invocationContext:self onCompletion:[[DisConnectCallbacks alloc] init]];
}

/**
 * MQTT publish
 */
- (void)publish:(NSString *)topic payload:(NSString *)payload qos:(int)qos retained:(BOOL)retained
{
    NSString *retainedStr = retained ? @" [retained]" : @"";
    NSString *logStr = [NSString stringWithFormat:@"[%@] %@%@", topic, payload, retainedStr];
    NSLog(@"%s:%d - %@", __func__, __LINE__, logStr);

    MqttMessage *msg = [[MqttMessage alloc] initWithMqttMessage:topic payload:(char*)[payload UTF8String] length:(int)payload.length qos:qos retained:retained duplicate:NO];
    [client send:msg invocationContext:self onCompletion:[[PublishCallbacks alloc] init]];
}

/**
 * MQTT auto publish
 */
- (void)autoPublish:(NSString *)topic payload:(NSString *)payload tripname:(NSString *)tripname qos:(int)qos retained:(BOOL)retained
{
    NSString *retainedStr = retained ? @" [retained]" : @"";
    NSString *logStr = [NSString stringWithFormat:@"[%@/%@] %@%@", topic, tripname, payload, retainedStr];
    NSLog(@"%s:%d - %@", __func__, __LINE__, logStr);
    
    MqttMessage *msg = [[MqttMessage alloc] initWithMqttMessage:topic payload:(char*)[payload UTF8String] length:(int)payload.length qos:qos retained:retained duplicate:NO];
    [client send:msg invocationContext:self onCompletion:[[PublishCallbacks alloc] init]];
}

/**
 * MQTT subscribe
 */
- (void)subscribe:(NSString *)topicFilter qos:(int)qos
{
    NSLog(@"%s:%d topicFilter=%@, qos=%d", __func__, __LINE__, topicFilter, qos);
    [client subscribe:topicFilter qos:qos invocationContext:topicFilter onCompletion:[[SubscribeCallbacks alloc] init]];

    Subscription *sub = [[Subscription alloc] init];
    sub.topicFilter = topicFilter;
    sub.qos = qos;
    [self.subscriptionData addObject:sub];
}

/**
 * MQTT unsubscribe
 */
- (void)unsubscribe:(NSString *)topicFilter
{
    NSLog(@"%s:%d topicFilter=%@", __func__, __LINE__, topicFilter);
    [client unsubscribe:topicFilter invocationContext:topicFilter onCompletion:[[UnsubscribeCallbacks alloc] init]];
    
    NSUInteger currentIndex = 0;
    for (id obj in self.subscriptionData) {
        if ([((Subscription *)obj).topicFilter isEqualToString:topicFilter]) {
            [self.subscriptionData removeObjectAtIndex:currentIndex];
            break;
        }
        currentIndex++;
    }
}

/**
 * Clear Log Message
 */
- (void)clearLog
{
    self.logMessages = [[NSMutableArray alloc] init];
}

/**
 * Add Log Message
 */
- (void)addLogMessage:(NSString *)data type:(NSString *)type
{
    LogMessage *msg = [[LogMessage alloc] init];
    msg.data = data;
    msg.type = type;
    
    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    msg.timestamp = [DateFormatter stringFromDate:[NSDate date]];
    
    [self.logMessages addObject:msg];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogReload"
                                                        object:nil
                                                      userInfo:nil];
}

@end
