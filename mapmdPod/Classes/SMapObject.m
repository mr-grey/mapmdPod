//
//  SMapClusters.m
//  mapmd
//
//  Created by user on 10/10/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import "SMapObject.h"

@interface SMapObject ()

@property (nonatomic, retain) NSMutableArray *layersArray;
@end


@implementation SMapObject
@synthesize url;

- (instancetype)initWithUrl:(NSURL *)geojson {
    
    self = [super init];
    url = geojson;
    _layersArray = [[NSMutableArray alloc] init];
    
    return self;
}


- (void)addLayer:(MGLStyleLayer *)layer {
    [_layersArray addObject:layer];
}

- (NSArray *)layers {
    return _layersArray;
}

@end
