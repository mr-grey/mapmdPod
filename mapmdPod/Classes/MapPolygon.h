//
//  MapPolygon.h
//  map_new_engine
//
//  Created by grey on 1/25/17.
//  Copyright © 2017 grey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mapbox/MapBox.h>
#import <Mapbox/MGLOverlay.h>

@class MapMarker;

@interface MapPolygon : MGLPolygon

@property (nonatomic, readonly) MapMarker *centerPin;
@property (nonatomic, retain) NSString *ObjectId;
@property (nonatomic, copy) UIColor *strokeColor;
@property (nonatomic, copy) UIColor *fillColor;
@property (readwrite) BOOL canShowCallout;
@property (readwrite) BOOL selectable;

// setup an selectable center pin with callout
- (void)setup;

@end
