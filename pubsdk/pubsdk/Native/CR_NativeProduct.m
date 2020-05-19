//
//  CR_NativeProduct.m
//  CriteoPublisherSdk
//
//  Copyright © 2018-2020 Criteo. All rights reserved.
//

#import "CR_NativeProduct.h"
#import "NSObject+Criteo.h"
#import "NSString+Criteo.h"

// Writable properties for internal use
@interface CR_NativeProduct ()

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *description;
@property (copy, nonatomic) NSString *price;
@property (copy, nonatomic) NSString *clickUrl;
@property (copy, nonatomic) NSString *callToAction;
@property (copy, nonatomic) CR_NativeImage *image;

@end

@implementation CR_NativeProduct

@synthesize description = _description;

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _title        = [NSString nonEmptyStringWithStringOrNil: dict[@"title"]];
        _description  = [NSString nonEmptyStringWithStringOrNil: dict[@"description"]];
        _price        = [NSString nonEmptyStringWithStringOrNil: dict[@"price"]];
        _clickUrl     = [NSString nonEmptyStringWithStringOrNil: dict[@"clickUrl"]];
        _callToAction = [NSString nonEmptyStringWithStringOrNil: dict[@"callToAction"]];
        _image        = [CR_NativeImage nativeImageWithDict:     dict[@"image"]];
    }
    return self;
}

+ (CR_NativeProduct *)nativeProductWithDict:(NSDictionary *)dict {
    if (dict && [dict isKindOfClass:NSDictionary.class]) {
        return [[CR_NativeProduct alloc] initWithDict:dict];
    } else {
        return nil;
    }
}

// Hash values of two CR_NativeProduct objects must be the same if the objects are equal. The reverse is not
// guaranteed (nor does it need to be).
- (NSUInteger) hash {
    return _title.hash ^
           _description.hash ^
           _price.hash ^
           _clickUrl.hash ^
           _callToAction.hash ^
           _image.hash;
}

- (BOOL)isEqual:(id)other {
    if (!other || ![other isMemberOfClass:CR_NativeProduct.class]) { return NO; }
    CR_NativeProduct *otherProduct = (CR_NativeProduct *)other;
    BOOL result = YES;
    result &= [NSObject cr_object:_title isEqualTo:otherProduct.title];
    result &= [NSObject cr_object:_description isEqualTo:otherProduct.description];
    result &= [NSObject cr_object:_price isEqualTo:otherProduct.price];
    result &= [NSObject cr_object:_clickUrl isEqualTo:otherProduct.clickUrl];
    result &= [NSObject cr_object:_callToAction isEqualTo:otherProduct.callToAction];
    result &= [NSObject cr_object:_image isEqualTo:otherProduct.image];
    return result;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    CR_NativeProduct *copy = [[CR_NativeProduct alloc] init];
    copy.title        = self.title;
    copy.description  = self.description;
    copy.price        = self.price;
    copy.clickUrl     = self.clickUrl;
    copy.callToAction = self.callToAction;
    copy.image        = self.image;
    return copy;
}

@end
