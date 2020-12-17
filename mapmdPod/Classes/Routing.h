//
//  Routing.h
//  map_new_engine
//
//  Created by grey on 2/8/17.
//  Copyright © 2017 grey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


typedef NS_ENUM( NSUInteger, SRoutingMode)  {
    SRoutingUserPlaceToOther = 0,
    SRoutingOtherToOther = 1
 };



@interface Routing : NSObject
{
    
    NSDictionary *googleDict;
    BOOL isLoading;
}

@property (readwrite) CLLocationCoordinate2D startPoint, endPoint;
@property (nonatomic, retain) NSDictionary *routesDict;

- (void)reset;
- (BOOL)isLoading;

- (instancetype)initWithLocations:(CLLocationCoordinate2D)start second:(CLLocationCoordinate2D)end;

- (NSArray *)routeList;

- (void)makeRequest:(void ( ^)( NSDictionary * ))reply;


+ (NSArray*)decodedPolylineString:(NSString *)encodedString;

+ (NSArray*)parseLegs:(NSDictionary*)routeDict; // return array of points total route


+ (CLLocationCoordinate2D)centerPointForRoute:(NSDictionary*)routeDict;


/*  returns middle point 
    from array points route */
+ (CLLocationCoordinate2D)middlePointForRoute:(NSDictionary*)routeDict;

@end
