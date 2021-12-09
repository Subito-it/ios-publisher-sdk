//
//  CR_DfpRewardedFunctionalTests.m
//  CriteoPublisherSdkTests
//
//  Copyright © 2018-2021 Criteo. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <XCTest/XCTest.h>
#import "Criteo.h"
#import "Criteo+Internal.h"
#import "Criteo+Testing.h"
#import "CR_IntegrationsTestBase.h"
#import "CR_DependencyProvider.h"
#import "CR_TestAdUnits.h"
#import "CR_AdUnitHelper.h"
#import "CR_TargetingKeys.h"
#import "NSString+CriteoUrl.h"
#import "CR_DfpCreativeViewChecker.h"
#import "CR_NativeAssets+Testing.h"
#import "CR_IntegrationRegistry.h"
#import "CR_CacheManager.h"
@import GoogleMobileAds;

@interface CR_DfpRewardedFunctionalTests : CR_IntegrationsTestBase

@end

@implementation CR_DfpRewardedFunctionalTests

#pragma mark - rewarded

- (void)setUp {
  // WARNING AdUnitHelper does use singleton object (no DI in here) should be changed with DPP-3734
  [Criteo.sharedCriteo.dependencyProvider.integrationRegistry declare:CR_IntegrationGamAppBidding];
}

- (void)tearDown {
  [Criteo.sharedCriteo.dependencyProvider.integrationRegistry declare:CR_IntegrationFallback];
}

- (void)test_givenRewarded_whenLoad_thenFailToReceiveAd {
  CRRewardedAdUnit *adUnit = [CR_TestAdUnits rewarded];

  self.criteo = [Criteo testing_criteoWithNetworkCaptor];
  [self.criteo testing_registerWithAdUnits:@[ adUnit ]];

  GAMRequest *request = [[GAMRequest alloc] init];

  [self enrichAdObject:request forAdUnit:adUnit];
  CR_DependencyProvider *dependencyProvider = self.criteo.dependencyProvider;

  [self enrichAdObject:request forAdUnit:adUnit];

  CR_CdbBid *bid = [dependencyProvider.cacheManager
      getBidForAdUnit:[CR_AdUnitHelper cacheAdUnitForAdUnit:adUnit]];
  NSDictionary *targeting = request.customTargeting;

  XCTAssertEqualObjects(targeting[CR_TargetingKey_crtCpm], @"1.12");
  XCTAssertEqual(targeting[CR_TargetingKey_crtFormat], @"video");
  XCTAssertEqualObjects(targeting[CR_TargetingKey_crtSize], @"320x480");

  // as this is a "video" url is not base64ed
  NSString *encodedUrl = targeting[CR_TargetingKey_crtDfpDisplayUrl];
  NSString *decodedUrl =
      [[encodedUrl stringByRemovingPercentEncoding] stringByRemovingPercentEncoding];

  XCTAssertEqualObjects(bid.displayUrl, decodedUrl);
  BOOL finished = [self.criteo testing_waitForRegisterHTTPResponses];
  XCTAssert(finished, "Failed to receive all prefetch requests");
}

@end
