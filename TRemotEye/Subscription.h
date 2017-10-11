//
//  Subscription.h
//  MQTTTest
//
//  Created by Bryan Boyd on 12/9/13.
//  Copyright (c) 2013 Bryan Boyd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Subscription : NSObject

@property NSString *topicFilter;
@property int qos;

@end
