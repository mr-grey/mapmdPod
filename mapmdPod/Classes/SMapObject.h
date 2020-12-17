//
//  SMapClusters.h
//  mapmd
//
//  Created by user on 10/10/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mapbox/MapBox.h>

NS_ASSUME_NONNULL_BEGIN

// it may be route , cluster, and other

@interface SMapObject : NSObject

@property (nonatomic, retain) MGLSource *source;
@property (nonatomic, copy) NSURL *url;

- (instancetype)initWithUrl:(NSURL *)geojson;

- (void)addLayer:(MGLStyleLayer *)layer;
- (NSArray *)layers;

@end

NS_ASSUME_NONNULL_END
