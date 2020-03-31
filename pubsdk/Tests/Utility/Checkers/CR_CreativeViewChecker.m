//
// Created by Aleksandr Pakhmutov on 24/12/2019.
// Copyright (c) 2019 Criteo. All rights reserved.
//

#import "CR_CreativeViewChecker.h"
#import "Criteo.h"
#import "CRBannerView+Internal.h"
#import "UIView+Testing.h"
#import "CR_Timer.h"
#import <XCTest/XCTest.h>
#import <WebKit/WebKit.h>
#import "CR_ViewCheckingHelper.h"
#import "CR_CacheAdUnit.h"
#import "CR_AdUnitHelper.h"
#import "CR_CdbBidBuilder.h"
#import "Criteo+Testing.h"
#import "CR_BidManagerBuilder.h"


@implementation CR_CreativeViewChecker

- (instancetype)initWithAdUnit:(CRBannerAdUnit *)adUnitParam criteo:(Criteo *)criteoParam {
    if (self = [super init]) {
        [self resetExpectations];
        _uiWindow = [self createUIWindow];
        _adUnit = adUnitParam;
        _criteo = criteoParam;
        [self resetBannerView];
        _expectedCreativeUrl = [CR_ViewCheckingHelper preprodCreativeImageUrl];
    }
    return self;
}

- (void)injectBidWithExpectedCreativeUrl:(NSString *)creativeUrl {
    self.expectedCreativeUrl = creativeUrl;
    CR_CacheAdUnit *cacheAdUnit = [CR_AdUnitHelper cacheAdUnitForAdUnit:self.adUnit];
    CR_CdbBid *bid = CR_CdbBidBuilder.new.adUnit(cacheAdUnit).cpm(@"15.00").displayUrl(creativeUrl).build;
    self.criteo.bidManagerBuilder.cacheManager.bidCache[cacheAdUnit] = bid;
}

- (void)dealloc {
    _bannerView.delegate = nil;
}

#pragma mark - CRBannerViewDelegate methods

- (void)banner:(CRBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    NSLog(@"%@", error.localizedDescription);
    [self.bannerViewFailToReceiveAdExpectation fulfill];
}

- (void)bannerWillLeaveApplication:(CRBannerView *)bannerView {
    NSLog(@"[CR_CreativeViewChecker] bannerWillLeaveApplication");
}

- (void)bannerDidReceiveAd:(CRBannerView *)bannerView {
    [self.bannerViewDidReceiveAdExpectation fulfill];
    [CR_Timer scheduledTimerWithTimeInterval:1
                                     repeats:NO
                                       block:^(NSTimer *_Nonnull timer) {
                                           [self checkViewAndFulfillExpectation];
                                       }];
}

- (void)resetExpectations {
    _bannerViewDidReceiveAdExpectation = [[XCTestExpectation alloc] initWithDescription:@"Expect that CRBannerView will get a bid"];
    _bannerViewFailToReceiveAdExpectation = [[XCTestExpectation alloc] initWithDescription:@"Expect that CRBannerView will fail to get a bid"];
    _adCreativeRenderedExpectation = [[XCTestExpectation alloc] initWithDescription:@"Expect that Criteo creative appears."];
}

- (void)resetBannerView {
    [_bannerView removeFromSuperview];
    // NOTE: bannerView was created with frame (0; 50; w; h) because with (0; 0; ...) banner is displayed wrong.
    // TODO: Find a way to render banner with (0;0; ...).
    _bannerView = [[CRBannerView alloc] initWithFrame:CGRectMake(.0, 50.0, self.adUnit.size.width, self.adUnit.size.height)
                                               criteo:self.criteo
                                              webView:[[WKWebView alloc] initWithFrame:CGRectMake(.0, .0, self.adUnit.size.width, self.adUnit.size.height)]
                                          application:[UIApplication sharedApplication]
                                               adUnit:self.adUnit];

    _bannerView.delegate = self;
    _bannerView.backgroundColor = UIColor.orangeColor;
    [_uiWindow.rootViewController.view addSubview:_bannerView];
}


#pragma mark - Private methods

- (UIWindow *)createUIWindow {
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 50, 320, 480)];
    [window makeKeyAndVisible];
    UIViewController *viewController = [UIViewController new];
    window.rootViewController = viewController;
    return window;
}

- (void)checkViewAndFulfillExpectation {
    WKWebView *firstWebView = [self.uiWindow testing_findFirstWKWebView];
    [firstWebView evaluateJavaScript:@"(function() { return document.getElementsByTagName('html')[0].outerHTML; })();"
                   completionHandler:^(NSString *htmlContent, NSError *err) {
        self.uiWindow.hidden = YES;
        if ([htmlContent containsString:self.expectedCreativeUrl]) {
            [self.adCreativeRenderedExpectation fulfill];
        }
    }];
}

@end