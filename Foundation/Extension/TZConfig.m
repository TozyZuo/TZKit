//
//  TZConfig.m
//  TZKit
//
//  Created by TozyZuo on 2023/9/5.
//  Copyright © 2023 TozyZuo. All rights reserved.
//

#import "TZConfig.h"

@interface TZConfig ()
@property (nonatomic) NSDictionary *config;
@end

@implementation TZConfig

- (NSDictionary *)loadConfig
{
    return @{};
}

+ (id)shared
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.config = [self loadConfig];
    }
    return self;
}

+ (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [NSMethodSignature signatureWithObjCTypes:"@@:"];
}

+ (void)forwardInvocation:(NSInvocation *)anInvocation
{
    anInvocation.target = self.shared;
    [anInvocation invoke];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [NSMethodSignature signatureWithObjCTypes:"@@:"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    id result = self[NSStringFromSelector(anInvocation.selector)];
    [anInvocation setReturnValue:&result];
}

- (nullable id)objectForKeyedSubscript:(NSString *)key
{
    return self.config[key];
}

- (NSString *)description
{
    return self.config.description;
}

@end
