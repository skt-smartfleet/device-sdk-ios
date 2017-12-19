# iOS Source for T-RemotEye

본 코드는 T-RemotEye 기반 아이폰 코드를 제공합니다.

## Configure

### MQTT Broker 정보

|Attribute | Value | Note |
| --- | --- | --- |
|IP | smartfleet.sktelecom.com |`MQTT_SERVER_HOST`|
|Port | 8883|`MQTT_SERVER_PORT`|
|UserName | 00000000000000011111 |`MQTT_USER_NAME`|

### MQTTS 설정

|Attribute | Value | Note |
| --- | --- | --- |
|QoS | 1 |`qos`|
|Microtrip QoS | 0 |`microTripQos`|
|timeout | 15 |`timeout`|
|keepalive | 60 |`keepalive`|
|cleanSession | true | `setCleanSession(boolean)` |

`$project/Project Dir/Paho/classes/PrefixHeader.pch`:
```
#define MQTT_SERVER_HOST    @"smartfleet.sktelecom.com"
#define MQTT_SERVER_PORT    @"8883"
#define MQTT_USER_NAME      @"00000000000000000001"

#define PUBLISH_TOPIC_TRE           @"v1/sensors/me/tre"
#define PUBLISH_TOPIC_TELEMETRY     @"v1/sensors/me/telemetry"
#define PUBLISH_TOPIC_ATTRIBUTES    @"v1/sensors/me/attributes"

#define SUBSCRIBE_TOPIC             @"v1/sensors/me/rpc/request/+"

#define RPC_RESONSE_TOPIC           @"v1/sensors/me/rpc/response/"
#define RPC_RESULT_TOPIC            @"v1/sensors/me/rpc/result/"
#define RPC_REQUEST_TOPIC           @"v1/sensors/me/rpc/request/"

#define DEVICE_ACTIVATION           @"activationReq"
#define FIRMWARE_UPDATE             @"fwupdate"
#define OBD_RESET                   @"reset"
#define DEVICE_SERIAL_NUMBER_CHECK  @"serial"
#define CLEAR_DEVICE_DATA           @"cleardata"
#define FIRMWARE_UPDATE_CHUNK       @"fwupchunk"

//2000 RPC 정상적 수행
//2001 RPC 메시지 정상적으로 수신 
#define SUCCESS_RESULT       @"2000"
#define SUCCESS_RESPONSE     @"2000"
```

`$project/Project Dir/Paho/classes/ViewController.m`:
```
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
```

## Code Guide

T-RemotEye Proxy에 접속, 메시지 전송 등을 위해  Class를 제공합니다.

### Connect

```
- (void)serverConnect
```
지정된 서버 정보로 TRE 플랫폼에 MQTTS 프로토콜로 접속합니다.

* Parameters
  * N/A
* Returns
  * N/A

```
void mqttConnectionLost(void* context, char* cause);
```

연결이 끊어졌을때 실행하는 콜백 함수입니다.

* Parameters
  * **context** Context
  * **cause** Connect Lost 원인
* Returns
  * N/A

```

void mqttConnectionSucceeded(void* context, MQTTAsync_successData* response);
```

연결 성공 시 실행하는 콜백 함수입니다.

* Parameters
  * **context** Context
  * **response** MQTTAsync_successData
* Returns
  * N/A

```
void mqttConnectionFailed(void* context, MQTTAsync_failureData* response);
```

연결 실패 시 실행하는 콜백 함수입니다.

* Parameters
  * **context** Context
  * **response** MQTTAsync_failureData
* Returns
  * N/A



### Subscribe

```
- (void)subscribe
```

연결이 성공한 뒤 토픽을 구독할 때 사용하는 함수입니다.

* Parameters
  * N/A
* Returns
  * N/A

```
int MQTTAsync_subscribe(MQTTAsync handle, const char* topic, int qos, MQTTAsync_responseOptions* response);
```
Mqtt Android Client에서 제공하는 subscribe 함수입니다.

* Parameters
  * **handle** MQTTAsync
  * **topic** 구독할 토픽
  * **qos** Quality of service의 약자로 서비스 품질을 선택.
  * **response** MQTTAsync_responseOptions 값
* Returns
  * N/A

```
void mqttSubscriptionSucceeded(void* context, MQTTAsync_successData* response);
```

구독 성공 시 실행하는 콜백 함수입니다

* Parameters
  * **context** Context
  * **response** MQTTAsync_successData
* Returns
  * N/A

```
void mqttSubscriptionFailed(void* context, MQTTAsync_failureData* response);
```

구독 실패 시 실행하는 콜백 함수입니다

* Parameters
  * **context** Context
  * **response** MQTTAsync_failureData
* Returns
  * N/A

```
- (void)setLogMsg:(NSString *)logType logString:(NSString *)logString
```

로그를 화면에 표시하는 함수 입니다.

* Parameters
* **logType** 로그 타입(Connect, Publish, MessageArrive, etc)
* **logString** 로그 텍스트
* Returns
* N/A



### Publish

#### Common

```
- (IBAction)onPublish:(id)sender
```
picker에 선택된 trip를 발행하는 함수입니다.

* Parameters
  * **sender** IBAction sender
* Retruns
  * N/A

```
int MQTTAsync_sendMessage(MQTTAsync handle, const char* destinationName, const MQTTAsync_message* msg, MQTTAsync_responseOptions* response);
```
토픽을 발행할 때 사용하는 함수입니다

* Parameters
  * **handle** MQTTAsync
  * **msg** 토픽에 대한 파라미터
  * **destinationName** 발행할 토픽
  * **response** MQTTAsync_responseOptions
* Returns
  * N/A

```
void mqttPublishSucceeded(void* context, MQTTAsync_successData* response);
```

발행 성공 시 실행하는 콜백 함수입니다.

* Parameters
* **context** context
* **response** MQTTAsync_successData
* Returns
  * N/A

```
void mqttPublishFailed(void* context, MQTTAsync_failureData* response);
```

발행 실패 시 실행하는 콜백 함수입니다.

* Parameters
  * **context** context
  * **response** MQTTAsync_failureData
* Returns
  * N/A

#### Trip

```
- (NSString *)setPayload:(NSString *)path
```

공통으로 plist 파일에 정의 되어 있는 Trip 정보를 설정하는 함수 입니다.

```
HEADER
```
Trip 헤더를 정의합니다.
* Key
* **ty** Trip 정보 수집시간
* **ts** Trip Payload 타입
* **ap** Micro Trip "0" 그외 nil
* **pld** Trip Payload


#### Trip Header


```
TRE1.plist
```
Trip 오브젝트를 정의합니다.

* Key
  * **tid** Trip 고유 번호
  * **stt** Trip의 시작 날짜 및 시간(UTC)
  * **edt** Trip의 종료 날짜 및 시간(UTC)
  * **dis** Trip의 주행거리
  * **tdis** 차량의 총 주행거리
  * **fc** 연료소모량
  * **stlat** 운행 시작 좌표의 위도
  * **stlon** 운행 시작 좌표의 경도
  * **edlat** 운행 종료 좌표의 위도
  * **edlon** 운행 종료 좌표의 경도
  * **ctp** 부동액(냉각수) 평균온도
  * **coe** Trip의 탄소 배출량
  * **fct** 연료차단 상태의 운행시간
  * **hsts** Trip의 최고 속도
  * **mesp** Trip의 평균 속도
  * **idt** Trip의 공회전 시간
  * **btv** 배터리 전압(시동OFF후 전압)
  * **gnv** 발전기 전압(주행중 최고 전압)
  * **wut** Trip의 웜업시간(주행전 시동 시간)
  * **usm** BT가 연결된 휴대폰 번호
  * **est** 80~100km 운행 시간
  * **fwv** 펌웨어 버전
  * **dtvt** 주행시간
  

#### Microtrip

```
TRE2.plist
```
Microtrip 오브젝트를 정의합니다.

* Key
  * **tid** Trip 고유 번호
  * **fc** 연료소모량
  * **lat** 위도 (WGS84)
  * **lon** 경도 (WGS84)
  * **lc** 측정 한 위치 값의 정확도
  * **clt** 단말기 기준 수집 시간
  * **cdit** Trip의 현재시점까지 주행거리
  * **rpm** rpm
  * **sp** 차량 속도
  * **em** 한 주기 동안 발생한 이벤트(Hexastring)
  * **el** 엔진 부하
  * **xyz** 가속도 X, Y 및 각속도 Y 값
  * **vv** 배터리 전압 (시동 OFF 후 전압)
  * **tpos** 엑셀 포지션 값


#### Diagnostic Information

```
TRE3.plist
```
Diagnostic Information 오브젝트를 정의합니다.

* Key
* **tid** Trip 고유 번호
* **dtcc** 차량고장코드
* **dtck** 0=confirm 1=pending 2=permanent
* **dtcs** DTC Code의 개수


#### HFD Capability Infomation

```
TRE4.plist
```
HFD Capability Infomatio 오브젝트를 정의합니다.

* Key
  * **cm** OBD가 전송할 수 있는 HFD 항목 (Hexastring)


#### Driving Collision Warning

```
TRE5.plist
```
Driving Collision Warning 오브젝트를 정의합니다.

* Key
  * **tid** Trip 고유 번호
  * **dclat** 위도
  * **dclon** 경도


#### Parking Collision Warning

```
TRE6.plist
```
Collision Warning 오브젝트를 정의합니다.

* Key
  * **pclat** 위도
  * **pclon** 경도


#### Battery Warning

```
TRE7.plist
```
Battery Warning 오브젝트를 정의합니다.

* Key
  * **wbv** 배터리 전압


#### Unplugged Warning

```
TRE8.plist
```
Unplugged Warning 오브젝트를 정의합니다.

* Key
  * **unpt** 탈착 시간(UTC Timestamp)
  * **pt** 부착 시간(UTC Timestamp)


#### Turn Off Warning

```
TRE9.plist
```
Turn Off Warning 오브젝트를 정의합니다.

* Key
  * **rs** 단말 종료 원인


#### Device RPC

##### Common

```
int mqttMessageArrived(void* context, char* topicName, int topicLen, MQTTAsync_message* message);

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
```

구독한 토픽으로 메세지를 받을 시 실행하는 콜백 함수입니다. RPC 요청은 해당 함수를 통해 처리합니다.

* Parameters
context
  * **context** context
  * **topicName** 메시지 온 토픽
  * **topicLen** 메시지 온 토픽의 길이
  * **message** 메시지 내용
* Retruns
  * N/A

```
- (void) publishResponse:(NSString *)topic rpcType:(int)rpcType
```

Device RPC Response 토픽을 발행할 때 사용하는 함수입니다.

* Parameters
  * **topic** 토픽
  * **rpcType** RPC Type
* Retruns
  * N/A

```
- (void) publishResult:(NSString *)topic rpcType:(int)rpcType
```

Device RPC Result 토픽을 발행할 때 사용하는 함수입니다.

* Parameters
* **topic** 토픽
* **rpcType** RPC Type
* Retruns
* N/A
