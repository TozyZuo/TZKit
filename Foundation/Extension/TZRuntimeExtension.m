//
//  TZRuntimeExtension.m
//
//  Copyright © 2019年 TozyZuo. All rights reserved.
//

#import "TZRuntimeExtension.h"
#import <objc/runtime.h>

id _Nullable objc_getWeakAssociatedObject(id object, NSString *key)
{
    if (object && key) {
        id (^getter)(void) = objc_getAssociatedObject(object, (const void *)key.hash);
        if (getter) {
            return getter();
        }
    }
    return nil;
}

void objc_setWeakAssociatedObject(id object, NSString *key, id _Nullable value)
{
    if (object && key) {
        if (value) {
            __weak id weakValue = value;
            objc_setAssociatedObject(object, (const void *)key.hash, ^{
                return weakValue;
            }, OBJC_ASSOCIATION_COPY);
        } else {
            objc_setAssociatedObject(object, (const void *)key.hash, nil, OBJC_ASSOCIATION_COPY);
        }
    }
}

