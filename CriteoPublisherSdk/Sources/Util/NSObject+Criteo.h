//
//  NSObject+Criteo.h
//  CriteoPublisherSdk
//
//  Copyright © 2018-2020 Criteo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Criteo)

+ (BOOL)cr_object:(nullable id)obj1 isEqualTo:(nullable id)obj2;

@end

NS_ASSUME_NONNULL_END