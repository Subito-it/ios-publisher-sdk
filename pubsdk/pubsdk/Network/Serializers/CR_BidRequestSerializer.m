//
//  CR_BidRequestSerializer.m
//  CriteoPublisherSdk
//
//  Copyright © 2018-2020 Criteo. All rights reserved.
//

#import "CR_ApiQueryKeys.h"
#import "CR_BidRequestSerializer.h"
#import "CR_CdbRequest.h"
#import "CR_Config.h"
#import "CR_DataProtectionConsent.h"
#import "CR_DeviceInfo.h"
#import "CR_GdprSerializer.h"


@interface CR_BidRequestSerializer ()

@property (strong, nonatomic, readonly) CR_GdprSerializer *gdprSerializer;

@end

@implementation CR_BidRequestSerializer

#pragma mark - Life cycle

- (instancetype)init {
    return [self initWithGdprSerializer:[[CR_GdprSerializer alloc] init]];
}

- (instancetype)initWithGdprSerializer:(CR_GdprSerializer *)gdprSerializer {
    if (self = [super init]) {
        _gdprSerializer = gdprSerializer;
    }
    return self;
}

#pragma mark - Public

- (NSURL *)urlWithConfig:(CR_Config *)config {
    NSString *query = [NSString stringWithFormat:@"profileId=%@", config.profileId];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@?%@", config.cdbUrl, config.path, query];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

- (NSDictionary *)bodyWithCdbRequest:(CR_CdbRequest *)cdbRequest
                             consent:(CR_DataProtectionConsent *)consent
                              config:(CR_Config *)config
                          deviceInfo:(CR_DeviceInfo *)deviceInfo {
    NSMutableDictionary *postBody = [NSMutableDictionary new];
    postBody[CR_ApiQueryKeys.sdkVersion] = config.sdkVersion;
    postBody[CR_ApiQueryKeys.profileId] = config.profileId;
    postBody[CR_ApiQueryKeys.publisher] = [self publisherWithConfig:config];
    postBody[CR_ApiQueryKeys.gdpr] = [self.gdprSerializer dictionaryForGdpr:consent.gdpr];
    postBody[CR_ApiQueryKeys.bidSlots] = [self slotsWithCdbRequest:cdbRequest];
    postBody[CR_ApiQueryKeys.user] = [self userWithConsent:consent
                                                    config:config
                                                deviceInfo:deviceInfo];

    return postBody;
}

#pragma mark - Private

- (NSDictionary *)userWithConsent:(CR_DataProtectionConsent *)consent
                           config:(CR_Config *)config
                       deviceInfo:(CR_DeviceInfo *)deviceInfo {

    NSMutableDictionary *userDict = [NSMutableDictionary new];
    userDict[CR_ApiQueryKeys.deviceModel]   = config.deviceModel;
    userDict[CR_ApiQueryKeys.deviceOs]      = config.deviceOs;
    userDict[CR_ApiQueryKeys.deviceId]      = deviceInfo.deviceId;
    userDict[CR_ApiQueryKeys.userAgent]     = deviceInfo.userAgent;
    userDict[CR_ApiQueryKeys.deviceIdType]  = CR_ApiQueryKeys.deviceIdValue;

    if (consent.usPrivacyIabConsentString.length > 0) {
        userDict[CR_ApiQueryKeys.uspIab] = consent.usPrivacyIabConsentString;
    }
    if (consent.usPrivacyCriteoState == CR_CcpaCriteoStateOptIn) {
        userDict[CR_ApiQueryKeys.uspCriteoOptout] = @NO;
    } else if (consent.usPrivacyCriteoState == CR_CcpaCriteoStateOptOut) {
        userDict[CR_ApiQueryKeys.uspCriteoOptout] = @YES;
    } // else if unknown we add nothing.

    if (consent.mopubConsent.length > 0) {
        userDict[CR_ApiQueryKeys.mopubConsent] = consent.mopubConsent;
    }

    return userDict;
}

- (NSDictionary *)publisherWithConfig:(CR_Config *)config {
    NSMutableDictionary *publisher = [NSMutableDictionary new];
    publisher[CR_ApiQueryKeys.bundleId] = config.appId;
    publisher[CR_ApiQueryKeys.cpId] = config.criteoPublisherId;
    return publisher;
}

- (NSArray *)slotsWithCdbRequest:(CR_CdbRequest *)cdbRequest {
    NSMutableArray *slots = [NSMutableArray new];
    for (CR_CacheAdUnit *adUnit in cdbRequest.adUnits) {
        NSMutableDictionary *slotDict = [NSMutableDictionary new];
        slotDict[CR_ApiQueryKeys.bidSlotsPlacementId] = adUnit.adUnitId;
        slotDict[CR_ApiQueryKeys.bidSlotsSizes] = @[adUnit.cdbSize];
        NSString *impressionId = [cdbRequest impressionIdForAdUnit:adUnit];
        if(impressionId) {
            slotDict[CR_ApiQueryKeys.impId] = impressionId;
        }
        if(adUnit.adUnitType == CRAdUnitTypeNative) {
            slotDict[CR_ApiQueryKeys.bidSlotsIsNative] = @(YES);
        }
        else if(adUnit.adUnitType == CRAdUnitTypeInterstitial) {
            slotDict[CR_ApiQueryKeys.bidSlotsIsInterstitial] = @(YES);
        }
        [slots addObject:slotDict];
    }
    return slots;
}

@end
