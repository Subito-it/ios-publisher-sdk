//
//  CRBannerView.m
//  pubsdk
//
//  Created by Julien Stoeffler on 4/3/19.
//  Copyright © 2019 Criteo. All rights reserved.
//

#import "CRBannerView.h"
#import "Criteo.h"
#import "CR_CdbBid.h"
#import "Criteo+Internal.h"
#import "CR_BidManager.h"

//TODO check import strategy
@import WebKit;


@interface CRBannerView() <WKNavigationDelegate>
@property (nonatomic, strong) Criteo *criteo;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, weak) UIApplication *application;
@end

@implementation CRBannerView


- (instancetype)initWithFrame:(CGRect)rect {
    return [self initWithFrame:rect
                        criteo:[Criteo sharedCriteo]
                       webView:[[WKWebView alloc] initWithFrame:CGRectMake(.0, .0,rect.size.width, rect.size.height)]
                   application:[UIApplication sharedApplication]];
}

- (instancetype)initWithFrame:(CGRect)rect
                       criteo:(Criteo *)criteo
                      webView:(WKWebView *)webView
                  application:(UIApplication *)application {
    if(self = [super initWithFrame:rect]) {
        _criteo = criteo;
        _webView = webView;
        _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _webView.scrollView.scrollEnabled = false;
        _webView.navigationDelegate = self;
        [self addSubview:webView];
        _application = application;
    }
    return self;
}

- (void)loadAd:(NSString *)adUnitId {
    CRAdUnit *adUnit = [[CRAdUnit alloc] initWithAdUnitId:adUnitId
                                                     size:self.frame.size];
    CR_CdbBid *bid = [self.criteo getBid:adUnit];
    if([bid isEmpty]) {
        return;
    }
    NSString *htmlString = [NSString stringWithFormat:@"<!doctype html>"
                            "<html>"
                            "<head>"
                            "<meta charset=\"utf-8\">"
                            "<style>body{margin:0;padding:0}</style>"
                            "<meta name=\"viewport\" content=\"width=%ld, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no\" >"
                            "</head>"
                            "<body>"
                            "<script src=\"%@\"></script>"
                            "</body>"
                            "</html>", (long)self.frame.size.width , bid.displayUrl];
    [_webView loadHTMLString:htmlString baseURL:[NSURL URLWithString:@"about:blank"]];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if(navigationAction.navigationType == WKNavigationTypeLinkActivated && [navigationAction.sourceFrame isMainFrame]) {
        if(navigationAction.request.URL != nil) {
            if([self.application canOpenURL:navigationAction.request.URL]) {
                [self.application openURL:navigationAction.request.URL];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end