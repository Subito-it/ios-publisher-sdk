//
//  CR_CdbBidBuilder.h
//  pubsdk
//
//  Created by Romain Lofaso on 1/24/20.
//  Copyright © 2020 Criteo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CR_CdbBid;
@class CR_CacheAdUnit;
@class CR_NativeAssets;

NS_ASSUME_NONNULL_BEGIN

#define PROPERTY_DECLARATION(name, type, ownership) \
    @property (nonatomic, readonly, copy) CR_CdbBidBuilder *(^name)(type); \
    @property (nonatomic, ownership) type name ## Value;

@interface CR_CdbBidBuilder : NSObject

PROPERTY_DECLARATION(zoneId, NSUInteger, assign);
PROPERTY_DECLARATION(placementId, NSString *, copy);
PROPERTY_DECLARATION(cpm, NSString *, copy);
PROPERTY_DECLARATION(currency, NSString *, copy);
PROPERTY_DECLARATION(width, NSUInteger, assign);
PROPERTY_DECLARATION(height, NSUInteger, assign);
PROPERTY_DECLARATION(ttl, NSTimeInterval, assign);
PROPERTY_DECLARATION(creative, NSString *, copy);
PROPERTY_DECLARATION(displayUrl, NSString *, copy);
PROPERTY_DECLARATION(insertTime, NSDate *, copy);
PROPERTY_DECLARATION(nativeAssets, CR_NativeAssets *, strong);

/** Shortcut for placementId, width and height of the ad unit. */
@property (nonatomic, readonly, copy) CR_CdbBidBuilder *(^adUnit)(CR_CacheAdUnit *);
@property (nonatomic, readonly, copy) CR_CdbBidBuilder *(^expiredInsertTime)(void);

@property (nonatomic, readonly, strong) CR_CdbBid *build;

@end

#undef PROPERTY_DECLARATION

NS_ASSUME_NONNULL_END
