//
//  RouteAnnotationView.h
//  mapmd
//
//  Created by user on 5/8/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import <Mapbox/Mapbox.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM( NSUInteger, RouteAnnotationViewStyle)  {
    RouteAnnotationViewStyleWhite = 0,
    RouteAnnotationViewStyleOrange = 1
};

@interface RouteAnnotationView : MGLAnnotationView
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) UIColor *tintColor;
@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, readwrite) BOOL canDeselect;
@property (nonatomic, readwrite) BOOL canSelect;
@property (nonatomic, readwrite) RouteAnnotationViewStyle style;
@end


NS_ASSUME_NONNULL_END
