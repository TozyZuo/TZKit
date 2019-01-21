//
//  NSObject+TZCategory.m
//
//  Created by Tozy on 13-10-10.
//  Copyright (c) 2013年 TozyZuo. All rights reserved.
//

#import "NSObject+TZCategory.h"
#import <objc/runtime.h>

@implementation NSObject (TZImplement)

BOOL ClassImplementedSelector(Class aClass, SEL aSelector)
{
    if ([aClass instancesRespondToSelector:aSelector]) {
        IMP imp = method_getImplementation(class_getInstanceMethod(aClass, aSelector));
        IMP superIMP = method_getImplementation(class_getInstanceMethod(class_getSuperclass(aClass), aSelector));
        return (!superIMP && imp) || (imp != superIMP);
    }
    return NO;
}

+ (BOOL)implementedSelector:(SEL)aSelector
{
    return ClassImplementedSelector(object_getClass(self), aSelector);
}

+ (BOOL)instancesImplementedSelector:(SEL)aSelector
{
    return ClassImplementedSelector(self, aSelector);
}

- (BOOL)implementedSelector:(SEL)aSelector
{
    return ClassImplementedSelector(self.class, aSelector);
}

@end
