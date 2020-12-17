//
//  MarkerManager.h
//  map_new_engine
//
//  Created by grey on 7/6/16.
//  Copyright © 2016 grey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mapbox/Mapbox.h>
#import "MapPolygon.h"
#import "MapMarker.h"

@class MapView;
@class SMapRoute;

// this class receive notifications with name:  "doSelectAnnotation" , "doDeselectAnnotation"


@interface MarkerManager : NSObject

@property (nonatomic, readonly) NSMutableArray *markers;
@property (nonatomic, readonly) NSMutableArray *hiddenMarkers;

@property (nonatomic, weak) MapView *mapView;


- (instancetype)initWithMap:(MapView*)map;

- (void)addPolygon:(MapPolygon*)polygon;
- (void)removePolygon:(MapPolygon*)p;

- (void)addMarker:(MapMarker *)marker;

// map.md representation
- (void)addClusters:(NSURL *)geojson;

// classic presentation
- (void)displayClusters:(NSURL*)geojson;

// display route pins like arrows with direction
- (void)displayRouteArrows:(SMapRoute *)r;


- (MapMarker*)addMarker:(NSDictionary*)dict withType:(MarkerType)type;
- (void)addMakerAtCoordinates:(CLLocationCoordinate2D)loc;
- (void)removeMarkers;
- (void)removeMarker:(MapMarker *)marker;

- (void)removeMarkerWhithId:(NSString *)markerId;
- (BOOL)haveMarkers;

- (MapMarker*)getDropedPin;
/* against selected */
- (void)hideAllMarkerLabels;

/* set visible false */
- (void)hideMarker:(MapMarker *)marker;

/* set visible true */
- (void)showMarker:(MapMarker *)marker;
@end
