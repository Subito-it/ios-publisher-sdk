//
//  ApiHandler.m
//  pubsdk
//
//  Created by Adwait Kulkarni on 12/6/18.
//  Copyright © 2018 Criteo. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "ApiHandler.h"
#import "Logging.h"

@implementation ApiHandler

- (instancetype) init
{
    NSAssert(false, @"Do not use this initializer");
    return [self initWithNetworkManager:nil];
}

- (instancetype) initWithNetworkManager:(NetworkManager*)networkManager {
    if(self = [super init]) {
        self.networkManager = networkManager;
    }
    return self;
}

- (void)     callCdb:(AdUnit *) adUnit
         gdprConsent:(GdprUserConsent *)gdprConsent
              config:(Config *)config
          deviceInfo:(DeviceInfo *)deviceInfo
ahCdbResponseHandler: (AHCdbResponse) ahCdbResponseHandler {
    if(adUnit.adUnitId.length == 0 ||
       adUnit.size.width == 0.0f ||
       adUnit.size.height == 0.0f) {
        CLog(@"AdUnit is missing one of the following required values adUnitId = %@, width = %f, height = %f"
             , adUnit.adUnitId, adUnit.size.width, adUnit.size.height);
        ahCdbResponseHandler(nil);
    }

    NSDictionary *postBody = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSDictionary dictionaryWithObjectsAndKeys:
                               [deviceInfo deviceId], @"deviceId",                            //The ID that uniquely identifies a device (IDFA, GAID or Hashed Android ID)
                               @"IDFA",               @"deviceIdType",                        // The device type. This parameter can only have two values: IDFA or GAID
                               [config deviceModel],  @"deviceModel",
                               [config deviceOs],     @"deviceOs",                            // The operating system of the device.
                               [deviceInfo userAgent],@"userAgent",
                               nil], @"user",

                              [NSDictionary dictionaryWithObjectsAndKeys:
                               [config appId],     @"bundleId",   // The bundle ID identifying the app
                               [config networkId], @"networkId",
                               nil], @"publisher",

                              [config sdkVersion], @"sdkVersion",
                              [config profileId], @"profileId",

                              [NSArray arrayWithObjects:
                               [NSDictionary dictionaryWithObjectsAndKeys:
                                adUnit.adUnitId,         @"placementId",                   // The adunit id provided in the request
                                [NSArray arrayWithObjects:[adUnit cdbSize], nil], @"sizes",
                                nil],
                               nil], @"slots",
                              [NSDictionary dictionaryWithObjectsAndKeys:
                               gdprConsent.consentString, @"consentData",
                               @(gdprConsent.gdprApplies), @"gdprApplies",
                               @(gdprConsent.consentGiven), @"consentGiven", nil], @"gdprConsent",
                              nil];

    NSString *query = [NSString stringWithFormat:@"profileId=%@", [config profileId]];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@?%@", [config cdbUrl], [config path], query];
    NSURL *url = [NSURL URLWithString: urlString];

    [self.networkManager postToUrl:url postBody:postBody responseHandler:^(NSData *data, NSError *error) {
        if(error == nil) {
            if(data && ahCdbResponseHandler) {
                NSArray *cdbBids = [CdbBid getCdbResponsesFromData:data receivedAt:[NSDate date]];
                ahCdbResponseHandler(cdbBids);
            } else {
                CLog(@"Error on post to CDB : response from CDB was nil");
            }
        } else {
            CLog(@"Error on post to CDB : %@", error);
        }
    }];
}

- (void) getConfig:(Config *) config
   ahConfigHandler:(AHConfigResponse) ahConfigHandler {
    if(![config networkId] || [config sdkVersion].length == 0 || [config appId].length == 0) {
        CLog(@"Config is is missing one of the following required values networkId = %@, sdkVersion = %@, appId = %@ "
             , [config networkId], [config sdkVersion], [config appId]);
        if(ahConfigHandler) {
            ahConfigHandler(nil);
        }
    }

    // TODO: Move the url + query building logic to Config class
    NSString *query = [NSString stringWithFormat:@"networkId=%@&sdkVersion=%@&appId=%@", [config networkId], [config sdkVersion], [config appId]];
    NSString *urlString = [NSString stringWithFormat:@"https://pub-sdk-cfg.criteo.com/v1.0/api/config?%@", query];
    NSURL *url = [NSURL URLWithString: urlString];
    [self.networkManager getFromUrl:url responseHandler:^(NSData *data, NSError *error) {
        if(error == nil) {
            if(data && ahConfigHandler) {
                NSDictionary *configValues = [Config getConfigValuesFromData:data];
                ahConfigHandler(configValues);
            } else {
                CLog(@"Error on get from Config: response from Config was nil");
            }
        } else {
            CLog(@"Error on get from Config : %@", error);
        }
    }];
}

- (void) sendAppEvent:(NSString *)event
               gdprConsent:(GdprUserConsent *)gdprConsent
                    config:(Config *)config
                deviceInfo:(DeviceInfo *)deviceInfo
            ahEventHandler:(AHAppEventsResponse)ahEventHandler {

    NSString *query = [NSString stringWithFormat:@"idfa=%@&eventType=%@&appId=%@&limitedAdTracking=%d"
                       , [deviceInfo deviceId], event, [config appId], ![gdprConsent isAdTrackingEnabled]];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@?%@",[config appEventsUrl], [config appEventsSenderId], query];
    NSURL *url = [NSURL URLWithString: urlString];
    [self.networkManager getFromUrl:url responseHandler:^(NSData *data, NSError *error) {
        if(error == nil) {
            if(data && ahEventHandler) {
                NSError *e = nil;
                NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
                if (!response) {
                    CLog(@"Error parsing app event JSON to AppEvents. Error was: %@" , e);
                } else {
                    ahEventHandler(response, [NSDate date]);
                }
            }
            else {
                CLog(@"Error on get from app events end point; either value is nil: (response: %@) or (ahEventHandler: %p)", data, ahEventHandler);
            }
        } else {
            CLog(@"Error on get from app events end point. Error was: %@", error);
        }
    }];
}
@end