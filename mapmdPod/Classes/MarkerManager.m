//
//  MarkerManager.m
//  map_new_engine
//
//  Created by grey on 7/6/16.
//  Copyright © 2016 grey. All rights reserved.
//

#import "MarkerManager.h"
#import "MapMarker.h"
#import "map.h"
#import "SMapRoute.h"
#import "SMapObject.h"

@import Mapbox;
@import MapKit;

@implementation MarkerManager
@synthesize mapView;
@synthesize markers;
@synthesize hiddenMarkers;


- (instancetype)init {
    
    self = [super init];
  
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNotificationRemove:) name:@"needRemoveMarker" object:nil];
    
    return self;
}

- (instancetype)initWithMap:(MapView*)map {
    
    self = [super init];
    
    mapView = map;
    markers = [[NSMutableArray alloc] init];
    hiddenMarkers = [[NSMutableArray alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNotificationRemove:) name:@"needRemoveMarker" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doSelectAnnotation:) name:@"doSelectAnnotation" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doDeselectAnnotation:) name:@"doDeselectAnnotation" object:nil];
    
    return self;
}

- (void)doDeselectAnnotation:(NSNotification *)notif {
   
    id annotation = [notif object];
    id animated = [notif userInfo];
    MGLMapView *glmap = [mapView getMapView];
    
    if (annotation && ([annotation class] == [MapMarker class])) {
        MapMarker *marker = annotation;
        marker.isSelected = false;
        if (animated)
         [glmap deselectAnnotation:marker animated:YES];
        else
         [glmap deselectAnnotation:marker animated:NO];
    }
}

- (void)doSelectAnnotation:(NSNotification *)notif {
    id annotation = [notif object];
    id animated = [notif userInfo];
    
    MGLMapView *glmap = [mapView getMapView];
    
    if (annotation && ([annotation class] == [MapMarker class])) {
        MapMarker *marker = annotation;
        marker.isSelected = true;
        if (animated)
         [glmap selectAnnotation:marker animated:YES];
        else
         [glmap selectAnnotation:marker animated:NO];
    }
}

- (void)removePolygon:(MapPolygon*)p {
    MGLMapView *glmap = [mapView getMapView];
    [glmap removeAnnotation:p];
}

- (void)addPolygon:(MapPolygon*)p {
    
    
    MapMarker *markerPolygon = [p centerPin];
    MGLMapView *glmap = [mapView getMapView];
    
    if (!markerPolygon) {
        [p setup];
        markerPolygon = [p centerPin];
    }
    
    [glmap addAnnotation:p];
    [glmap addAnnotation:markerPolygon];
}

- (BOOL)haveMarkers {
    MGLMapView *glmap = [mapView getMapView];
    NSArray *annotations = [glmap annotations];
  
    
    for ( id<MGLAnnotation> a in annotations) {
        
        if ([a class] == [MapMarker class]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)didReceiveNotificationRemove:(NSNotification*)notif {
    id object = notif.object;
    if (object) {
        [self removeMarker:object];
    }
}

- (void)removeMarker:(id < MGLAnnotation >)marker {
    SMLog(@"$ to remove : %@",marker);
    MGLMapView *glmap = [mapView getMapView];
    
    if (marker) {
        [glmap removeAnnotation:marker];
    }
}

- (void)addMarker:(id < MGLAnnotation >)marker {
    MGLMapView *glmap = [mapView getMapView];
    if (marker) {
        SMLog(@"%@",marker);
        [glmap addAnnotation:marker];
    }
        
}


- (void)removeMarkerWhithId:(NSString *)markerId {
    
    if (!markerId) return;
    MGLMapView *glmap = [mapView getMapView];
    
    NSArray *annotations = [glmap annotations];
    id toRemove = nil;
    
    for ( id<MGLAnnotation> a in annotations) {
        
        if ([a class] == [MapMarker class]) {
            MapMarker *marker = a;
           
            if ([markerId isEqualToString:marker.objectid]) {
                toRemove = a;
                break;
            }
        }
    }
    
    if (toRemove) {
        [self removeMarker:toRemove];
    }
}

- (MapMarker*)addMarker:(NSDictionary*)dict withType:(MarkerType)type {
    
    
    NSValue *coords = [dict objectForKey:@"coordinate"];
    NSString *object_id = [dict objectForKey:@"objectid"];
    NSString *category_id = [dict objectForKey:@"categoryid"];
    NSNumber *selectable = [dict objectForKey:@"selectable"];
    
    BOOL canSelect = NO;
    
    MapMarker *annotation = [[MapMarker alloc] init];
   
    if (selectable) {
     
        canSelect = [selectable boolValue];
        
        annotation.selectable = canSelect;
        
    }
    
    
    if (coords == nil) {
        return nil;
    }
    
    MGLMapView *glmap = [mapView getMapView];
    
    CLLocationCoordinate2D loc = [coords MKCoordinateValue];
    
    
   
    annotation.objectid = object_id;
    annotation.category_id = [category_id integerValue];
    annotation.coordinate = loc;
    
    annotation.marker_type = type;
  
    if (type == MarkerTypeTest) {
        NSString *title = dict[@"title"];
        NSString *subtitle = dict[@"subtitle"];
      
        [annotation setTitle:title];
        [annotation setSubtitle:subtitle];
     
        annotation.dict = dict;
        annotation.selectable = YES;
        UIImage *image = dict[@"UIImage"];
        
        if (image) annotation.image = image;
    
    }
    
    if (type == MarkerTypePin || type == MarkerTypeDefault) {
        
        NSString *title = dict[@"title"];
        NSString *subtitle = dict[@"subtitle"];
        canSelect = [selectable boolValue];

        if (title && title.length) { annotation.placeGeocoded = YES; }
        
        if (!title) title = @"\t";
        if (!subtitle) subtitle = @"";
        
        annotation.image = [UIImage imageNamed:@"pin"];
        annotation.selectedImage = [UIImage imageNamed:@"pin_selected"];
        
        annotation.title = title;
        annotation.subtitle = subtitle;
        
        annotation.dict = dict;
        annotation.selectable = canSelect;

    }
    
    if (type == MarkerTypeAd) {

        [annotation setTitle:@" "]; // You can set the subtitle too
        annotation.selectable = YES;
        
        UIImage *image = dict[@"UIImage"];
        
        if (image) annotation.image = image;
        
        [glmap addAnnotation:annotation];
        
        return annotation;
    }
    
    if (type == MarkerTypePolylinePin) {
        
        UIImage *image = dict[@"UIImage"];
        
        if (image) annotation.image = image;
        
        [glmap addAnnotation:annotation];
        
        return annotation;
    }
    
    if (type == MarkerTypeTemporary) {
        NSString *title = dict[@"title"];
        NSString *subtitle = dict[@"subtitle"];
        [annotation setTitle:title];
        [annotation setSubtitle:subtitle];
        annotation.dict = dict;
        annotation.selectable = NO;
        annotation.image = [UIImage imageNamed:@"pin"];
        annotation.selectedImage = [UIImage imageNamed:@"pin_selected"];
    }
    
    
    if (type == MarkerTypePinAddress) {
        
        NSString *title = dict[@"title"];
        NSString *subtitle = dict[@"subtitle"];
        NSNumber *show_routes = dict[@"show_routes"];
        
        [annotation setTitle:title];
        [annotation setSubtitle:subtitle];
        annotation.dict = dict;
        annotation.selectable = YES;
        annotation.placeGeocoded = YES;
        
        if (show_routes.boolValue) {
            
        }
    }
  
    [glmap addAnnotation:annotation];
    
    if (type == MarkerTypeTemporary) {
        // used for show  MGLPointFeature on clustering mode
        annotation.placeGeocoded = YES;
       // [glmap selectAnnotation:annotation moveIntoView:YES animateSelection:YES];
      [glmap selectAnnotation:annotation moveIntoView:YES animateSelection:YES completionHandler:^{
        
      }];
    }
    return annotation;
    
}


- (void)addMakerAtCoordinates:(CLLocationCoordinate2D)loc {
     
    MGLMapView *glmap = [mapView getMapView];
   
    MapMarker *annotation = [[MapMarker alloc] init];
    [annotation setCoordinate:loc];
    [annotation setTitle:@"maker"]; //You can set the subtitle too
    
    [glmap addAnnotation:annotation];
    

}

/* against selected marker */

- (void)hideAllMarkerLabels {
    MGLMapView *glmap = [mapView getMapView];
    NSArray *mar = [glmap annotations];

    for (id <MGLAnnotation>m in mar ) {
        [glmap deselectAnnotation:m animated:NO];
    }
    
}

- (void)showMarker:(MapMarker *)marker {
    MGLMapView *glmap = [mapView getMapView];
    [glmap addAnnotation:marker];
    [hiddenMarkers removeObject:marker];
    
}

- (void)hideMarker:(MapMarker *)marker {
    MGLMapView *glmap = [mapView getMapView];
    [glmap removeAnnotation:marker];
    [hiddenMarkers addObject:marker];
    
    [mapView setNeedsDisplay];
}

- (MapMarker*)getDropedPin {
    MGLMapView *glmap = [mapView getMapView];
    NSArray *mar = [glmap annotations];
    for (id <MKAnnotation>m in mar ) {
        if ([m isKindOfClass:[MapMarker class]]) {
            MapMarker *marker = (id)m;
            if (marker.marker_type == MarkerTypeDroppedPin) {
                return marker;
            }
        }
    }
    
    for (MapMarker *m in hiddenMarkers) {
        if (m.marker_type == MarkerTypeDroppedPin) {
            return m;
        }
    }
    
    
    return nil;
}

- (void)removeMarkers {
    SMLog(@"");
    MGLMapView *glmap = [mapView getMapView];
    NSArray *mar = [glmap annotations];
    [glmap removeAnnotations:mar];
}

- (void)addClusters:(NSURL *)geojson {
    
    MGLMapView *glmap = [mapView getMapView];
    MGLStyle *style = [glmap style];
    MGLShapeSource *source = [[MGLShapeSource alloc] initWithIdentifier:@"clusteredPins" URL:geojson options:@{
                                                                                                            MGLShapeSourceOptionClustered: @(YES),
                                                                                                            MGLShapeSourceOptionClusterRadius: @(31)
                                                                                                            }];
    if (source == nil) { NSLog(@"error: shape not loaded!");  return; }
    
    [style addSource:source];
    // Use a template image so that we can tint it with the `iconColor` runtime styling property.
    [style setImage:[UIImage imageNamed:@"cluster"] forName:@"cluster"];
    [style setImage:[UIImage imageNamed:@"pin"] forName:@"pin"];
    
    MGLSymbolStyleLayer *pins = [[MGLSymbolStyleLayer alloc] initWithIdentifier:@"clusteredPins" source:source];
    pins.predicate = [NSPredicate predicateWithFormat:@"cluster != YES && visible == YES"];
    pins.iconImageName = [NSExpression expressionForConstantValue:@"pin"];
    
    [style addLayer:pins];
    
    
    MGLSymbolStyleLayer *clusters = [[MGLSymbolStyleLayer alloc] initWithIdentifier:@"clusters" source:source];
    clusters.predicate = [NSPredicate predicateWithFormat:@"cluster == YES"];
    clusters.iconImageName = [NSExpression expressionForConstantValue:@"cluster"];
    
    [style addLayer:clusters];
    
    
    
    SMapObject *obj = [[SMapObject alloc] initWithUrl:geojson];
    obj.source = source;
    
    [obj addLayer:pins];
    [obj addLayer:clusters];
    
    [mapView addMapObject:obj];
}

// classic presentation
- (void)displayClusters:(NSURL*)geojson {
    
    MGLMapView *glmap = [mapView getMapView];
    MGLStyle *style = [glmap style];
    MGLShapeSource *source = [[MGLShapeSource alloc] initWithIdentifier:@"clusteredPins" URL:geojson options:@{
                                                                                                               MGLShapeSourceOptionClustered: @(YES),
                                                                                                               MGLShapeSourceOptionClusterRadius: @(31)
                                                                                                               }];
    if (source == nil) { NSLog(@"error: shape not loaded!");  return; }
    UIImage *pinImage = [SMapHelper imageForGroup:1];
    UIImage *clusterImage = [SMapHelper imageForGroup:0];
    
    [style addSource:source];
    // Use a template image so that we can tint it with the `iconColor` runtime styling property.
    [style setImage:clusterImage forName:@"cluster"];
    [style setImage:pinImage forName:@"pin"];
    
    MGLSymbolStyleLayer *pins = [[MGLSymbolStyleLayer alloc] initWithIdentifier:@"clusteredPins" source:source];
    pins.predicate = [NSPredicate predicateWithFormat:@"cluster != YES && visible == YES"];
    pins.iconImageName = [NSExpression expressionForConstantValue:@"pin"];
    
    [style addLayer:pins];
    
    
    MGLSymbolStyleLayer *clusters = [[MGLSymbolStyleLayer alloc] initWithIdentifier:@"clusters" source:source];
    clusters.predicate = [NSPredicate predicateWithFormat:@"cluster == YES"];
   
    clusters.iconImageName = [NSExpression expressionForConstantValue:@"cluster"];
    clusters.text = [NSExpression expressionWithFormat:@"CAST(point_count, 'NSString')"];
    clusters.textColor = [NSExpression expressionForConstantValue:[UIColor whiteColor]];
    clusters.textFontSize = [NSExpression expressionForConstantValue:@(15)];
    clusters.textFontNames = [NSExpression expressionForConstantValue: @[@"Arial Bold", @"Arial-Bold"]];
    
    [style addLayer:clusters];
    
    SMapObject *obj = [[SMapObject alloc] initWithUrl:geojson];
    obj.source = source;
      
    [obj addLayer:pins];
    [obj addLayer:clusters];
    [mapView addMapObject:obj];
}


- (void)displayRouteArrows:(SMapRoute *)r {
    
    if (!r) return;
    NSURL *geoJson = [r getArrowsUrl];
    
    MGLSource *source = [[MGLShapeSource alloc] initWithIdentifier:@"arrows" URL:geoJson options:@{}];
    
    MGLMapView *glmap = [mapView getMapView];
    MGLStyle *style = [glmap style];
    
    [style addSource:source];
    [style setImage:[UIImage imageNamed:@"route_dir_pin"] forName:@"route_dir_pin"];
    
    MGLSymbolStyleLayer *droneLayer = [[MGLSymbolStyleLayer alloc] initWithIdentifier:@"route_pin_direction" source:source];
    droneLayer.iconImageName = [NSExpression expressionForConstantValue:@"route_dir_pin"];
    droneLayer.iconRotation = [NSExpression expressionForKeyPath:@"rotate"];
    droneLayer.iconAllowsOverlap =  [NSExpression expressionForConstantValue:@"NO"];
    droneLayer.iconRotationAlignment = [NSExpression expressionForConstantValue:@"map"];
    droneLayer.minimumZoomLevel = 12;
    
    MGLStyleLayer *la = [r layer];
    
    
    [style insertLayer:droneLayer aboveLayer:la];
    
    SMapObject *obj = [[SMapObject alloc] initWithUrl:geoJson];
    obj.source = source;
    [obj addLayer:droneLayer];
    
    [mapView addMapObject:obj];
}

@end
