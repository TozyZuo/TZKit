//
//  TZKit.h
//  TZKit
//
//  Created by TozyZuo on 2019/1/4.
//  Copyright © 2019年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for TZKit.
FOUNDATION_EXPORT double TZKitVersionNumber;

//! Project version string for TZKit.
FOUNDATION_EXPORT const unsigned char TZKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <TZKit/PublicHeader.h>


#import <TZKit/FoundationMacros.h>
#import <TZKit/NSObject+TZCategory.h>
#import <TZKit/TZVector.h>
#import <TZKit/TZConfig.h>

#if TARGET_OS_WATCH
#elif TARGET_OS_IOS
//    #import <TZKit/TZRichTextController.h>
#elif TARGET_OS_MAC
    #import <TZKit/NSView+TZCategory.h>
    #import <TZKit/NSTextView+TZCategory.h>
    #import <TZKit/NSMenu+TZCategory.h>
    #import <TZKit/TZRichTextController.h>
#endif

