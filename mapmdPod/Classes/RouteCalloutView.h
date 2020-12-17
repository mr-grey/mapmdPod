//
//  RouteCalloutView.h
//  mapmd
//
//  Created by user on 5/8/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Mapbox/MGLCalloutView.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, RouteCalloutStyle) {
    RouteCalloutStyleRed,
    RouteCalloutStyleWhite
};
@class MapMarker;
@interface RouteCalloutView : UIView <MGLCalloutViewDelegate , MGLCalloutView >
{
    UILabel *titleLabel;
    UIView *backgroundView;
}

@property (nonatomic,weak) MapMarker *marker;
@property (nonatomic, readwrite, assign) BOOL dismissesAutomatically;
@property (nonatomic, weak) id<MGLCalloutViewDelegate> delegate;

@end

@interface RouteCalloutBackgroundView : UIView

@property (nonatomic, copy) UIColor *strokeColor;
@property (nonatomic, copy) UIColor *fillColor;
@end

NS_ASSUME_NONNULL_END
