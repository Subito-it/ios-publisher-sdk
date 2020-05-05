//
//  CRNativeAdView.h
//  AdViewer
//
//  Copyright © 2018-2020 Criteo. All rights reserved.
//

@import UIKit;
#import <CriteoPublisherSdk/CriteoPublisherSdk.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRVNativeAdView : UIView<CRNativeDelegate>

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *bodyLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

NS_ASSUME_NONNULL_END