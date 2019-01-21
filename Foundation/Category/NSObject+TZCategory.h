//
//  NSObject+TZCategory.h
//
//  Copyright (c) 2013年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (TZImplement)
+ (BOOL)implementedSelector:(SEL)aSelector;
+ (BOOL)instancesImplementedSelector:(SEL)aSelector;
- (BOOL)implementedSelector:(SEL)aSelector;
@end

