//
//  CR_NativeImageTests.m
//  CriteoPublisherSdkTests
//
//  Copyright © 2018-2020 Criteo. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock.h>

#import "Criteo.h"
#import "Criteo+Internal.h"
#import "CR_BidManager.h"
#import "CRNativeAdUnit.h"
#import "CRNativeLoader.h"
#import "CRNativeLoader+Internal.h"
#import "CR_AdUnitHelper.h"
#import "CRMediaDownloader.h"

@interface CR_NativeLoaderTests : XCTestCase
@end

@interface CR_NativeLoaderDispatchChecker : NSObject <CRNativeDelegate>
@property (strong, nonatomic) XCTestExpectation *didReceiveOnMainQueue;
@property (strong, nonatomic) XCTestExpectation *didFailOnMainQueue;
@property (strong, nonatomic) XCTestExpectation *didDetectImpression;
@property (strong, nonatomic) XCTestExpectation *didDetectClick;
@property (strong, nonatomic) XCTestExpectation *willLeaveApplicationForNativeAd;
@end

@interface CRNativeLoader (Tests)
- (void)notifyWillLeaveApplicationForNativeAd;
@end

@implementation CR_NativeLoaderTests

- (void)testReceiveWithValidBid {
    [self loadNativeWithBid:self.validBid verify:
        ^(CRNativeLoader *loader, id <CRNativeDelegate> delegateMock, Criteo *criteoMock) {
            OCMExpect([delegateMock nativeLoader:loader didReceiveAd:[OCMArg any]]);
            OCMReject([delegateMock nativeLoader:loader didFailToReceiveAdWithError:[OCMArg any]]);
        }];
}

- (void)testFailureWithNoBid {
    [self loadNativeWithBid:[CR_CdbBid emptyBid] verify:
        ^(CRNativeLoader *loader, id <CRNativeDelegate> delegateMock, Criteo *criteoMock) {
            OCMExpect([delegateMock nativeLoader:loader didFailToReceiveAdWithError:[OCMArg any]]);
            OCMReject([delegateMock nativeLoader:loader didReceiveAd:[OCMArg any]]);
        }];
}

- (Criteo *)mockCriteoWithAdUnit:(CRNativeAdUnit *)adUnit
                       returnBid:(CR_CdbBid *)bid {
    Criteo *criteoMock = OCMStrictClassMock([Criteo class]);
    CR_CacheAdUnit *cacheAdUnit = [CR_AdUnitHelper cacheAdUnitForAdUnit:adUnit];
    OCMStub([criteoMock getBid:cacheAdUnit]).andReturn(bid);
    return criteoMock;
}

- (CRNativeLoader *)buildLoaderWithAdUnit:(CRNativeAdUnit *)adUnit criteo:(Criteo *)criteo {
    CRNativeLoader *loader = [[CRNativeLoader alloc] initWithAdUnit:adUnit criteo:criteo];
    // Mock downloader to prevent actual downloads from the default downloader implementation.
    loader.mediaDownloader = OCMProtocolMock(@protocol(CRMediaDownloader));
    return loader;
}

- (void)loadNativeWithBid:(CR_CdbBid *)bid
                 delegate:(id <CRNativeDelegate>) delegate
                   verify:(void (^)(CRNativeLoader *loader, id <CRNativeDelegate> delegateMock, Criteo *criteoMock))verify {
    CRNativeAdUnit *adUnit = [[CRNativeAdUnit alloc] initWithAdUnitId:@"123"];
    Criteo *criteoMock = [self mockCriteoWithAdUnit:adUnit returnBid:bid];
    id <CRNativeDelegate> testDelegate = delegate ?: OCMStrictProtocolMock(@protocol(CRNativeDelegate));
    CRNativeLoader *loader = [self buildLoaderWithAdUnit:adUnit criteo:criteoMock];
    loader.delegate = testDelegate;
    [loader loadAd];
    verify(loader, testDelegate, criteoMock);
}

- (void)loadNativeWithBid:(CR_CdbBid *)bid
                   verify:(void (^)(CRNativeLoader *loader, id <CRNativeDelegate> delegateMock, Criteo *criteoMock))verify {
    [self loadNativeWithBid:bid delegate:nil verify:verify];
}

- (CR_CdbBid *)validBid {
    return [[CR_CdbBid alloc] initWithZoneId:@123
                                 placementId:@"placementId"
                                         cpm:@"4.2"
                                    currency:@"₹😀"
                                       width:@456.0f
                                      height:@789.0f
                                         ttl:26
                                    creative:@"THIS IS USELESS LEGACY"
                                  displayUrl:@""
                                  insertTime:[NSDate date]
                                nativeAssets:nil
                                impressionId:nil];
}

- (void)testReceiveOnMainQueue {
    CR_NativeLoaderDispatchChecker *delegate = [[CR_NativeLoaderDispatchChecker alloc] init];
    [self dispatchCheckerForBid:self.validBid delegate:delegate];
    [self waitForExpectations:@[delegate.didReceiveOnMainQueue] timeout:5];
}

- (void)testFailureOnMainQueue {
    CR_NativeLoaderDispatchChecker *delegate = [[CR_NativeLoaderDispatchChecker alloc] init];
    [self dispatchCheckerForBid:[CR_CdbBid emptyBid] delegate:delegate];
    [self waitForExpectations:@[delegate.didFailOnMainQueue] timeout:5];
}

- (void)testWillLeaveApplicationForNativeAdOnMainQueue {
    CR_NativeLoaderDispatchChecker *delegate = [[CR_NativeLoaderDispatchChecker alloc] init];
    CRNativeLoader *loader = [self dispatchCheckerForBid:[CR_CdbBid emptyBid] delegate:delegate];
    [loader notifyWillLeaveApplicationForNativeAd];
    [self waitForExpectations:@[delegate.willLeaveApplicationForNativeAd] timeout:5];
}

- (void)testDidDetectImpressionOnMainQueue {
    CR_NativeLoaderDispatchChecker *delegate = [[CR_NativeLoaderDispatchChecker alloc] init];
    CRNativeLoader *loader = [self dispatchCheckerForBid:[CR_CdbBid emptyBid] delegate:delegate];
    [loader notifyDidDetectImpression];
    [self waitForExpectations:@[delegate.didDetectImpression] timeout:5];
}

- (void)testDidDetectClickOnMainQueue {
    CR_NativeLoaderDispatchChecker *delegate = [[CR_NativeLoaderDispatchChecker alloc] init];
    CRNativeLoader *loader = [self dispatchCheckerForBid:[CR_CdbBid emptyBid] delegate:delegate];
    [loader notifyDidDetectClick];
    [self waitForExpectations:@[delegate.didDetectClick] timeout:5];
}

- (CRNativeLoader *)dispatchCheckerForBid:(CR_CdbBid *)bid
                                 delegate:(id<CRNativeDelegate>)delegate {
    CRNativeAdUnit *adUnit = [[CRNativeAdUnit alloc] initWithAdUnitId:@"123"];
    Criteo *criteoMock = [self mockCriteoWithAdUnit:adUnit returnBid:bid];
    CRNativeLoader *loader = [self buildLoaderWithAdUnit:adUnit criteo:criteoMock];
    loader.delegate = delegate;
    [loader loadAd];
    return loader;
}

- (void)testDoesNotConsumeBidWhenNotListeningToAds {
    id <CRNativeDelegate> delegateMock = OCMPartialMock([NSObject new]);
    [self loadNativeWithBid:self.validBid delegate:delegateMock verify:
        ^(CRNativeLoader *loader, id <CRNativeDelegate> delegateMock, Criteo *criteoMock) {
            OCMReject([criteoMock getBid:[OCMArg any]]);
        }];
}

@end

@implementation CR_NativeLoaderDispatchChecker

- (instancetype)init {
    self = [super init];
    if (self) {
        _didFailOnMainQueue = [[XCTestExpectation alloc] initWithDescription:@"Delegate should be called on main queue"];
        _didReceiveOnMainQueue = [[XCTestExpectation alloc] initWithDescription:@"Delegate should be called on main queue"];
        _didDetectImpression = [[XCTestExpectation alloc] initWithDescription:@"Delegate should be called on main queue"];
        _didDetectClick = [[XCTestExpectation alloc] initWithDescription:@"Delegate should be called on main queue"];
        _willLeaveApplicationForNativeAd = [[XCTestExpectation alloc] initWithDescription:@"Delegate should be called on main queue"];
    }
    return self;
}

- (void)nativeLoader:(CRNativeLoader *)loader didReceiveAd:(CRNativeAd *)ad {
    if (@available(iOS 10.0, *)) {
        dispatch_assert_queue(dispatch_get_main_queue());
        [_didReceiveOnMainQueue fulfill];
    }
}

- (void)nativeLoader:(CRNativeLoader *)loader didFailToReceiveAdWithError:(NSError *)error {
    if (@available(iOS 10.0, *)) {
        dispatch_assert_queue(dispatch_get_main_queue());
        [_didFailOnMainQueue fulfill];
    }
}

- (void)nativeLoaderDidDetectImpression:(CRNativeLoader *)loader {
    if (@available(iOS 10.0, *)) {
        dispatch_assert_queue(dispatch_get_main_queue());
        [_didDetectImpression fulfill];
    }
}

- (void)nativeLoaderDidDetectClick:(CRNativeLoader *)loader {
    if (@available(iOS 10.0, *)) {
        dispatch_assert_queue(dispatch_get_main_queue());
        [_didDetectClick fulfill];
    }
}

- (void)nativeLoaderWillLeaveApplicationForNativeAd:(CRNativeLoader *)loader {
    if (@available(iOS 10.0, *)) {
        dispatch_assert_queue(dispatch_get_main_queue());
        [_willLeaveApplicationForNativeAd fulfill];
    }
}

@end