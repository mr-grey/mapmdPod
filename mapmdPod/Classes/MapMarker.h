//
//  MapMarker.h
//  map_new_engine
//
//  Created by grey on 7/6/16.
//  Copyright © 2016 grey. All rights reserved.
//

#import <Mapbox/Mapbox.h>
#import <Mapbox/MGLAnnotation.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MarkerType) {
    MarkerTypeTest,
    MarkerTypeGroup,
    MarkerTypeDefault,
    MarkerTypeDroppedPin,
    MarkerTypePin,
    MarkerTypePolylinePin,
    MarkerTypeAd,
    MarkerTypeMyLocation,
    MarkerTypePinAddress,
    MarkerTypeRouteStartPin,
    MarkerTypeRouteCenterPin,
    MarkerTypeRouteDirection,
    MarkerTypeTemporary
    
};

@interface MapMarker : NSObject <MGLAnnotation>
@property (readwrite) BOOL isSelected;
@property (readwrite) BOOL selectable;
@property (readwrite) BOOL canShowCallout;
@property (nonatomic, retain) NSString *objectid;
@property NSInteger category_id;
@property (nonatomic, retain) NSDictionary *dict;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) UIImage *selectedImage;
@property (nonatomic, weak) id annotation;
@property (readwrite) MarkerType marker_type;
@property (readwrite) BOOL placeGeocoded;
@property (readwrite) double bearing;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) UIView <MGLCalloutView> *calloutView;
@property (nonatomic, readwrite) CGSize imageOffset; // default is Zero
@property (nonatomic, readwrite) NSInteger count; // used for MarkerTypeGroup

@end

