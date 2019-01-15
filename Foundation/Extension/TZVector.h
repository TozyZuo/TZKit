//
//  TZVector.h
//
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FoundationMacros.h"

#define ObjectType(type, ...) _ObjectType(type, __VA_ARGS__)

#define MapType(...) ObjectType(NSDictionary, __VA_ARGS__)
#define ArrayType(...) ObjectType(NSArray, __VA_ARGS__)
#define SetType(...) ObjectType(NSSet, __VA_ARGS__)

#define ImplementCategory(class, categoryName, property, ...)\
_ImplementCategory(class, categoryName, property, __VA_ARGS__)


NS_ASSUME_NONNULL_BEGIN

@interface TZVectorType : NSObject
@property (readonly) NSUInteger level;
@property (readonly) NSString *string;
@property (readonly) Class typeClass;
@end

@protocol TZVectorProtocol <NSObject>
@property BOOL ignoreTypeChecking;
+ (instancetype)vectorWithType:(NSString *)type;
+ (instancetype)vectorWithType:(NSString *)type generateVectorBlock:(_Nullable id (^_Nullable)(TZVectorType *type))block;
@end

#pragma mark - Map

@interface NSMutableDictionary<K, V> (TZVector)
<TZVectorProtocol>
@end

@interface NSCache<K, V> (TZVectorExtension)
- (nullable V)objectForKeyedSubscript:(K)key;
- (void)setObject:(nullable V)obj forKeyedSubscript:(K)key;
@end

@interface NSCache<K, V> (TZVector)
<TZVectorProtocol>
@end

@interface NSMapTable<K, V> (TZVectorExtension)
- (nullable V)objectForKeyedSubscript:(K)key;
- (void)setObject:(nullable V)obj forKeyedSubscript:(K)key;
@end

@interface NSMapTable<K, V> (TZVector)
<TZVectorProtocol>
@end

#pragma mark - Array

@interface NSMutableArray<T> (TZVector)
<TZVectorProtocol>
- (void)sortUsingComparator:(NSComparisonResult (^NS_NOESCAPE)(T obj1, T obj2))cmptr;
@end

@interface NSMutableOrderedSet<T> (TZVector)
<TZVectorProtocol>
- (void)sortUsingComparator:(NSComparisonResult (^NS_NOESCAPE)(T obj1, T obj2))cmptr;
@end

#pragma mark - Set

@interface NSMutableSet<T> (TZVector)
<TZVectorProtocol>
@end

@interface NSCountedSet<T> (TZVector)
<TZVectorProtocol>
@end

@interface NSHashTable<T> (TZVector)
<TZVectorProtocol>
@end


@interface NSObject (TZVector)
+ (void)addVectorFeatureToVector:(id)vector type:(NSString *)type;
+ (void)addVectorFeatureToVector:(id)vector type:(NSString *)type generateVectorBlock:(_Nullable id (^_Nullable)(TZVectorType *type))block;
@end

NS_ASSUME_NONNULL_END


#define _ObjectType(type, ...)\
(((void)(NO && ((void)((type __VA_ARGS__ *)(nil)), NO)), # __VA_ARGS__))

OBJC_EXPORT Class objc_getClass(const char *name);
OBJC_EXPORT IMP class_getMethodImplementation(Class cls, SEL name);
OBJC_EXPORT SEL sel_registerName(const char *str);
OBJC_EXPORT BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types);

#define ImplementCategoryBegin(class, categoryName)\
TZIgnoreWarning(-Wincomplete-implementation, -Wobjc-property-implementation)\
@implementation class (categoryName)\
\
+ (void)load\
{\
    char *key, buf[64], lo, hi;\
    size_t size;\
    SEL getter, setter;\
    Class targetClass = self;\
    Class stubClass = objc_getClass("TZVectorStub");\
    IMP impGetter = class_getMethodImplementation(stubClass, sel_registerName("value"));\
    IMP impSetter = class_getMethodImplementation(stubClass, sel_registerName("setValue:"));

// this definition will lose code completion feature
//#define CheckProperty(_class, _p) (((void)(NO && ((void)((_class *)(nil))._p, NO)), # _p))
#ifdef DEBUG
#define CheckProperty(_class, _p) ((void)(((_class *)(nil))._p), # _p)
#else
#define CheckProperty(_class, _p) (# _p)
#endif

#define ImplementProperty(index, _class, _p)\
    key =  CheckProperty(_class, _p);\
    size = strlen(key);\
    NSAssert(size < 60, @"name `%s` is too long.", key);\
    strncpy(buf, "set", 3);\
    strncpy(&buf[3], key, size);\
    lo = buf[3];\
    hi = islower(lo) ? toupper(lo) : lo;\
    buf[3] = hi;\
    buf[size + 3] = ':';\
    buf[size + 4] = '\0';\
    getter = sel_registerName(key);\
    setter = sel_registerName(buf);\
    if (!class_addMethod(targetClass, getter, impGetter, "@@:")) {\
        NSLog(@"TZVector: Auto implement method `%s` failed in %s(%s). Maybe implemented.", key, #_class, #_p);\
    }\
    if (!class_addMethod(targetClass, setter, impSetter, "v@:@")) {\
        NSLog(@"TZVector: Auto implement method `%s` failed in %s(%s). Maybe implemented.", buf, #_class, #_p);\
    }

#define ImplementCategoryEnd \
}\
@end \
TZIgnoreWarningEnd


#define _ImplementCategory(class, categoryName, ...)\
ImplementCategoryBegin(class, categoryName) \
metamacro_foreach_cxt(ImplementProperty,, class, __VA_ARGS__) \
ImplementCategoryEnd

