//
//  CR_HeaderBidding.m
//  CriteoPublisherSdk
//
//  Copyright © 2018-2020 Criteo. All rights reserved.
//

#import "CR_HeaderBidding.h"
#import "CR_TargetingKeys.h"
#import "CR_CdbBid.h"
#import "CR_CacheAdUnit.h"
#import "CR_NativeAssets.h"
#import "CR_NativeProduct.h"
#import "CRAdUnit+Internal.h"
#import "CR_BidManagerHelper.h"
#import "NSString+CriteoUrl.h"

@interface CR_HeaderBidding ()

@property (strong, nonatomic, readonly) id<CR_HeaderBiddingDevice> device;

@end

@implementation CR_HeaderBidding

- (instancetype)initWithDevice:(id<CR_HeaderBiddingDevice>)device {
    if (self = [super init]) {
        _device = device;
    }
    return self;
}

- (void)enrichRequest:(id)adRequest
              withBid:(CR_CdbBid *)bid
               adUnit:(CR_CacheAdUnit *)adUnit {

    // Reset the keywords in the request in case there is empty bid (EE-412).
    if ([self isMoPubRequest:adRequest]) {
        [self removeCriteoBidsFromMoPubRequest:adRequest];
    }

    if ([bid isEmpty]) {
        return;
    }

    if([self isDfpRequest:adRequest]) {
        [self addCriteoBidToDfpRequest:adRequest
                               withBid:bid
                                adUnit:adUnit];
    } else if ([self isMoPubRequest:adRequest]) {
        [self addCriteoBidToMopubRequest:adRequest
                                 withBid:bid
                                  adUnit:adUnit];
    } else if ([adRequest isKindOfClass:NSMutableDictionary.class]) {
        [self addCriteoBidToDictionary:adRequest
                               withBid:bid
                                adUnit:adUnit];
    }
}

- (void)removeCriteoBidsFromMoPubRequest:(id)adRequest {
    NSAssert([self isMoPubRequest:adRequest],
             @"Given object isn't from MoPub API: %@",
             adRequest);
    // For now, this method is a class method because it is used
    // in NSObject+Criteo load for swizzling. 
    [CR_BidManagerHelper removeCriteoBidsFromMoPubRequest:adRequest];
}

- (BOOL)isMoPubRequest:(id)request {
    NSString *className = NSStringFromClass([request class]);
    BOOL result =
    [className isEqualToString:@"MPAdView"] ||
    [className isEqualToString:@"MPInterstitialAdController"];
    return result;
}


#pragma mark - Private

- (BOOL)isDfpRequest:(id)request {
    NSString *name = NSStringFromClass([request class]);
    BOOL result =
    [name isEqualToString:@"DFPRequest"] ||
    [name isEqualToString:@"DFPNRequest"] ||
    [name isEqualToString:@"DFPORequest"] ||
    [name isEqualToString:@"GADRequest"] ||
    [name isEqualToString:@"GADORequest"] ||
    [name isEqualToString:@"GADNRequest"];
    return result;
}

- (void)addCriteoBidToDictionary:(NSMutableDictionary*)dictionary
                         withBid:(CR_CdbBid *)bid
                          adUnit:(CR_CacheAdUnit *)adUnit {
    dictionary[CR_TargetingKey_crtDisplayUrl] = bid.displayUrl;
    dictionary[CR_TargetingKey_crtCpm] = bid.cpm;
    dictionary[CR_TargetingKey_crtSize] = [self stringSizeForBannerWithAdUnit:adUnit];
}

- (void) addCriteoBidToDfpRequest:(id) adRequest
                           withBid:(CR_CdbBid *)bid
                           adUnit:(CR_CacheAdUnit *)adUnit {
    SEL dfpCustomTargeting = NSSelectorFromString(@"customTargeting");
    SEL dfpSetCustomTargeting = NSSelectorFromString(@"setCustomTargeting:");
    if([adRequest respondsToSelector:dfpCustomTargeting] && [adRequest respondsToSelector:dfpSetCustomTargeting]) {

// this is for ignoring warning related to performSelector: on unknown selectors
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id targeting = [adRequest performSelector:dfpCustomTargeting];

        if (targeting == nil) {
            targeting = [NSDictionary dictionary];
        }

        if ([targeting isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary* customTargeting = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *) targeting];
            customTargeting[CR_TargetingKey_crtCpm] = bid.cpm;
            if(adUnit.adUnitType == CRAdUnitTypeNative) {
                // bid will contain atleast one product, a privacy section and atleast one impression pixel
                CR_NativeAssets *nativeAssets = bid.nativeAssets;
                if(nativeAssets.products.count > 0) {
                    CR_NativeProduct *product = nativeAssets.products[0];
                    [self setDfpValue:product.title forKey:CR_TargetingKey_crtnTitle inDictionary:customTargeting];
                    [self setDfpValue:product.description forKey:CR_TargetingKey_crtnDesc inDictionary:customTargeting];
                    [self setDfpValue:product.price forKey:CR_TargetingKey_crtnPrice inDictionary:customTargeting];
                    [self setDfpValue:product.clickUrl forKey:CR_TargetingKey_crtnClickUrl inDictionary:customTargeting];
                    [self setDfpValue:product.callToAction forKey:CR_TargetingKey_crtnCta inDictionary:customTargeting];
                    [self setDfpValue:product.image.url forKey:CR_TargetingKey_crtnImageUrl inDictionary:customTargeting];
                }
                CR_NativeAdvertiser *advertiser = nativeAssets.advertiser;
                [self setDfpValue:advertiser.description forKey:CR_TargetingKey_crtnAdvName inDictionary:customTargeting];
                [self setDfpValue:advertiser.domain forKey:CR_TargetingKey_crtnAdvDomain inDictionary:customTargeting];
                [self setDfpValue:advertiser.logoImage.url forKey:CR_TargetingKey_crtnAdvLogoUrl inDictionary:customTargeting];
                [self setDfpValue:advertiser.logoClickUrl forKey:CR_TargetingKey_crtnAdvUrl inDictionary:customTargeting];

                CR_NativePrivacy *privacy = nativeAssets.privacy;
                [self setDfpValue:privacy.optoutClickUrl forKey:CR_TargetingKey_crtnPrUrl inDictionary:customTargeting];
                [self setDfpValue:privacy.optoutImageUrl forKey:CR_TargetingKey_crtnPrImageUrl inDictionary:customTargeting];
                [self setDfpValue:privacy.longLegalText forKey:CR_TargetingKey_crtnPrText inDictionary:customTargeting];
                customTargeting[CR_TargetingKey_crtnPixCount] =
                    [NSString stringWithFormat:@"%lu", (unsigned long) nativeAssets.impressionPixels.count];
                for(int i = 0; i < bid.nativeAssets.impressionPixels.count; i++) {
                    [self setDfpValue:bid.nativeAssets.impressionPixels[i]
                               forKey:[NSString stringWithFormat:@"%@%d", CR_TargetingKey_crtnPixUrl, i]
                         inDictionary:customTargeting];
                }
            }
            else {
                customTargeting[CR_TargetingKey_crtDfpDisplayUrl] = bid.dfpCompatibleDisplayUrl;
                if (adUnit.adUnitType == CRAdUnitTypeInterstitial) {
                    customTargeting[CR_TargetingKey_crtSize] = [self stringSizeForInterstitial];
                } else if (adUnit.adUnitType == CRAdUnitTypeBanner) {
                    customTargeting[CR_TargetingKey_crtSize] = [self stringSizeForBannerWithAdUnit:adUnit];
                }
            }
            NSDictionary *updatedDictionary = [NSDictionary dictionaryWithDictionary:customTargeting];
            [adRequest performSelector:dfpSetCustomTargeting withObject:updatedDictionary];
#pragma clang diagnostic pop
        }
    }
}

- (void)addCriteoBidToMopubRequest:(id) adRequest
                           withBid:(CR_CdbBid *)bid
                           adUnit:(CR_CacheAdUnit *)adUnit {
    [self removeCriteoBidsFromMoPubRequest:adRequest];
    SEL mopubKeywords = NSSelectorFromString(@"keywords");
    if([adRequest respondsToSelector:mopubKeywords]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id targeting = [adRequest performSelector:mopubKeywords];

        if (targeting == nil) {
            targeting = @"";
        }

        if ([targeting isKindOfClass:[NSString class]]) {
            NSMutableString *keywords = [[NSMutableString alloc] initWithString:targeting];
            if ([keywords length] > 0) {
                [keywords appendString:@","];
            }
            [keywords appendString:CR_TargetingKey_crtCpm];
            [keywords appendString:@":"];
            [keywords appendString:bid.cpm];
            [keywords appendString:@","];
            [keywords appendString:CR_TargetingKey_crtDisplayUrl];
            [keywords appendString:@":"];
            [keywords appendString:bid.mopubCompatibleDisplayUrl];

            if (adUnit.adUnitType == CRAdUnitTypeBanner) {
                NSString *sizeStr = [self stringSizeForBannerWithAdUnit:adUnit];
                [keywords appendString:@","];
                [keywords appendString:CR_TargetingKey_crtSize];
                [keywords appendString:@":"];
                [keywords appendString:sizeStr];
            }
            [adRequest setValue:keywords forKey:@"keywords"];
#pragma clang diagnostic pop
        }
    }
}

- (void)setDfpValue:(NSString *)value
             forKey:(NSString *)key
       inDictionary:(NSMutableDictionary*)dict {
    if(value.length > 0) {
        dict[key] = [NSString cr_dfpCompatibleString:value];
    }
}

#pragma mark - Ad Size

- (NSString *)stringSizeForBannerWithAdUnit:(CR_CacheAdUnit *)adUnit {
    NSAssert(adUnit.adUnitType == CRAdUnitTypeBanner,
             @"The given adUnit isn't a banner: %@", adUnit);
    NSString *sizeStr = [self stringFromSize:adUnit.size];
    return sizeStr;
}

- (NSString *)stringSizeForInterstitial {
    CGSize size = [self sizeForInterstitial];
    NSString *str = [self stringFromSize:size];
    return str;
}

- (CGSize)sizeForInterstitial {
    if ([self.device isPhone] || [self isSmallScreen]) {
        if ([self.device isInPortrait]) {
            return (CGSize) { 320.f, 480.f };
        } else {
            return (CGSize) { 480.f, 320.f };
        }
    } else { // is iPad (or TV)
        if ([self.device isInPortrait]) {
            return (CGSize) { 768.f, 1024.f };
        } else {
            return (CGSize) { 1024.f, 768.f };
        }
    }
}

- (BOOL)isSmallScreen {
    CGSize size = [self.device screenSize];
    BOOL isSmall = NO;
    if (size.width > size.height) {
        isSmall = (size.width < 1024.f) || (size.height < 768.f);
    } else {
        isSmall = (size.width < 768.f) || (size.height < 1024.f);
    }
    return isSmall;
}

- (NSString *)stringFromSize:(CGSize)size {
    NSString *result = [[NSString alloc] initWithFormat:
                        @"%dx%d",
                        (int)size.width,
                        (int)size.height];
    return result;
}

@end

@implementation CR_DeviceInfo (HeaderBidding)

- (BOOL)isPhone {
    UIUserInterfaceIdiom idiom = [[UIDevice currentDevice] userInterfaceIdiom];
    BOOL isPhone = (idiom == UIUserInterfaceIdiomPhone);
    return isPhone;
}

- (BOOL)isInPortrait {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    BOOL isInPortrait = UIDeviceOrientationIsPortrait(orientation);
    return isInPortrait;
}

- (CGSize)screenSize {
    // getScreenSize should be remove at some point because it doesn't respect
    // the naming convention of Apple and class method are usefull for
    // tests on iOS.
    return [self.class getScreenSize];
}

@end
