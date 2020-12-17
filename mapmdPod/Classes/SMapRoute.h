//
//  SMapRoute.h
//  mapmd
//
//  Created by user on 5/13/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <Mapbox/MGLLineStyleLayer.h>

@class MGLShapeSource;
@class MapMarker;
@class MGLLineStyleLayer;
@class MGLPolylineFeature;


NS_ASSUME_NONNULL_BEGIN

@interface SMapRoute : NSObject
@property (nonatomic, retain) NSString *routeId;
@property (nonatomic, retain) MGLPolylineFeature *polyline;
@property (nonatomic, retain) MGLLineStyleLayer *strokeLayer;
@property (nonatomic, retain) MGLLineStyleLayer *layer;
@property (nonatomic, retain) MapMarker *marker;
@property (nonatomic, retain) MGLShapeSource *source;
@property (nonatomic, copy) UIColor *selectedColor;
@property (nonatomic, copy) UIColor *selectedStrokeColor;
@property (nonatomic, copy) UIColor *color;
@property (nonatomic, copy) UIColor *strokeColor;
@property (nonatomic, readwrite) BOOL selected;
@property (nonatomic, readwrite) BOOL canSelect; // or deselect ;; by default is true

/**
 Display route path like public transport
 @param info
 {
 "points": [ [lng,lat],[lng,lat].. ]
 "id": "route -identifier"
 "color": UIColor
 
 }
 */
- (instancetype)initWithRouteInfo:(NSDictionary *)info;

/**
 Returns route points array
  [ {[lng,lat]},{[lng,lat]}.. ]
 */
- (NSArray *)getPoints;

/**
 Returns route duration in seconds
 can be zero
 */
- (double)getDuration;


/**
 Drops points outside from location and start point
 */
- (void)trimRoute:(NSValue *)coordinates;
/**
 Return an url to geojson file named r_direction.json, containing featured points, with angles.
 
 
 */
- (NSURL *)getArrowsUrl;


@end




NS_ASSUME_NONNULL_END
