//
//  TZVector.m
//
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "TZVector.h"
#import <objc/objc-runtime.h>
#import "metamacros.h"

#define TZInvokeSuper(returnType, sel, ...) TZInvokeSuperWithObject(self, returnType, sel, __VA_ARGS__)
#define TZInvokeSuperWithObject(object, returnType, sel, ...)\
metamacro_concat(TZInvokeSuperWithObject, metamacro_argcount(__VA_ARGS__))(object, returnType, sel, __VA_ARGS__)
#define TZInvokeSuperWithObject0(object, returnType, sel, ...)\
((returnType (*)(struct objc_super *, SEL))objc_msgSendSuper)(&(struct objc_super){object, class_getSuperclass(object_getClass(object))}, sel)
#define TZInvokeSuperWithObject2(object, returnType, sel, type1, arg1, ...)\
((returnType (*)(struct objc_super *, SEL, type1))objc_msgSendSuper)(&(struct objc_super){object, class_getSuperclass(object_getClass(object))}, sel, arg1)
#define TZInvokeSuperWithObject4(object, returnType, sel, type1, arg1, type2, arg2, ...)\
((returnType (*)(struct objc_super *, SEL, type1, type2))objc_msgSendSuper)(&(struct objc_super){object, class_getSuperclass(object_getClass(object))}, sel, arg1, arg2)

#define TZVectorCheckAssert(condition) NSAssert((condition), @"handle this")
#define TZVectorLog(...) NSLog(@"TZVector: %@", [NSString stringWithFormat:__VA_ARGS__])

//static BOOL (*_TZKVOIsAutonotifying)(id self, SEL _cmd);

static NSString * const TZVectorClassSuffix = @"_tzvector";
const void *NSObjectTZVectorTypeKey = &NSObjectTZVectorTypeKey;


@interface NSObject (TZVectorPrivate)
@property TZVectorType *vectorType;
+ (id)generateVectorWithVectorType:(TZVectorType *)vetorType;
+ (void)addVectorFeatureToVector:(id)vector vectorType:(TZVectorType *)vectorType;
@end


@protocol TZVectorStubProtocol
// map
- (nullable id)objectForKeyedSubscript:(id)key;
- (void)setObject:(nullable id)obj forKeyedSubscript:(id)key;
- (void)removeObjectForKey:(id)aKey;
// array
@property (readonly) NSUInteger count;
// set
- (nullable id)anyObject;
@end


@interface NSObject (TZVectorPrivateDeclare)
<TZVectorStubProtocol>
- (BOOL)_isKVOA;
@end



//@interface NSInvocation (TZVector)
//- (void)invokeSuper;
//- (void)invokeUsingIMP:(IMP)imp;
//@end


typedef NS_ENUM(NSInteger, TZVectorTypeDetailType) {
    TZVectorTypeDetailTypeUnknown   =   0,
    TZVectorTypeDetailTypeMap       =   1,
    TZVectorTypeDetailTypeArray     =   2,
    TZVectorTypeDetailTypeSet       =   3,
};

@interface TZVectorType ()
@property (nonatomic, assign) NSUInteger level;
@property (nonatomic, strong) NSString *string;
@property (nonatomic, assign) Class typeClass;
@property (nonatomic, assign) Class keyClass;
@property (nonatomic, assign) Class valueClass;
@property (nonatomic, strong) NSString *keyClassSring;
@property (nonatomic, strong) NSString *valueClassSring;
@property (nonatomic, assign) BOOL isContentAVector;
@property (nonatomic, assign) TZVectorTypeDetailType detailType;
@property (nonatomic, assign) BOOL ignoreTypeChecking;
@property (nonatomic,  copy ) _Nullable id (^generateVectorBlock)(TZVectorType *type);

- (instancetype)initWithTypeString:(NSString *)string
                             level:(NSUInteger)level
                ignoreTypeChecking:(BOOL)ignoreTypeChecking
               generateVectorBlock:(id  _Nullable (^)(TZVectorType * _Nonnull))block;
- (BOOL)checkKeyObject:(id)object;
- (BOOL)checkValueObject:(id)object;
+ (NSString *)clearKeyTypeString:(NSString *)string;
+ (NSString *)sublevelStringFromTypeString:(NSString *)string;
@end


@interface TZVectorStub : NSObject
@property (class, readonly) NSMutableSet<Class> *cachedVectorClasses;
@property (class, readonly) NSMutableSet<Class> *supportedVectorClasses;
@end

@interface TZVectorStub (FixWarning)
@property BOOL ignoreTypeChecking;
@end

@implementation TZVectorStub

+ (instancetype)alloc
{
    return nil;
}

+ (NSMutableSet<Class> *)cachedVectorClasses
{
    static NSMutableSet *cachedVectorClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cachedVectorClass = [[NSMutableSet alloc] init];
    });
    return cachedVectorClass;
}

+ (NSMutableSet<Class> *)supportedVectorClasses
{
    static NSMutableSet *supportedVectorClasses;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        supportedVectorClasses = [NSMutableSet setWithObjects:
                                  // map
                                  NSMutableDictionary.class,
                                  NSCache.class,
                                  NSMapTable.class,
                                  // array
                                  NSMutableArray.class,
                                  NSMutableOrderedSet.class,
                                  // set
                                  NSMutableSet.class,
                                  NSHashTable.class,
                                  NSCountedSet.class, nil];
    });
    return supportedVectorClasses;
}

@end

@implementation TZVectorStub (TZVectorGeneralStub)

- (Class)class
{
    return class_getSuperclass(object_getClass(self));
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    TZInvokeSuper(void, _cmd, id, observer, id, keyPath);
//    ((void (*)(struct objc_super *, SEL, id, id))objc_msgSendSuper)(&(struct objc_super){self, self.superclass}, _cmd, observer, keyPath);

    if (![self _isKVOA]) {
        [NSObject addVectorFeatureToVector:self vectorType:self.vectorType];
    }
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    TZVectorCheckAssert([NSStringFromSelector(aSelector) rangeOfString:@":"].length == 0);
    return [NSMethodSignature signatureWithObjCTypes:"@@:"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    anInvocation.selector = @selector(unknownSelector);
    [anInvocation invoke];
}

- (id)unknownSelector
{
    return self;
}

- (id)value
{
    return self[NSStringFromSelector(_cmd)];
}

- (void)setValue:(id)value
{
    const char *setSEL = sel_getName(_cmd);
    size_t size = strlen(setSEL) - 3;
    char buf[size];

    // setXXX:
    strncpy(buf, &setSEL[3], size);
    char hi = buf[0];
    char lo = isupper(hi) ? tolower(hi) : hi;
    buf[0] = lo;
    buf[size - 1] = '\0';

    self[[NSString stringWithUTF8String:buf]] = value;
}

@end

@implementation TZVectorStub (TZVectorMapStub)

- (nullable id)objectForKey:(id)aKey
{
    return self[aKey];
}

- (nullable id)objectForKeyedSubscript:(id)key
{
    id object = TZInvokeSuper(id, @selector(objectForKey:), id, key);

    TZVectorType *type = self.vectorType;

    if (!object && type.isContentAVector)
    {
        TZVectorType *vectorType = [[TZVectorType alloc] initWithTypeString:[TZVectorType clearKeyTypeString:[TZVectorType sublevelStringFromTypeString:type.string]] level:type.level + 1 ignoreTypeChecking:self.ignoreTypeChecking generateVectorBlock:type.generateVectorBlock];
        object = [NSObject generateVectorWithVectorType:vectorType];
        [NSObject addVectorFeatureToVector:object vectorType:vectorType];
        TZInvokeSuper(void, @selector(setObject:forKey:), id, object, id, key);
    }

    return object;
}

- (void)setObject:(id)anObject forKey:(id)aKey
{
    self[aKey] = anObject;
}

- (void)setObject:(nullable id)obj forKeyedSubscript:(id)key
{
    NSAssert(self.ignoreTypeChecking || [self.vectorType checkKeyObject:key], @"%@%@ needs `%@` as key, but receive `%@` %@", self.vectorType.typeClass, self.vectorType.string, self.vectorType.keyClassSring, [key class] ?: @"nil", key ?: @"");
    NSAssert(self.ignoreTypeChecking || !obj || [self.vectorType checkValueObject:obj], @"%@%@ needs `%@` as value, but receive `%@` %@", self.vectorType.typeClass, self.vectorType.string, self.vectorType.valueClassSring, [obj class], obj);

    if (obj) {
        TZInvokeSuper(void, @selector(setObject:forKey:), id, obj, id, key);
    } else {
        [self removeObjectForKey:key];
    }
}

@end

@implementation TZVectorStub (TZVectorArrayStub)

- (id)firstObject
{
    return self[0];
}

- (id)lastObject
{
    if (!self.count) {
        return self[0];
    }
    return self[self.count - 1];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return self[index];
}

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
    id object;
    if (index < self.count) {
        object = TZInvokeSuper(id, @selector(objectAtIndex:), NSUInteger, index);
    }

    TZVectorType *type = self.vectorType;

    if (!object && type.isContentAVector)
    {
        if (!self.count) {
            TZVectorLog(@"Extremely NOT Recommend using a `%@` in vector chain, please use a map vector instead.", type.typeClass);
        }
        TZVectorType *vectorType = [[TZVectorType alloc] initWithTypeString:[TZVectorType clearKeyTypeString:[TZVectorType sublevelStringFromTypeString:type.string]] level:type.level + 1 ignoreTypeChecking:self.ignoreTypeChecking generateVectorBlock:type.generateVectorBlock];
        object = [NSObject generateVectorWithVectorType:vectorType];
        [NSObject addVectorFeatureToVector:object vectorType:vectorType];
        if (index != self.count) {
            TZVectorLog(@"Auto generate a vector(%@%@) at index %lu, not %lu, please check.", vectorType.typeClass, vectorType.string, self.count, index);
        }
        TZInvokeSuper(void, @selector(insertObject:atIndex:), id, object, NSUInteger, self.count);
//        [self addObject:object];

    }

    return object;
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    NSAssert(self.ignoreTypeChecking || !anObject || [self.vectorType checkValueObject:anObject], @"%@%@ needs `%@` as content, but receive `%@` %@", self.vectorType.typeClass, self.vectorType.string, self.vectorType.valueClassSring, [anObject class], anObject);
    if (anObject) {
        TZInvokeSuper(void, @selector(insertObject:atIndex:), id, anObject, NSUInteger, index);
    } else {
        TZVectorLog(@"%@%@ receive `nil`. -[%@ %@]", self.vectorType.typeClass, self.vectorType.string, self.vectorType.typeClass, NSStringFromSelector(_cmd));
    }
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    NSAssert(self.ignoreTypeChecking || !anObject || [self.vectorType checkValueObject:anObject], @"%@%@ needs `%@` as content, but receive `%@` %@", self.vectorType.typeClass, self.vectorType.string, self.vectorType.valueClassSring, [anObject class], anObject);
    if (anObject) {
        TZInvokeSuper(void, @selector(replaceObjectAtIndex:withObject:), NSUInteger, index, id, anObject);
    } else {
        TZVectorLog(@"%@%@ receive `nil`. -[%@ %@]", self.vectorType.typeClass, self.vectorType.string, self.vectorType.typeClass, NSStringFromSelector(_cmd));
    }
}

- (void)setObject:(id)obj atIndex:(NSUInteger)idx
{
    self[idx] = obj;
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    NSAssert(self.ignoreTypeChecking || !obj || [self.vectorType checkValueObject:obj], @"%@%@ needs `%@` as content, but receive `%@` %@", self.vectorType.typeClass, self.vectorType.string, self.vectorType.valueClassSring, [obj class], obj);

    if (obj) {
        TZInvokeSuper(void, @selector(setObject:atIndexedSubscript:), id, obj, NSUInteger, idx);
    } else {
        TZVectorLog(@"%@%@ receive `nil`. -[%@ %@]", self.vectorType.typeClass, self.vectorType.string, self.vectorType.typeClass, NSStringFromSelector(_cmd));
    }
}

@end

@implementation TZVectorStub (TZVectorSetStub)

- (nullable id)anyObject
{
    id object = super.anyObject;

    TZVectorType *type = self.vectorType;

    if (!object && type.isContentAVector)
    {
        TZVectorLog(@"Extremely NOT Recommend using a `%@` in vector chain, please use a map vector instead.", type.typeClass);
        TZVectorType *vectorType = [[TZVectorType alloc] initWithTypeString:[TZVectorType clearKeyTypeString:[TZVectorType sublevelStringFromTypeString:type.string]] level:type.level + 1 ignoreTypeChecking:self.ignoreTypeChecking generateVectorBlock:type.generateVectorBlock];
        object = [NSObject generateVectorWithVectorType:vectorType];
        [NSObject addVectorFeatureToVector:object vectorType:vectorType];
        TZInvokeSuper(void, @selector(addObject:), id, object);
    }

    return object;
}

- (void)addObject:(id)anObject
{
    NSAssert(self.ignoreTypeChecking || !anObject || [self.vectorType checkValueObject:anObject], @"%@%@ needs `%@` as content, but receive `%@` %@", self.vectorType.typeClass, self.vectorType.string, self.vectorType.valueClassSring, [anObject class], anObject);
    if (anObject) {
        TZInvokeSuper(void, @selector(addObject:), id, anObject);
    } else {
        TZVectorLog(@"%@%@ receive `nil`. -[%@ %@]", self.vectorType.typeClass, self.vectorType.string, self.vectorType.typeClass, NSStringFromSelector(_cmd));
    }
}

@end


#define Implementation(VectorClass)\
implementation VectorClass (TZVector)\
\
+ (instancetype)vectorWithType:(NSString *)type\
{\
    return [self vectorWithType:type generateVectorBlock:nil];\
}\
\
+ (instancetype)vectorWithType:(NSString *)type generateVectorBlock:(id  _Nullable (^)(TZVectorType * _Nonnull))block\
{\
    TZVectorType *vetorType = [[TZVectorType alloc] initWithTypeString:[NSString stringWithFormat:@"%@%@ *", self, type ?: @""] level:0 ignoreTypeChecking:NO generateVectorBlock:block];\
    id vector = [NSObject generateVectorWithVectorType:vetorType];\
    [NSObject addVectorFeatureToVector:vector vectorType:vetorType];\
\
    return vector;\
}\
\
- (BOOL)ignoreTypeChecking\
{\
    return self.vectorType.ignoreTypeChecking;\
}\
\
- (void)setIgnoreTypeChecking:(BOOL)ignoreTypeChecking\
{\
    self.vectorType.ignoreTypeChecking = ignoreTypeChecking;\
} \
@end


@Implementation(NSMutableDictionary)
@Implementation(NSCache)
@Implementation(NSMapTable)

TZIgnoreWarning(-Wincomplete-implementation)
@Implementation(NSMutableArray)
@Implementation(NSMutableOrderedSet)
TZIgnoreWarningEnd

@Implementation(NSMutableSet)
@Implementation(NSCountedSet)
@Implementation(NSHashTable)


@interface TZVectorType (TZVectorExtension)
+ (void)addCustomVector:(Class)vectorClass;
@end

@interface TZVectorType (ErrorChecking)
+ (BOOL)checkErrorType:(NSString *)type;
+ (NSString *)errorTypePromptStingWithType:(NSString *)type;
@end

@implementation TZVectorType

- (instancetype)initWithTypeString:(NSString *)string level:(NSUInteger)level ignoreTypeChecking:(BOOL)ignoreTypeChecking generateVectorBlock:(id  _Nullable (^)(TZVectorType * _Nonnull))block
{
    NSAssert(![TZVectorType checkErrorType:string], [TZVectorType errorTypePromptStingWithType:string]);
    self = [super init];
    if (self) {
        self.level = level;
        self.ignoreTypeChecking = ignoreTypeChecking;
        self.generateVectorBlock = block;

        NSString *sublevelString = [TZVectorType sublevelStringFromTypeString:string];

        self.string = [NSString stringWithFormat:@"<%@>", sublevelString ?: @""];

        [TZVectorType parseTypeString:string outKeyClass:NULL outValueClass:&_typeClass outKeyClassString:NULL outValueClassString:NULL];

        NSString *keyString, *valueString;
        [TZVectorType parseTypeString:sublevelString outKeyClass:&_keyClass outValueClass:&_valueClass outKeyClassString:&keyString outValueClassString:&valueString];
        self.keyClassSring = keyString;
        self.valueClassSring = valueString;

        self.isContentAVector = [sublevelString rangeOfString:@"<"].length > 0;
        self.detailType = [TZVectorType detailTypeForClass:_typeClass];
    }
    return self;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"Level: %lu %@%@", self.level, self.typeClass, self.string];
}

+ (TZVectorTypeDetailType)detailTypeForClass:(Class)cls
{
    if (cls == NSMutableDictionary.class ||
        cls == NSCache.class ||
        cls == NSMapTable.class)
    {
        return TZVectorTypeDetailTypeMap;
    }
    else if (cls == NSMutableArray.class ||
             cls == NSMutableOrderedSet.class)
    {
        return TZVectorTypeDetailTypeArray;
    }
    else if (cls == NSHashTable.class ||
             cls == NSMutableSet.class ||
             cls == NSCountedSet.class)
    {
        return TZVectorTypeDetailTypeSet;
    }
    return TZVectorTypeDetailTypeUnknown;
}

+ (void)parseTypeString:(NSString *)string outKeyClass:(Class *)outKeyClass outValueClass:(Class *)outValueClass outKeyClassString:(NSString **)outKeyClassString outValueClassString:(NSString **)outValueClassString
{
    if (!string.length) {
        return;
    }

    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];

    if ([string hasPrefix:@"<"]) {
        string = [string substringFromIndex:1];
    }
    if ([string hasSuffix:@">"]) {
        string = [string substringToIndex:string.length - 2];
    }

    NSString *classStrings;
    NSScanner *scanner = [[NSScanner alloc] initWithString:string];
    [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"<"] intoString:&classStrings];

    NSArray *classStringArray = [classStrings componentsSeparatedByString:@","];
    NSString *classString;

    if (classStringArray.count == 1)
    {
        if (outValueClass || outValueClassString) {
            [[[NSScanner alloc] initWithString:classStringArray.firstObject] scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"*"] intoString:&classString];
            [self cleanClass:classString outClass:outValueClass outClassString:outValueClassString];
        }
    }
    else if (classStringArray.count == 2)
    {
        if (outKeyClass || outKeyClassString) {
            [[[NSScanner alloc] initWithString:classStringArray.firstObject] scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"*"] intoString:&classString];
            [self cleanClass:classString outClass:outKeyClass outClassString:outKeyClassString];
        }

        if (outValueClass || outValueClassString) {
            [[[NSScanner alloc] initWithString:classStringArray.lastObject] scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"*"] intoString:&classString];
            [self cleanClass:classString outClass:outValueClass outClassString:outValueClassString];
        }
    }
}

+ (NSString *)sublevelStringFromTypeString:(NSString *)string
{
    if (!string.length) {
        return nil;
    }

    string = [string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];

    if (![string rangeOfString:@"<"].length) {
        return nil;
    }

    NSUInteger start = [string rangeOfString:@"<"].location;
    NSUInteger end = [string rangeOfString:@">" options:NSBackwardsSearch].location;
    end = end == NSNotFound ? string.length : end;

    return [string substringWithRange:NSMakeRange(start + 1, end - start - 1)];
}

+ (NSString *)clearKeyTypeString:(NSString *)string
{
    NSRange comma = [string rangeOfString:@","];
    if (comma.location != NSNotFound) {
        NSRange angleBrackets = [string rangeOfString:@"<"];
        if (comma.location < angleBrackets.location) {
            return [[string substringFromIndex:comma.location + 1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        }
    }
    return string;
}

+ (void)cleanClass:(NSString *)classString outClass:(Class *)outClass outClassString:(NSString **)outClassString
{
    Class aClass;
    if ([classString isEqualToString:@"id"]) {
        if (outClassString) {
            *outClassString = classString;
        }
        if (outClass) {
            *outClass = nil;
        }
    } else if ([classString isEqualToString:@"Class"]) {
        if (outClassString) {
            *outClassString = classString;
        }
        if (outClass) {
            *outClass = object_getClass([NSObject class]);
        }
    } else {
        aClass = NSClassFromString(classString);
        if (aClass) {
            NSSet *supportedVectorClasses = TZVectorStub.supportedVectorClasses;

            for (Class c in supportedVectorClasses) {
                if ([aClass isSubclassOfClass:c]) {
                    while (![supportedVectorClasses containsObject:aClass]) {
                        aClass = [aClass superclass];
                    }
                    break;
                }
            }

            if (outClassString) {
                *outClassString = NSStringFromClass(aClass);
            }
            if (outClass) {
                *outClass = aClass;
            }
        } else {
            if (outClassString) {
                *outClassString = classString;
            }
        }
    }
}

- (BOOL)checkKeyObject:(id)object
{
    if ([self.keyClassSring isEqualToString:@"id"]) {
        return YES;
    }

    return [object isKindOfClass:self.keyClass];
}

- (BOOL)checkValueObject:(id)object
{
    if (object && [self.valueClassSring isEqualToString:@"id"]) {
        return YES;
    }

    return [object isKindOfClass:self.valueClass];
}

+ (void)addCustomVector:(Class)vectorClass
{
    [TZVectorStub.supportedVectorClasses addObject:vectorClass];
}

@end

@implementation TZVectorType (ErrorChecking)

+ (BOOL)checkErrorType:(NSString *)type
{
    return [self errorTypePromptStingWithType:type] > 0;
}

+ (NSString *)errorTypePromptStingWithType:(NSString *)_type
{
    static NSInteger (^calculateCount)(NSString *string, NSString *characterString);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calculateCount = ^(NSString *string, NSString *characterString) {
            unichar character = [characterString characterAtIndex:0];
            NSInteger count = 0;
            for (int i = 0; i < string.length; i++) {
                if ([string characterAtIndex:i] == character) {
                    count++;
                }
            }
            return count;
        };
    });

    NSMutableString *ret = _type.mutableCopy;

    if (calculateCount(_type, @"<") != calculateCount(_type, @">")) {
        [ret insertString:@"Wrong type string `" atIndex:0];
        [ret appendString:@"`. Counts of '<' and '>' are not paire."];
        return ret;
    }

    NSString *string = _type;
    NSRange range = NSMakeRange(NSNotFound, 0);
    NSString *suffix = @"";

    while (string.length) {

        NSDictionary *parseResult = [self parseTypeString:string];
        NSArray<Class> *classes = parseResult[@"class"];
        NSArray<NSString *> *strings = parseResult[@"string"];
        if (strings.count != 1) {
            NSRange retRange = [ret rangeOfString:string];
            NSRange e = [string rangeOfString:@"<"];
            e.location = (e.location == NSNotFound ? string.length : e.location);
            NSRange stringRange = NSMakeRange(0, e.location);
            range = NSMakeRange(retRange.location + stringRange.location, stringRange.length);
            suffix = @"Wrong Vector type.";
            break;
        }

        NSString *sublevelString = [self sublevelStringFromTypeString:string];
        BOOL isAVector = [string rangeOfString:@"<"].length > 0;
        Class type = [classes.lastObject isEqual:NSNull.null] ? nil : classes.lastObject;
        NSString *typeString = [strings.lastObject isEqual:NSNull.null] ? nil : strings.lastObject;

        if ([self checkClass:type string:typeString isAVector:isAVector]) {
            if (isAVector && ![TZVectorStub.supportedVectorClasses containsObject:type]) {
                range = [ret rangeOfString:typeString];
                suffix = [NSString stringWithFormat:@"Not supported vector class `%@`.", typeString];
                break;
            }
            if (isAVector) {
                if (!sublevelString.length) {
                    range = NSMakeRange(NSMaxRange([ret rangeOfString:typeString]), 2);
                    suffix = @"Content of vector can NOT be empty.";
                    break;
                }

                parseResult = [self parseTypeString:sublevelString];
                classes = parseResult[@"class"];
                strings = parseResult[@"string"];

                Class key, value;
                NSString *keySting, *valueString;

                if ([self detailTypeForClass:type] == TZVectorTypeDetailTypeMap) {
                    if (strings.count != 2) {
                        NSRange retRange = [ret rangeOfString:string];
                        NSRange s = [string rangeOfString:@"<"];
                        NSRange e = [string rangeOfString:@">"];
                        e.location = (e.location == NSNotFound ? string.length : e.location);
                        NSRange stringRange = NSUnionRange(s, e);
                        range = NSMakeRange(retRange.location + stringRange.location, stringRange.length);
                        suffix = [NSString stringWithFormat:@"Wrong content count for %@, should be 2, but pass %lu", typeString, strings.count];
                        break;
                    }
                    key = [classes[0] isEqual:NSNull.null] ? nil :  classes[0];
                    value = [classes[1] isEqual:NSNull.null] ? nil :  classes[1];
                    keySting = [strings[0] isEqual:NSNull.null] ? nil :  strings[0];
                    valueString = [strings[1] isEqual:NSNull.null] ? nil :  strings[1];
                    if (![self checkClass:key string:keySting isAVector:NO]) {
                        range = [ret rangeOfString:keySting];
                        suffix = [NSString stringWithFormat:@"Content key type `%@` is invalid.", keySting];
                        break;
                    }
                    if (![self checkClass:value string:valueString isAVector:NO]) {
                        range = [ret rangeOfString:valueString];
                        suffix = [NSString stringWithFormat:@"Content value type `%@` is invalid.", keySting];
                        break;
                    }
                } else { // array or set
                    if (strings.count != 1) {
                        NSRange retRange = [ret rangeOfString:string];
                        NSRange s = [string rangeOfString:@"<"];
                        NSRange e = [string rangeOfString:@">"];
                        e.location = (e.location == NSNotFound ? string.length : e.location);
                        NSRange stringRange = NSUnionRange(s, e);
                        range = NSMakeRange(retRange.location + stringRange.location, stringRange.length);
                        suffix = [NSString stringWithFormat:@"Wrong content count for %@, should be 1, but pass %lu", typeString, strings.count];
                        break;
                    }
                    value = [classes[0] isEqual:NSNull.null] ? nil :  classes[0];
                    valueString = [strings[0] isEqual:NSNull.null] ? nil :  strings[0];
                    if (![self checkClass:value string:valueString isAVector:NO]) {
                        range = [ret rangeOfString:valueString];
                        suffix = [NSString stringWithFormat:@"Content type `%@` is invalid.", valueString];
                        break;
                    }
                }
            }
        } else {
            range = [ret rangeOfString:typeString];
            suffix = [NSString stringWithFormat:@"No such type class `%@`.", typeString];
            break;
        }
        string = [self clearKeyTypeString:sublevelString];
    }

    if (range.location != NSNotFound) {
        [ret insertString:@" [ `" atIndex:range.location];
        [ret insertString:@"` ] " atIndex:NSMaxRange(range) + 4];
        [ret insertString:@"Wrong type string `" atIndex:0];
        [ret appendString:@"`."];
        [ret appendString:suffix];
        return ret;
    }

    return nil;
}

+ (NSDictionary *)parseTypeString:(NSString *)string
{
    if (!string.length) {
        return nil;
    }

    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];

    if ([string hasPrefix:@"<"]) {
        string = [string substringFromIndex:1];
    }
    if ([string hasSuffix:@">"]) {
        string = [string substringToIndex:string.length - 2];
    }

    NSString *classStrings;
    NSScanner *scanner = [[NSScanner alloc] initWithString:string];
    [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"<"] intoString:&classStrings];

    NSMutableArray *classes = [[NSMutableArray alloc] init];
    NSMutableArray *strings = [[NSMutableArray alloc] init];

    for (NSString *classString in [classStrings componentsSeparatedByString:@","]) {

        Class cls;
        NSString *clsString;

        [[[NSScanner alloc] initWithString:classString] scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"*"] intoString:&clsString];
        [self cleanClass:clsString outClass:&cls outClassString:&clsString];
        [classes addObject:cls ?: NSNull.null];
        [strings addObject:clsString ?: NSNull.null];
    }
    return @{@"class": classes,
             @"string": strings};
}

+ (BOOL)checkClass:(Class)cls string:(NSString *)string isAVector:(BOOL)isAVector
{
    if (cls || (!isAVector && [string isEqualToString:@"id"])) {
        return YES;
    }
    return NO;
}

@end

@implementation NSCache (TZVectorExtension)

- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)key
{
    if (obj) {
        [self setObject:obj forKey:key];
    } else {
        [self removeObjectForKey:key];
    }
}

@end

@implementation NSMapTable (TZVectorExtension)

- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)key
{
    [self setObject:obj forKey:key];
}

@end

@implementation NSObject (TZVector)

+ (void)addVectorFeatureToVector:(id)vector type:(NSString *)type
{
    [self addVectorFeatureToVector:vector type:type generateVectorBlock:nil];
}

+ (void)addVectorFeatureToVector:(id)vector type:(NSString *)type generateVectorBlock:(id  _Nullable (^)(TZVectorType * _Nonnull))block
{
    NSString *vectorClass = NSStringFromClass([vector class]);
    [TZVectorType cleanClass:vectorClass outClass:NULL outClassString:&vectorClass];

    [NSObject addVectorFeatureToVector:vector vectorType:[[TZVectorType alloc] initWithTypeString:[NSString stringWithFormat:@"%@%@ *", vectorClass, type] level:0 ignoreTypeChecking:NO generateVectorBlock:block]];
}

@end

@implementation NSObject (TZVectorPrivate)

- (TZVectorType *)vectorType
{
    return objc_getAssociatedObject(self, NSObjectTZVectorTypeKey);
}

- (void)setVectorType:(TZVectorType *)vectorType
{
    objc_setAssociatedObject(self, NSObjectTZVectorTypeKey, vectorType, OBJC_ASSOCIATION_RETAIN);
}

+ (id)generateVectorWithVectorType:(TZVectorType *)vetorType
{
    id vector;
    if (vetorType.generateVectorBlock) {
        vector = vetorType.generateVectorBlock(vetorType);
        if (vector) {
            NSAssert([vector isKindOfClass:self], @"TZVector: %@%@ needs a `%@`, but got `%@`", self, vetorType.string, vetorType.typeClass, [vector class]);
        }
    }

    if (!vector) {
        vector = [[vetorType.typeClass alloc] init];
    }

    return vector;
}

+ (void)addVectorFeatureToVector:(id)vector vectorType:(TZVectorType *)vectorType
{
    if (!vector) {
        return;
    }

    @synchronized (vector) {

        if ([TZVectorStub.cachedVectorClasses containsObject:object_getClass(vector)]) {
            TZVectorLog(@"%p%@%@ already had vector feature.", vector, [vector vectorType].typeClass, [vector vectorType].string);
            return;
        }

        Class vectorClass;
        [TZVectorType cleanClass:NSStringFromClass(object_getClass(vector)) outClass:&vectorClass outClassString:NULL];

        NSAssert([vector _isKVOA] || [TZVectorStub.supportedVectorClasses containsObject:vectorClass], @"TZVector: Not support for object %@", vector);
        NSAssert(![vector _isKVOA], @"TZVector: Not support for KVO object.");

        vectorClass = [self realVectorClassForVector:vector];

        if ([vector _isKVOA])
        {
            [self addVectorMethodsToClass:vectorClass detailType:vectorType.detailType];
            SEL removeObserverforKeyPath = @selector(removeObserver:forKeyPath:);
            class_addMethod(vectorClass, removeObserverforKeyPath, class_getMethodImplementation(TZVectorStub.class, removeObserverforKeyPath), "v@:@@");
        }
        else if (![TZVectorStub.cachedVectorClasses containsObject:vectorClass])
        {
            [self addVectorMethodsToClass:vectorClass detailType:vectorType.detailType];
        }

        object_setClass(vector, vectorClass);

        [vector setVectorType:vectorType];
    }
}

+ (Class)realVectorClassForVector:(id)vector
{
    Class vectorClass = object_getClass(vector);

    if (![vector _isKVOA]) {
        NSString *vectorClassString = [NSStringFromClass(vectorClass) stringByAppendingString:TZVectorClassSuffix];
        vectorClass = NSClassFromString(vectorClassString);
        if (!vectorClass) {
            vectorClass = objc_allocateClassPair(object_getClass(vector), vectorClassString.UTF8String, 0);
            objc_registerClassPair(vectorClass);
        }
    }

    return vectorClass;
}

+ (void)addVectorMethodsToClass:(Class)vectorClass detailType:(TZVectorTypeDetailType)detailType
{
    NSArray *selectors;

    switch (detailType) {
            case TZVectorTypeDetailTypeMap:
            selectors = @[NSStringFromSelector(@selector(objectForKey:)),
                          NSStringFromSelector(@selector(setObject:forKey:)),
                          NSStringFromSelector(@selector(objectForKeyedSubscript:)),
                          NSStringFromSelector(@selector(setObject:forKeyedSubscript:)),];
            break;
            case TZVectorTypeDetailTypeArray:
            selectors = @[NSStringFromSelector(@selector(firstObject)),
                          NSStringFromSelector(@selector(lastObject)),
                          NSStringFromSelector(@selector(objectAtIndex:)),
                          NSStringFromSelector(@selector(objectAtIndexedSubscript:)),
                          NSStringFromSelector(@selector(insertObject:atIndex:)),
                          NSStringFromSelector(@selector(replaceObjectAtIndex:withObject:)),
                          NSStringFromSelector(@selector(setObject:atIndex:)),
                          NSStringFromSelector(@selector(setObject:atIndexedSubscript:)),];
            break;
            case TZVectorTypeDetailTypeSet:
            selectors = @[NSStringFromSelector(@selector(anyObject)),
                          NSStringFromSelector(@selector(addObject:))];
            break;
        default:
//        {
//            NSMutableArray *array = [[NSMutableArray alloc] init];
//            Class vectorSuperClass = [vectorClass superclass];
//            unsigned count;
//            Method *methods = class_copyMethodList(vectorSuperClass, &count);
//
//            for (int i = 0; i < count; i++) {
//                [array addObject:NSStringFromSelector(method_getName(methods[i]))];
//            }
//
//            free(methods);
//
//            selectors = array;
//        }
            break;
    }

    selectors = [selectors arrayByAddingObjectsFromArray:
                 @[NSStringFromSelector(@selector(forwardingTargetForSelector:)),
                   NSStringFromSelector(@selector(methodSignatureForSelector:)),
                   NSStringFromSelector(@selector(forwardInvocation:)),
                   NSStringFromSelector(@selector(unknownSelector)),
                   NSStringFromSelector(@selector(class)),]];

    for (NSString *sel in selectors) {

        SEL selector = NSSelectorFromString(sel);

        if (class_respondsToSelector(vectorClass, selector)) {

            Method method = class_getInstanceMethod(vectorClass, selector);

            TZVectorCheckAssert(class_addMethod(vectorClass, selector, class_getMethodImplementation(TZVectorStub.class, selector), method_getTypeEncoding(method)));
        }
    }

    [TZVectorStub.cachedVectorClasses addObject:vectorClass];
}

@end
