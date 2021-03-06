//
//  AppKitExtension.m
//  Rcode
//
//  Created by TozyZuo on 2018/11/5.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "NSObject+TZCategory.h"

@implementation NSView (AppKitExtension)

static BOOL _NSViewImplementedDescription;

+ (void)load
{
    if ([self instancesImplementedSelector:@selector(description)]) {
        _NSViewImplementedDescription = YES;
        method_exchangeImplementations(class_getInstanceMethod(self, @selector(description)), class_getInstanceMethod(self, @selector(description_AppKitExtension)));
    } else {
        _NSViewImplementedDescription = NO;
        Method description_AppKitExtension = class_getInstanceMethod(self, @selector(description_AppKitExtension));
        class_addMethod(self, @selector(description), method_getImplementation(description_AppKitExtension), method_getTypeEncoding(description_AppKitExtension));
    }
}

- (NSString *)description_AppKitExtension
{
    NSMutableString *str = _NSViewImplementedDescription ? self.description_AppKitExtension.mutableCopy : super.description.mutableCopy;

    [str appendString:@"["];
    [str appendFormat:@"frame = %@; ", NSStringFromRect(self.frame)];
    [str appendString:self.descriptionAppendTextIfApplicable];
    if (!self.wantsDefaultClipping) [str appendString:@"wantsDefaultClipping = NO; "];
    if (self.alphaValue != 1) [str appendFormat:@"alphaValue = %g; ", self.alphaValue];
    if (self.hidden) [str appendString:@"hidden = YES; "];
    if (self.isOpaque) [str appendString:@"opaque = YES; "];
    [str appendString:self.descriptionAutoresizing];
    if (!self.autoresizesSubviews) [str appendString:@"autoresizesSubviews = NO; "];
    if (!self.tag)  [str appendFormat:@"tag = %ld; ", self.tag];
    if (self.gestureRecognizers.count) [str appendFormat:@"gestureRecognizers(%lu) = <NSArray: %p>; ", self.gestureRecognizers.count,  self.gestureRecognizers];
    if (self.trackingAreas.count) [str appendFormat:@"trackingAreas(%lu) = <NSArray: %p>; ", self.trackingAreas.count, self.trackingAreas];
    if (self.layer) [str appendFormat:@"layer = %@; ", self.layer];
    [str deleteCharactersInRange:NSMakeRange(str.length - 2, 2)];
    [str appendString:@"]"];
    return str;
}

- (NSString *)descriptionAppendTextIfApplicable
{
    NSString *text = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self respondsToSelector:@selector(text)]) {
        id t = [self performSelector:@selector(text)];
#pragma clang diagnostic pop
        if ([t isKindOfClass:NSString.class]) {
            text = t;
        }
        if (text) {
            if (text.length >= 0x1a) {
                text = [text substringWithRange:[text rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, 0x1a)]];
                text = [text stringByAppendingString:@"..."];
            }
            text = [NSString stringWithFormat:@"text = '%@'; ", text];
        }
    }
    return text ?: @"";
}

- (NSString *)descriptionAutoresizing
{
    NSAutoresizingMaskOptions mask = self.autoresizingMask;

    NSMutableString *str = [NSMutableString string];

    if ((mask & NSViewMinXMargin)) {
        [str appendString:@"MinX+"];
    }
    if ((mask & NSViewWidthSizable)) {
        [str appendString:@"W+"];
    }
    if ((mask & NSViewMaxXMargin)) {
        [str appendString:@"MaxX+"];
    }
    if ((mask & NSViewMinYMargin)) {
        [str appendString:@"MinY+"];
    }
    if ((mask & NSViewHeightSizable)) {
        [str appendString:@"H+"];
    }
    if ((mask & NSViewMaxYMargin)) {
        [str appendString:@"MaxY+"];
    }

    if (str.length) {
        [str deleteCharactersInRange:NSMakeRange(str.length - 1, 1)];
    }
    else {
        [str appendString:@"none"];
    }

    return [NSString stringWithFormat:@"autoresize = %@; ", str];
}

@end


@implementation NSArray (AppKitExtension)

- (NSString *)debugDescription
{
    return self.description;
}

@end
