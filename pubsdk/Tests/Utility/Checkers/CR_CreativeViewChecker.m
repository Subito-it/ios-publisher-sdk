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


@implementation CR_CreativeViewChecker

- (instancetype)initWithAdUnit:(CRBannerAdUnit *)adUnit criteo:(Criteo *)criteo {
    if (self = [super init]) {
        _bannerViewDidReceiveAdExpectation = [[XCTestExpectation alloc] initWithDescription:@"Expect that CRBannerView will get a bid"];
        _bannerViewFailToReceiveAdExpectation = [[XCTestExpectation alloc] initWithDescription:@"Expect that CRBannerView will fail to get a bid"];
        _adCreativeRenderedExpectation = [[XCTestExpectation alloc] initWithDescription:@"Expect that Criteo creative appears."];
        _uiWindow = [self createUIWindow];

        // NOTE: bannerView was created with frame (0; 50; w; h) because with (0; 0; ...) banner is displayed wrong.
        // TODO: Find a way to render banner with (0;0; ...).
        _bannerView = [[CRBannerView alloc] initWithFrame:CGRectMake(.0, 50.0, adUnit.size.width, adUnit.size.height)
                                                   criteo:criteo
                                                  webView:[[WKWebView alloc] initWithFrame:CGRectMake(.0, .0, adUnit.size.width, adUnit.size.height)]
                                              application:[UIApplication sharedApplication]
                                                   adUnit:adUnit];

        _bannerView.delegate = self;
        _bannerView.backgroundColor = UIColor.orangeColor;
        [_uiWindow.rootViewController.view addSubview:_bannerView];
    }
    return self;
}

#pragma mark - CRBannerViewDelegate methods

- (void)banner:(CRBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    NSLog(@"%@", error.localizedDescription);
    [self.bannerViewFailToReceiveAdExpectation fulfill];
}

- (void)bannerWillLeaveApplication:(CRBannerView *)bannerView {
    NSLog(@"[AAAA] bannerWillLeaveApplication");
}

- (void)bannerDidReceiveAd:(CRBannerView *)bannerView {
    [self.bannerViewDidReceiveAdExpectation fulfill];
    [CR_Timer scheduledTimerWithTimeInterval:1
                                     repeats:NO
                                       block:^(NSTimer *_Nonnull timer) {
                                           [self checkViewAndFulfillExpectation];
                                       }];
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
                       if ([htmlContent containsString:[CR_ViewCheckingHelper preprodCreativeImageUrl]]) {
                           [self.adCreativeRenderedExpectation fulfill];
                       }
                       self.uiWindow.hidden = YES;
                   }];
}

@end