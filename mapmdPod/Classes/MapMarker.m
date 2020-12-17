//
//  MapMarker.m
//  map_new_engine
//
//  Created by grey on 7/6/16.
//  Copyright © 2016 grey. All rights reserved.
//

#import "MapMarker.h"
#import "RouteCalloutView.h"

@implementation MapMarker
@synthesize objectid;
@synthesize category_id;
@synthesize annotation;
@synthesize dict;
@synthesize image;
@synthesize marker_type;
@synthesize selectable;
@synthesize isSelected;
@synthesize bearing;
@synthesize selectedImage;
@synthesize canShowCallout;
@synthesize calloutView;
@synthesize imageOffset;
@synthesize count;

- (instancetype)init {
    
    self = [super init];
    
    selectable = NO;
    
    return self;
}


- (void)dealloc {
    
    annotation = nil;
    category_id = 0;
    objectid = nil;
    image = nil;
    
  //  NSLog(@"dealloc MapMarker");
    
}

- (NSString *)debugDescription {
    
    NSString *string = [NSString stringWithFormat:@"%@ %@ id:%@ ", NSStringFromClass(self.class),_title, objectid];
    NSString *t = @"";
    if (marker_type == MarkerTypePin) t = @"MarkerTypePin";
    if (marker_type == MarkerTypeDefault) t = @"MarkerTypeDefault";
    if (marker_type == MarkerTypeTest) t = @"MarkerTypeTest";
    if (marker_type == MarkerTypeTemporary) t = @"MarkerTypeTemporary";
    if (marker_type == MarkerTypeRouteStartPin) t = @"MarkerTypeRouteStartPin";
    if (marker_type == MarkerTypeRouteCenterPin) t = @"MarkerTypeRouteCenterPin";
    
    string = [string stringByAppendingString:t];
    
    return string;
}

- (void)setSelected:(BOOL) sel {
    isSelected = sel;
}

- (NSString *)description {
    
    NSString *string = [NSString stringWithFormat:@"%@ %@ id:%@ ", NSStringFromClass(self.class),_title, objectid];
    NSString *t = @"";
    if (marker_type == MarkerTypePin) t = @"MarkerTypePin";
    if (marker_type == MarkerTypeDefault) t = @"MarkerTypeDefault";
    if (marker_type == MarkerTypeTest) t = @"MarkerTypeTest";
    if (marker_type == MarkerTypeTemporary) t = @"MarkerTypeTemporary";
    if (marker_type == MarkerTypeRouteStartPin) t = @"MarkerTypeRouteStartPin";
    if (marker_type == MarkerTypeRouteCenterPin) t = @"MarkerTypeRouteCenterPin";
    
    string = [string stringByAppendingString:t];
    
    return string;
}



@end


