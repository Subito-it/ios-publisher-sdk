//
//  CRBannerView.h
//  CriteoPublisherSdk
//
//  Copyright © 2018-2020 Criteo. All rights reserved.
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

#import <UIKit/UIKit.h>
#import "CRBannerViewDelegate.h"
#import "CRBidToken.h"
#import "CRBannerAdUnit.h"

NS_ASSUME_NONNULL_BEGIN

@interface CRBannerView : UIView
@property(nullable, nonatomic, weak) id<CRBannerViewDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithAdUnit:(CRBannerAdUnit *)adUnit;

- (void)loadAd;
- (void)loadAdWithBidToken:(CRBidToken *)bidToken;

@end

NS_ASSUME_NONNULL_END
