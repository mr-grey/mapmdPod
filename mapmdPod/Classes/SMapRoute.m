//
//  SMapRoute.m
//  mapmd
//
//  Created by user on 5/13/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import "SMapRoute.h"
#import <Mapbox/Mapbox.h>
#import "Routing.h"
#import "MapMarker.h"
#import "SMapHelper.h"

@interface SMapRoute()
@property (nonatomic, retain) NSMutableArray *arrows;
@property (nonatomic, retain) NSMutableArray *points;
@property (readwrite) double duration;
@end

@implementation SMapRoute
@synthesize polyline;
@synthesize strokeLayer;
@synthesize routeId;
@synthesize source;
@synthesize layer;
@synthesize canSelect;
@synthesize selectedStrokeColor;


- (instancetype)init {
    self = [super init];
    routeId = @"rid_000000";
    return self;
}

- (instancetype)initWithRouteInfo:(NSDictionary *)info {
    self = [super init];
    self.points = [[NSMutableArray alloc] init];
    canSelect = true;
    
    NSArray *route_points = info[@"points"];
    UIColor *cl = info[@"color"]; //
    UIColor *st = info[@"stroke"];
    UIColor *selectColor = info[@"selectedColor"];
    UIColor *selectSColor = info[@"selectedStrokeColor"];
    
    NSNumber *width = info[@"width"];
    NSNumber *cs = info[@"canSelect"];
    
    NSNumber *show_arrows = info[@"show_direction"];
    if (show_arrows && show_arrows.boolValue == true) {
       
    }
    
    if (cs && [cs respondsToSelector:@selector(boolValue)]) { canSelect = cs.boolValue; }
    if (!width) { width = @6; }
    if (!st) { st = cl; }
    if ([width respondsToSelector:@selector(floatValue)] == false) { width = @6;}
    if (selectColor) { self.selectedColor = selectColor; }
    if (selectedStrokeColor) { self.selectedStrokeColor = selectSColor; }
    
    
    NSString *_id = info[@"id"];
    NSNumber *duration = info[@"duration"];
    
    if (_id) {
        routeId = [_id description];
    }
    
    if (duration && [duration respondsToSelector:@selector(doubleValue)]) {
        self.duration = duration.doubleValue;
    }

    if (cl) { self.color = cl; } else { self.color = [UIColor blueColor]; }
    if (st) { self.strokeColor = st; } else { self.strokeColor = [UIColor blueColor]; }
    
    if (route_points) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:route_points];
        self.points = array;
        
    }
    
    NSInteger numberOfSteps = route_points.count;
    CLLocationCoordinate2D coordinates[numberOfSteps];
    
    for (NSInteger index = 0; index < numberOfSteps; index++) {
        
        NSArray *coords = [route_points objectAtIndex:index];
        double lon = [[coords firstObject] doubleValue];
        double lat = [[coords lastObject] doubleValue];
        
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lon);
        
        coordinates[index] = coordinate;
        
        
    }
    
    CLLocationCoordinate2D media = [Routing middlePointForRoute:info];
    
    MapMarker *routePin = [[MapMarker alloc] init];
    routePin.coordinate = media;
    routePin.marker_type = MarkerTypeRouteCenterPin;
    routePin.canShowCallout = true;
    routePin.selectable = true;
    routePin.title = [[SMapHelper localizedTime:duration.intValue] string];
    
    self.marker = routePin;
    
    
    polyline = [MGLPolylineFeature polylineWithCoordinates:coordinates count:numberOfSteps];
    polyline.identifier = [NSString stringWithFormat:@"rid_%@",routeId];
    
    source = [[MGLShapeSource alloc] initWithIdentifier:[NSString stringWithFormat:@"rid_%@",routeId] features:@[] options:nil];
    source.shape = polyline;
    
    
   
    
    strokeLayer = [[MGLLineStyleLayer alloc] initWithIdentifier:[NSString stringWithFormat:@"rid_stroke_%@",routeId] source:source];
    strokeLayer.lineColor = [NSExpression expressionForConstantValue:self.strokeColor];
    strokeLayer.lineJoin = [NSExpression expressionForConstantValue:@"round"];
    strokeLayer.lineCap = layer.lineJoin = [NSExpression expressionForConstantValue:@"round"];
    strokeLayer.lineWidth = [NSExpression expressionWithFormat:@"mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
                              @{@14: width, @18: @21}];
    
    
    
    layer = [[MGLLineStyleLayer alloc] initWithIdentifier:[NSString stringWithFormat:@"rid_%@",routeId] source:source];
    layer.lineJoin = [NSExpression expressionForConstantValue:@"round"];
    layer.lineCap = layer.lineJoin = [NSExpression expressionForConstantValue:@"round"];
    layer.lineColor = [NSExpression expressionForConstantValue:self.color];
    
    
    //The line width should gradually increase based on the zoom level.
    layer.lineWidth = [NSExpression expressionWithFormat:@"mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
                       @{@14: [NSNumber numberWithFloat: (width.floatValue - 1.0)], @18: @20}];
    
    


    return  self;

}

- (void)addArrow:(MapMarker *)m {
    
}

- (void)setColor:(UIColor *)co {
    
    if (co == nil) return;
    
    _color = co;
    
    layer.lineColor = [NSExpression expressionForConstantValue:self.color];
    
}

- (void)setStrokeColor:(UIColor *)stroke {
    if (stroke == nil) return;
    _strokeColor = stroke;
    strokeLayer.lineColor = [NSExpression expressionForConstantValue:stroke];
}

- (void)setSelected:(BOOL)select {
    _selected = select;
    if ( select ) {
        if (self.selectedStrokeColor) strokeLayer.lineColor = [NSExpression expressionForConstantValue:self.selectedStrokeColor];
        if (self.selectedColor) layer.lineColor = [NSExpression expressionForConstantValue:self.selectedColor];
        return;
    }
    
    if (select == NO) {
        if (self.color) layer.lineColor = [NSExpression expressionForConstantValue:self.color];
        if (self.strokeColor) strokeLayer.lineColor = [NSExpression expressionForConstantValue:self.strokeColor];
        
        
    }
    
    
    
}

- (NSURL *)getArrowsUrl {
    if (!self.points) return nil;
    NSURL *url;
    NSString *fileUrl = [NSTemporaryDirectory() stringByAppendingPathComponent:@"r_direction.json"];
    
    url = [NSURL fileURLWithPath:fileUrl];
    
    NSMutableDictionary *geojson = [NSMutableDictionary dictionary];
    NSMutableArray* array = [[NSMutableArray alloc] init];
    
    [geojson setObject:@"FeatureCollection" forKey:@"type"];
    
    @synchronized (self.points) {
        NSInteger idx = 0;
        for (NSArray *p in self.points) {
            if (idx == 0) { idx++; continue; }
            
            NSArray *prev_coords = [self.points objectAtIndex:idx -1];
          
            double lon1 = [[prev_coords firstObject] doubleValue];
            double lat1 = [[prev_coords lastObject] doubleValue];
            
            double lon2 = [[p firstObject] doubleValue];
            double lat2 = [[p lastObject] doubleValue];
            
            CLLocationCoordinate2D loc1 = CLLocationCoordinate2DMake(lat1, lon1);
            CLLocationCoordinate2D loc2 = CLLocationCoordinate2DMake(lat2, lon2);
            
            NSMutableDictionary *ob = [NSMutableDictionary dictionary];
            [ob setObject:@"Feature" forKey:@"type"];
            
            NSMutableDictionary *geometry = [NSMutableDictionary dictionary];
            [geometry setObject:@"Point" forKey:@"type"];
            
            [geometry setObject:p forKey:@"coordinates"];
            
            
            NSMutableDictionary *properties = [NSMutableDictionary dictionary];
            float direction = [SMapHelper calculateUserDirection:loc1 second:loc2];
            
            
            [properties setObject:@YES forKey:@"visible"];
            [properties setObject:[NSNumber numberWithDouble:1.0] forKey:@"aplha"];
            [properties setObject:[NSNumber numberWithFloat:direction]  forKey:@"rotate"];
            [properties setObject:[NSNumber numberWithFloat:direction] forKey:@"icon-rotate"];
            
            [ob setObject:properties forKey:@"properties"];
            [ob setObject:geometry forKey:@"geometry"];
            
            
            [array addObject:ob];
            idx++;
            if (idx >= ([self.points count] - 1)) { break; }
        }
    }
    
    [geojson setObject:array forKey:@"features"];
    NSError *err;
    NSData *jsdata = [NSJSONSerialization dataWithJSONObject:geojson options:NSJSONWritingPrettyPrinted error:&err];
    BOOL res =  [jsdata writeToURL:url atomically:YES];;
    NSLog(@"write to file %i",res);
    
    return url;
}

- (NSArray *)getPoints {
    NSArray *result = [NSArray arrayWithArray:self.points];
    return result;
}

- (NSString *)formatDuration:(double)time {
    
    
    return nil;
}

- (double)getDuration {
    return self.duration;
}

// used in navigation mode
- (void)trimRoute:(NSValue *)coords {
 
    CLLocationCoordinate2D loc = [coords MKCoordinateValue];
    NSArray *route_points = self.points;
    if (!route_points) return;
    
    // find most nearest
    
    NSInteger numberOfSteps = route_points.count;
    CLLocationCoordinate2D coordinates[numberOfSteps];
    double minDist = MAXFLOAT;
    NSInteger minIdx = -1;
    
    for (NSInteger index = 0; index < numberOfSteps; index++) {
        
        NSArray *coords = [route_points objectAtIndex:index];
        double lon = [[coords firstObject] doubleValue];
        double lat = [[coords lastObject] doubleValue];
        
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lon);
       
        double dist = [SMapHelper distanceBetween:loc point:coordinate];
        if (dist < minDist) {
            minDist = dist;
            minIdx = index;
        }
        
    }
    
    if (minDist > 200) return;
    
    NSInteger numberRemain = 0;
    
    if (minIdx > 1) {
        minIdx --;
     
        
        for (NSInteger index = minIdx; index < numberOfSteps; index++) {
            
            NSArray *coords = [route_points objectAtIndex:index];
            double lon = [[coords firstObject] doubleValue];
            double lat = [[coords lastObject] doubleValue];
            
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lon);
            coordinates[numberRemain] = coordinate;
            numberRemain = numberRemain + 1;
            
        }
        numberRemain = numberRemain - 1;
        if (numberRemain < 2) return;
        
        MGLPolylineFeature *poly = [MGLPolylineFeature polylineWithCoordinates:coordinates count:numberRemain];
        [poly setCoordinates:coordinates count:numberRemain];
         
        source.shape = poly;
        
        
    }
    
    
}

@end
