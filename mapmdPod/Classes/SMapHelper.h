//
//  SMapHelper.h
//  map_new_engine
//
//  Created by grey on 3/13/17.
//  Copyright © 2017 grey. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;

@import MapKit;

static UIImage *sharedGroupimageSmall;
static UIImage *sharedGroupimageMedium;
static UIImage *sharedGroupimageLarge;

typedef enum MapLogoPosition {
    MapLogoPositionTopLeft,
    MapLogoPositionTopRight,
    MapLogoPositionBottomLeft,
    MapLogoPositionBottomRight
} MapLogoPosition;


@interface SMapHelper : NSObject

+ (float)randomFloatBetween:(float)smallNumber and:(float)bigNumber;
+ (float)calculateUserDirection:(CLLocationCoordinate2D)loc1 second:(CLLocationCoordinate2D)loc2;

/* return angle in degrees */
+ (double)directionBetweenPoints:(MKMapPoint )sourcePoint dest:(MKMapPoint)destinationPoint;
+ (double)distanceBetween:(CLLocationCoordinate2D)loc1 point:(CLLocationCoordinate2D)loc2;
+ (double)DegreeToRadian:(double)angle;

+ (double)DegreesToRadians:(double) degrees;
/**
 This function used for put correct annotation for 2 route
 Returns a Dictonary with 2 keys - 1 and 2, this keys is two points of one and second route
 It check max distance between point of two routes
 */
+ (NSDictionary*)maxDistanceFromTwooPointsOfRoutes:(NSArray*)points1 second:(NSArray *)points2;

+ (double)RadianToDegree:(double)angle;

/**
 Convert speed in m/s to Localized Attributed string
 @param sp Type used to represent the speed in meters per second.
 
 */
+ (NSAttributedString*)localizedSpeed:(double)sp;

/**
 Convert time to Localized Attributed string
 @param secs Type used to represent the time in seconds.

 Return format  "hour:min:sec"
 Based on current "AppleLanguages"
 */
+ (NSAttributedString*)localizedTime:(int)secs;


/*
 Return default location name (localized)
 */
+ (NSString *) localizedLocation;



/**
 Return an image like a cluster with count in middle
 */
+ (UIImage*)imageForGroup:(int)count;

/**
 Return an image like a cluster , from shared static images
 no counter text
 */
+ (UIImage*)imageForGroup_v2:(int)count;

@end
