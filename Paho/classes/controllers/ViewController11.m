#import "ViewController.h"  // Header
#import <MQTT/MQTTClient.h> // MQTT
#import <MQTT/MQTTAsync.h>  // MQTT

@interface ViewController () <UITextFieldDelegate>
@property (weak,nonatomic) IBOutlet RLYTextField* brokerField;
@property (weak,nonatomic) IBOutlet RLYButton* brokerButton;
@property (weak,nonatomic) IBOutlet UIView* dataView;
@property (weak,nonatomic) IBOutlet RLYTextField* subscriptionField;
@property (weak,nonatomic) IBOutlet RLYButton* subscriptionButton;
@property (weak,nonatomic) IBOutlet RLYTextField* publishField;
@property (weak,nonatomic) IBOutlet RLYTextField* publishBodyField;
@property (weak,nonatomic) IBOutlet RLYButton* publishButton;

@property (unsafe_unretained,nonatomic) MQTTAsync mqttClient;
@property (strong,nonatomic) NSString* mqttClientID;
@property (strong,nonatomic) NSString* mqttUsername;
@property (strong,nonatomic) NSString* mqttPassword;

@property (strong,nonatomic) NSString* strSelectTrip;
@end

#pragma mark - C Private prototypes
void mqttConnectionSucceeded(void* context, MQTTAsync_successData* response);
void mqttConnectionFailed(void* context, MQTTAsync_failureData* response);
void mqttConnectionLost(void* context, char* cause);

void mqttSubscriptionSucceeded(void* context, MQTTAsync_successData* response);
void mqttSubscriptionFailed(void* context, MQTTAsync_failureData* response);

int mqttMessageArrived(void* context, char* topicName, int topicLen, MQTTAsync_message* message);

void mqttUnsubscriptionSucceeded(void* context, MQTTAsync_successData* response);
void mqttUnsubscriptionFailed(void* context, MQTTAsync_failureData* response);

void mqttPublishSucceeded(void* context, MQTTAsync_successData* response);
void mqttPublishFailed(void* context, MQTTAsync_failureData* response);

void mqttDisconnectionSucceeded(void* context, MQTTAsync_successData* response);
void mqttDisconnectionFailed(void* context, MQTTAsync_failureData* response);

@implementation ViewController

#pragma mark - Public API

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _mqttClient = NULL;
    _mqttClientID = @"TRE20171117101140";
    _mqttUsername = @"00000000000000000001";
}

- (void)viewDidLoad
{
    [self resetUI];
}

#pragma mark - Private API

- (IBAction)brokerButtonPressed:(RLYButton*)sender
{
    int status;
    [self.view endEditing:YES];
    __weak ViewController* weakSelf = self;
    
    if (_mqttClient == NULL)
    {
        if (!_brokerField.text.length || !_mqttClientID.length) {
            return;
        }
        
        NSLog(@"_mqttClientID[%@] _mqttUsername[%@]", _mqttClientID, _mqttUsername);
        
        status = MQTTAsync_create(&_mqttClient, _brokerField.text.UTF8String, _mqttClientID.UTF8String, MQTTCLIENT_PERSISTENCE_NONE, NULL);
        
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
        connOptions.username = _mqttUsername.UTF8String;
        
        [_brokerButton setTitle:@"Connecting" forState:UIControlStateDisabled];
        
        _brokerField.enabled = NO;
        _brokerButton.enabled = NO;
        
        status = MQTTAsync_connect(_mqttClient, &connOptions);
        
        if (status != MQTTASYNC_SUCCESS) {
            mqttDestroy((__bridge void*)weakSelf);
        }
    }
    else
    {
        _brokerField.enabled = NO;
        [_brokerButton setTitle:@"Disconnecting" forState:UIControlStateDisabled];
        _brokerButton.enabled = NO;
        _dataView.hidden = YES;
        
        MQTTAsync_disconnectOptions disconnOptions = MQTTAsync_disconnectOptions_initializer;
        disconnOptions.onSuccess = mqttDisconnectionSucceeded;
        disconnOptions.onFailure = mqttDisconnectionFailed;
        disconnOptions.context = (__bridge void*)weakSelf;
        status = MQTTAsync_disconnect(_mqttClient, &disconnOptions);
    }
}

- (IBAction)subscribeButtonPressed:(RLYButton*)sender
{
    if (_mqttClient==NULL) {
        return;
    }
    
    if (!_subscriptionField.text.length) {
        printf("You need to write a subscription topic.\n");
        return;
    }
    
    int status;
    [self.view endEditing:YES];
    __weak ViewController* weakSelf = self;
    
    if ([[_subscriptionButton titleForState:UIControlStateNormal] isEqualToString:@"Subscribe"])
    {   // When the button is pressed, you want to subscribe.
        _subscriptionField.enabled = NO;
        [_subscriptionButton setTitle:@"Subscribing" forState:UIControlStateDisabled];
        _subscriptionButton.enabled = NO;
        
        MQTTAsync_responseOptions subOptions = MQTTAsync_responseOptions_initializer;
        subOptions.onSuccess = mqttSubscriptionSucceeded;
        subOptions.onFailure = mqttSubscriptionFailed;
        subOptions.context = (__bridge void*)weakSelf;
        status = MQTTAsync_subscribe(_mqttClient, _subscriptionField.text.UTF8String, 1, &subOptions);

        if (status != MQTTASYNC_SUCCESS) {
            _subscriptionButton.enabled = YES;
        }
    }
    else
    {   // When the button is pressed, you want to unsubscribe
        [_subscriptionButton setTitle:@"Unsubscribing" forState:UIControlStateDisabled];
        _subscriptionButton.enabled = NO;
        
        MQTTAsync_responseOptions unsubOptions = MQTTAsync_responseOptions_initializer;
        unsubOptions.onSuccess = mqttUnsubscriptionSucceeded;
        unsubOptions.onFailure = mqttUnsubscriptionFailed;
        unsubOptions.context = (__bridge void*)weakSelf;
        status = MQTTAsync_unsubscribe(_mqttClient, _subscriptionField.text.UTF8String, &unsubOptions);
        
        if (status != MQTTASYNC_SUCCESS) {
            _subscriptionField.enabled = YES;
            _subscriptionButton.enabled = YES;
        }
    }
}

- (IBAction)publishButtonPressed:(RLYButton*)sender
{
    if (_mqttClient==NULL) {
        return;
    }
    
    if (!_publishField.text.length) {
        printf("You need to write a publish topic.\n");
        return;
    }
    
    if (!_publishBodyField.text.length) {
        printf("You need to to write a message to be published.\n");
        return;
    }
    
    __weak ViewController* weakSelf = self;
    [self.view endEditing:YES];
    
    MQTTAsync_message message = MQTTAsync_message_initializer;
    
    message.payloadlen = (int)[_publishBodyField.text lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    const char *payload = [_publishBodyField.text UTF8String];
    
    message.payload = (char*)payload;
    
    NSLog(@"Topic [%@]", _publishField.text);
    NSLog(@"payload [%s]", message.payload);
    
//    _publishButton.enabled = NO;
//    _publishField.enabled = NO;
    
    MQTTAsync_responseOptions pubOptions = MQTTAsync_responseOptions_initializer;

    pubOptions.onSuccess = mqttPublishSucceeded;
    pubOptions.onFailure = mqttPublishFailed;
    pubOptions.context = (__bridge void*)weakSelf;
    
    int status = MQTTAsync_sendMessage(_mqttClient, _publishField.text.UTF8String, &message, &pubOptions);
    
    if (status != MQTTASYNC_SUCCESS) {
        _publishField.enabled = YES;
        _publishButton.enabled = YES;
    }
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    
    if (textField == _brokerField) {
        [self brokerButtonPressed:_brokerButton];
    } else if (textField == _subscriptionField) {
        [self subscribeButtonPressed:_subscriptionButton];
    } else if (textField == _publishField) {
        [_publishBodyField becomeFirstResponder];
    } else if (textField == _publishBodyField) {
        [self publishButtonPressed:_publishButton];
    }
    return YES;
}

#pragma mark UI methods

- (void)resetUI
{
    _brokerField.enabled = YES;
    [_brokerButton setTitle:@"Connect" forState:UIControlStateNormal];
    _brokerButton.enabled = YES;
    
    _dataView.hidden = YES;
    [_subscriptionButton setTitle:@"Subscribe" forState:UIControlStateNormal];
    _subscriptionButton.enabled = YES;
    [_publishButton setTitle:@"Publish" forState:UIControlStateNormal];
    _publishButton.enabled = YES;
}

#pragma mark MQTT functions

void mqttConnectionSucceeded(void* context, MQTTAsync_successData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        printf("MQTT connection to broker succeeded.\n");
        
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        if (!strongSelf) { return; }
        
        strongSelf.brokerButton.enabled = YES;
        strongSelf.brokerButton.backgroundColor = strongSelf.brokerButton.selectedBackgroundColor;
        [strongSelf.brokerButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        strongSelf.dataView.hidden = NO;
    });
}

void mqttConnectionFailed(void* context, MQTTAsync_failureData* response)
{
    printf("MQTT connection to broker failed.\n");
    mqttDestroy(context);
}

void mqttConnectionLost(void* context, char* cause)
{
    printf("MQTT connection was lost with cause: %s\n", cause);
    mqttDestroy(context);
}

void mqttSubscriptionSucceeded(void* context, MQTTAsync_successData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        
        if (!strongSelf) {
            return;
        }
        
        printf("MQTT subscription succeeded to topic: %s\n", strongSelf.subscriptionField.text.UTF8String);
        [strongSelf.subscriptionButton setTitle:@"Unsubscribe" forState:UIControlStateNormal];
        strongSelf.subscriptionButton.enabled = YES;
        strongSelf.subscriptionButton.backgroundColor = strongSelf.subscriptionButton.selectedBackgroundColor;
    });
}

void mqttSubscriptionFailed(void* context, MQTTAsync_failureData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        
        if (!strongSelf) {
            return;
        }
        
        printf("MQTT subscription failed to topic: %s", strongSelf.subscriptionField.text.UTF8String);
        strongSelf.subscriptionField.enabled = YES;
        [strongSelf.subscriptionButton setTitle:@"Subscribe" forState:UIControlStateNormal];
        strongSelf.subscriptionButton.enabled = YES;
    });
}

int mqttMessageArrived(void* context, char* topicName, int topicLen, MQTTAsync_message* message)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        printf("MQTT message arrived from topic: %s with body: %s\n", topicName, message->payload);
    });
    return true;
}

void mqttUnsubscriptionSucceeded(void* context, MQTTAsync_successData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        
        if (!strongSelf) {
            return;
        }
        
        printf("MQTT unsubscription succeeded.\n");
        strongSelf.subscriptionField.enabled = YES;
        [strongSelf.subscriptionButton setTitle:@"Subscribe" forState:UIControlStateNormal];
        strongSelf.subscriptionButton.enabled = YES;
        strongSelf.subscriptionButton.backgroundColor = strongSelf.subscriptionButton.defaultBackgroundColor;
    });
}

void mqttUnsubscriptionFailed(void* context, MQTTAsync_failureData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        
        if (!strongSelf) {
            return;
        }
        
        printf("MQTT unsubscription failed.\n");
        strongSelf.subscriptionButton.enabled = YES;
    });
}

void mqttPublishSucceeded(void* context, MQTTAsync_successData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        if (!strongSelf) {
            return;
        }
        
        printf("MQTT publish message succeeded.\n");
        strongSelf.publishButton.enabled = YES;
        strongSelf.publishField.enabled = YES;
    });
}

void mqttPublishFailed(void* context, MQTTAsync_failureData* response)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        if (!strongSelf) { return; }
        
        printf("MQTT publish message failed.\n");
        strongSelf.publishButton.enabled = YES;
        strongSelf.publishField.enabled = YES;
    });
}

void mqttDisconnectionSucceeded(void* context, MQTTAsync_successData* response)
{
    printf("MQTT disconnection succeeded.\n");
    mqttDestroy(context);
}

void mqttDisconnectionFailed(void* context, MQTTAsync_failureData* response)
{
    printf("MQTT disconnection failed.\n");
    mqttDestroy(context);
}

void mqttDestroy(void* context)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        printf("MQTT handler destroyed.\n");
        
        ViewController* strongSelf = (__bridge __weak ViewController*)context;
        if (!strongSelf) { return; }
        
        MQTTAsync mqttClient = strongSelf.mqttClient;
        MQTTAsync_destroy(&mqttClient);
        strongSelf.mqttClient = NULL;
        [strongSelf resetUI];
    });
}

// setting Payload
- (NSString *)setPayload:(NSString *)path{
    NSMutableDictionary *dicTripPayload = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    int nTy = 0;
    int nAp = 0;
    
    nTy = [[self.strSelectTrip stringByReplacingOccurrencesOfString:@"TRE" withString:@""] intValue];
    
//    if([self.strSelectTrip isEqualToString:@"TRE2"]){
//        // Micro-Trip
//        // 급유턴 | 급가속 | 급정지
//        NSString *strEM = [[NSString alloc] initWithFormat:@"%02x", TripEm3 | TripEm5 | TripEm6];
//
//        [dicTripPayload removeObjectForKey:@"em"];
//        [dicTripPayload setValue:@([strEM intValue]) forKey:@"em"];
//
//        nAp = 0;
//    }
//    else if([self.strSelectTrip isEqualToString:@"TRE4"]){
//        // 엔진 부하
//        NSString *strCM = [[NSString alloc] initWithFormat:@"%02x", HFDcm0];
//
//        [dicTripPayload removeObjectForKey:@"cm"];
//        [dicTripPayload setValue:@([strCM intValue]) forKey:@"cm"];
//    }
    
    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"hhmmss"];
    NSString *strTs = [DateFormatter stringFromDate:[NSDate date]];
    
    NSDictionary *dicHeaderpayload = @{@"ty":@(nTy), @"ts":@([strTs intValue]), @"ap":@(nAp), @"pld":dicTripPayload};
    NSString *jsonString = @"";
    
    NSError *error;
    
    if(![self.strSelectTrip isEqualToString:@"TRE1"] && ![self.strSelectTrip isEqualToString:@"TRE2"]){
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
@end
