//
//  FoundationMacros.h
//
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#ifndef FoundationMacros_h
#define FoundationMacros_h

#import "metamacros.h"
#import "EXTKeyPathCoding.h"
#import "EXTScope.h"

NS_INLINE void TZInvokeBlockInMainThread(void (^block)(void))
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

//#define TZInvokeBlockInMainThread(...)\
//if ([NSThread isMainThread]) {\
//    (__VA_ARGS__)();\
//} else {\
//    dispatch_async(dispatch_get_main_queue(), ^{\
//        (__VA_ARGS__)();\
//    });\
//}

#define TZIgnoreWarning(...)\
_Pragma("clang diagnostic push")\
metamacro_foreach(TZWarningName,, __VA_ARGS__)

#define TZIgnoreWarningEnd \
_Pragma("clang diagnostic pop")

#define TZWarningName(index, name) _Pragma(TZWarningNameStringify(name))
#define TZWarningNameStringify(name) TZWarningAppendPrefix(#name)
#define TZWarningAppendPrefix(name) metamacro_stringify(clang diagnostic ignored name)


#endif /* FoundationMacros_h */
