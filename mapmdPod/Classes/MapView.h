//
//  MapView.h
//  map
//
//  Created by user on 4/10/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "SMapHelper.h"


@class MGLMapView;
@class MarkerManager;
@class MapMarker;
@class MapView;
@class MGLShapeSource;
@class SMapRoute;
@class SMapObject;

@protocol MGLCalloutView;
@protocol MGLAnnotation;

typedef NS_ENUM(NSUInteger, MapViewMode) {
    MapViewModeDefault,
    MapViewModeCompass,
    MapViewModeFollow,
    MapViewModeDrive
};

@protocol MapViewDelegate <NSObject>

@optional

- (UIView <MGLCalloutView> *)calloutViewForAnnotation:(MapMarker *)marker;
- (void)tapOnMap:(NSValue *)tapCoordinate;
- (void)regionDidChange:(NSNumber *)reason;
- (void)regionWillChange:(NSNumber *)reason;
- (void)didSelectAnnotation:(id <MGLAnnotation>) annotation;
- (void)didDeselectAnnotation:(id<MGLAnnotation>)annotation;
- (void)didSelectRoute:(SMapRoute *)route;
- (void)didDropPin:(MapMarker *)marker;
- (BOOL)mapView:(MapView *)map shouldRestoreSource:(MGLShapeSource *)source; // it may be route or clusters
@end


@interface MapView : UIView

@property (nonatomic, readonly) UIButton *satelliteButton;
@property (nonatomic, weak) id <MapViewDelegate> delegate;

/**
 When user long press at mapview, Call this method to enable this feature
 */
- (void)enableLongPress;
- (void)disableLongPress;

/**
User location
 */
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

- (void)moveToUserLocation;
- (void)moveTo:(CLLocationCoordinate2D )location;

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(double)zoomLevel animated:(BOOL)animated;
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;

- (void)setMapViewMode:(MapViewMode)mode;

- (void)setZoomLevel:(double)level;
- (float)zoomLevel;

- (CLLocationCoordinate2D)centerCoordinate;
- (BOOL)isUserLocationVisible;
- (BOOL)isUserLocationInCenter;
- (CLLocation *)userLocation;
- (BOOL)isShowingClusters;

/**
 returns based MGLMapView Object
 */
- (MGLMapView *)getMapView;
- (void)setLogoPosition:(MapLogoPosition)position;
- (void)showLogo; // set it visible
/**
 A `CGPoint` indicating the position offset of the compass.
 */
- (void)setCompassOffset:(CGPoint)offset;

- (MarkerManager *)markerManager;
- (void)deselectAll;
- (void)selectMarker:(MapMarker *)m;
- (void)selectMarker:(MapMarker *)m animated:(BOOL)a;
- (void)deselectMarker:(MapMarker *)m;
- (void)deselectMarker:(MapMarker *)m animated:(BOOL)a;

- (void)showSatellite:(BOOL)show;
- (void)removeAllRoutes;

/**
    Return an Route with id
    can be null
 */
- (SMapRoute*)getRouteById:(NSString *)ID;

/**
Display route path like public transport
@param routeInfo
 {
    "points": [ [lng,lat], [lng,lat].. ]
    "id": "route-identifier"
    "color": UIColor
 }
*/
- (void)addRoute:(NSDictionary *)routeInfo;

/**
 Makes visible viewport to fit all route coordinates 
 @param rid - is routeid
 @param padding - The inset of map bounds
 */
- (void)zoomToRoute:(NSString *)rid edgePadding:(UIEdgeInsets)padding;

/**
Select one route with id
 @param rid - is route id
*/
- (void)setRouteSelected:(BOOL )selected routeId:(NSString *)rid;

/**
 Add more that one route at map and select one
 @param routes - array of routes
 
 the route {
 "points": [ [lng,lat], [lng,lat].. ]
 "id": "route -identifier"
 "color": UIColor
 }
 
 */
- (void)addNavigationRoutes:(NSArray *)routes;

/**
  set selected route displayed by 'addNavigationRoutes:'
  it find route by id passed in parametr rid
 */
- (void)selectRoute:(NSString *)rid;

/**
 Clears all on map
 */
- (void)clearMap;

/**
 Clears all on map, keep selected marker
 MarkerTypeTemporary and MarkerTypeRouteCenterPin are ignored (removed)
 */
- (void)clearMap:(BOOL)keepSelected;

/**
Clears all on map, keep  markers in array
@param annotations is array of markers to keep on map
 */
- (void)clearMapKeepAnnotations:(NSArray *)annotations;


/**
 add an object to array,
*/
- (void)addMapObject:(SMapObject *)object;

@end


