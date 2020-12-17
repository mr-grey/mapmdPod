//
//  MapPolygon.m
//  map_new_engine
//
//  Created by grey on 1/25/17.
//  Copyright © 2017 grey. All rights reserved.
//

#import "MapPolygon.h"
#import "MapMarker.h"

@implementation MapPolygon
@synthesize strokeColor;
@synthesize canShowCallout;
@synthesize selectable;
@synthesize centerPin;

@synthesize coordinate;

@synthesize overlayBounds;

- (BOOL)intersectsOverlayBounds:(MGLCoordinateBounds)overlayBounds {
    return false;
}

- (void)setup {
   
    centerPin = [[MapMarker alloc] init];
    centerPin.image = [UIImage new];
    centerPin.selectable = true;
    centerPin.canShowCallout = YES;
    centerPin.objectid = [self ObjectId];
    centerPin.marker_type = MarkerTypeDefault;
    centerPin.title = @"polygon";
    
    CLLocationCoordinate2D *coords = [self coordinates];
    NSInteger count = [self pointCount];
    double mlat = 0, mlon = 0;
    
    for (int i = 0; i < count; i++ ) {
        CLLocationCoordinate2D loc = coords[i];
        mlat = mlat + loc.latitude;
        mlon = mlon + loc.longitude;
    }
    
    mlat = mlat / count;
    mlon = mlon / count;
    
    centerPin.coordinate = CLLocationCoordinate2DMake(mlat, mlon);
}

- (BOOL)isEnabled {
    
    if (selectable) return YES;
    return false;
}

@end
