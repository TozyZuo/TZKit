//
//  TZRuntimeExtension.h
//
//  Copyright © 2019年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


OBJC_EXPORT id _Nullable objc_getWeakAssociatedObject(id object, NSString *key);
OBJC_EXPORT void objc_setWeakAssociatedObject(id object, NSString *key, id _Nullable value);


NS_ASSUME_NONNULL_END
