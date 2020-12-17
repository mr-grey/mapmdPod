//
//  Routing.m
//  map_new_engine
//
//  Created by grey on 2/8/17.
//  Copyright © 2017 grey. All rights reserved.
//

#import "Routing.h"
#import "ApiProvider.h"

@import MapKit;


@implementation Routing
@synthesize startPoint,endPoint;
@synthesize routesDict;


- (BOOL)isLoading {
    return isLoading;
}

- (instancetype)initWithLocations:(CLLocationCoordinate2D)start second:(CLLocationCoordinate2D)end {
    
    self = [super init];
    
    startPoint = start;
    endPoint = end;
    
    return self;
}

- (void)reset {
    startPoint = CLLocationCoordinate2DMake(0, 0);
    endPoint = startPoint;
    
}

- (void)requestToGoogle {
    //https://maps.googleapis.com/maps/api/directions/json?origin=46.4451653,27.9701449&destination=47.035324,28.806383&key=AIzaSyD4KfNStGTDouTfYyylpZdq2d2fqr1tWVc&alternatives=true
  /* do nothing !
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/directions/json?"];
    NSString *coordsString = [NSString stringWithFormat:@"origin=%f,%f&destination=%f,%f",startPoint.latitude,startPoint.longitude,endPoint.latitude,endPoint.longitude];
    urlString = [urlString stringByAppendingString:coordsString];
    urlString = [urlString stringByAppendingString:@"&alternatives=true"];
    urlString = [urlString stringByAppendingString:@"&steps=true"];

    NSURL *u = [NSURL URLWithString:urlString];
    
    NSLog(@"load %@",u.description);
    
    
    NSURLRequest *req = [NSURLRequest requestWithURL:u];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        
        if (!data) {
            return ;
        }
        googleDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:0];
        
    }];
*/
    
}

- (void)handleDirectionsError:(NSError*)err {
    NSLog(@"%@",err);
          
}

- (void)makeRequest:(void ( ^)( NSDictionary * ))reply {
    
    // root https://point.md/ru/map/osrm/
    //GET /route/v1/{profile}/{coordinates}?alternatives={true|false}&steps={true|false}&geometries={polyline|polyline6|geojson}&overview={full|simplified|false}&annotations={true|false}
    // {longitude},{latitude};{longitude},{latitude}
    // http://router.project-osrm.org/route/v1/driving/13.388860,52.517037;13.397634,52.529407;13.428555,52.523219?overview=false'
    if (isLoading) {
        NSLog(@"%s return already loading ..", __PRETTY_FUNCTION__);
        return;
    }
    
    if (startPoint.latitude == 0 || endPoint.latitude == 0) return;
    
    isLoading = YES;
    
    
    NSString *urlString = [NSString stringWithFormat:@"https://map.md/api/routing/route/v1/driving/"];
    NSString *coordsString = [NSString stringWithFormat:@"%f,%f;%f,%f",startPoint.longitude,startPoint.latitude,endPoint.longitude,endPoint.latitude];
    
    urlString = [urlString stringByAppendingString:coordsString];
    urlString = [urlString stringByAppendingString:@"?alternatives=true"];
    urlString = [urlString stringByAppendingString:@"&steps=true"];
    urlString = [urlString stringByAppendingString:@"&geometries=geojson"];
    urlString = [urlString stringByAppendingString:@"&overview=simplified"];
    
    NSURL *u = [NSURL URLWithString:urlString];
    
    NSLog(@"load %@",u.description);

    NSURLSession *session = [[ApiProvider shared] getSession];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:u];
    NSString *apikey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    
    if (apikey) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", apikey, @""];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:(NSDataBase64EncodingEndLineWithLineFeed)]];
        
        [req setValue:authValue forHTTPHeaderField:@"Authorization"];
        [req setValue:@"iOS" forHTTPHeaderField:@"platform"];
    }
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        self->isLoading = NO;
        
        if (!data) {
            if(reply) reply ( @{ @"error:":@"nodata"} );
            return;
        }
        
        @try {
            self.routesDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:0];
        } @catch (NSException *exception) {
            self.routesDict = @{} ;
        } @finally {
            
        }
        
        if (reply) reply(self.routesDict);
        
    }];
    [task resume];
    

}



- (NSArray *)routeList {
    
    NSMutableArray *variants = [NSMutableArray array];
    
    if (routesDict) {
        
        NSArray *routes = routesDict[@"routes"];
        [variants addObjectsFromArray:routes];
    } else {
        [self makeRequest:nil];
    }
 
    if (googleDict) {
       
        NSArray *routes = googleDict[@"routes"];
        [variants addObjectsFromArray:routes];
    }
    
    return variants;
}


#pragma mark - Other

+ (NSArray*)decodedPolylineString:(NSString *)encodedString {
   
    NSMutableArray *array = [[NSMutableArray alloc] init];
    const char *bytes = [encodedString UTF8String];
    NSUInteger length = [encodedString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSUInteger idx = 0;
    
    NSUInteger count = length / 4;
    CLLocationCoordinate2D *coords = calloc(count, sizeof(CLLocationCoordinate2D));
    NSUInteger coordIdx = 0;

    float latitude = 0;
    float longitude = 0;
    while (idx < length) {
        char byte = 0;
        int res = 0;
        char shift = 0;
        
        do {
            byte = bytes[idx++] - 63;
            res |= (byte & 0x1F) << shift;
            shift += 5;
        } while (byte >= 0x20);
        
        float deltaLat = ((res & 1) ? ~(res >> 1) : (res >> 1));
        latitude += deltaLat;
        
        shift = 0;
        res = 0;
        
        do {
            byte = bytes[idx++] - 0x3F;
            res |= (byte & 0x1F) << shift;
            shift += 5;
        } while (byte >= 0x20);
        
        float deltaLon = ((res & 1) ? ~(res >> 1) : (res >> 1));
        longitude += deltaLon;
        
        float finalLat = latitude * 1E-5;
        float finalLon = longitude * 1E-5;
        
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(finalLat, finalLon);
        coords[coordIdx++] = coord;
        
        NSArray *point = @[ [NSNumber numberWithDouble:finalLon] ,  [NSNumber numberWithDouble:finalLat]  ];
        [array addObject:point];
        
        if (coordIdx == count) {
            NSUInteger newCount = count + 10;
            coords = realloc(coords, newCount * sizeof(CLLocationCoordinate2D));
            count = newCount;
        }
    }
    
    
    return array;
}

+ (MKPolyline *)polylineWithEncodedString:(NSString *)encodedString {
  
    const char *bytes = [encodedString UTF8String];
    NSUInteger length = [encodedString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSUInteger idx = 0;
    
    NSUInteger count = length / 4;
    CLLocationCoordinate2D *coords = calloc(count, sizeof(CLLocationCoordinate2D));
    NSUInteger coordIdx = 0;
    
    float latitude = 0;
    float longitude = 0;
    while (idx < length) {
        char byte = 0;
        int res = 0;
        char shift = 0;
        
        do {
            byte = bytes[idx++] - 63;
            res |= (byte & 0x1F) << shift;
            shift += 5;
        } while (byte >= 0x20);
        
        float deltaLat = ((res & 1) ? ~(res >> 1) : (res >> 1));
        latitude += deltaLat;
        
        shift = 0;
        res = 0;
        
        do {
            byte = bytes[idx++] - 0x3F;
            res |= (byte & 0x1F) << shift;
            shift += 5;
        } while (byte >= 0x20);
        
        float deltaLon = ((res & 1) ? ~(res >> 1) : (res >> 1));
        longitude += deltaLon;
        
        float finalLat = latitude * 1E-5;
        float finalLon = longitude * 1E-5;
        
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(finalLat, finalLon);
        coords[coordIdx++] = coord;
        
        if (coordIdx == count) {
            NSUInteger newCount = count + 10;
            coords = realloc(coords, newCount * sizeof(CLLocationCoordinate2D));
            count = newCount;
        }
    }
    
    MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coords count:coordIdx];
    free(coords);
    
    return polyline;
}



+ (NSString *)encodeStringWithCoordinates:(NSArray *)coordinates
{
    NSMutableString *encodedString = [NSMutableString string];
    int val = 0;
    int value = 0;
    CLLocationCoordinate2D prevCoordinate = CLLocationCoordinate2DMake(0, 0);
    
    for (NSValue *coordinateValue in coordinates) {
        CLLocationCoordinate2D coordinate = [coordinateValue MKCoordinateValue];
        
        // Encode latitude
        val = round((coordinate.latitude - prevCoordinate.latitude) * 1e5);
        val = (val < 0) ? ~(val<<1) : (val <<1);
        while (val >= 0x20) {
            int value = (0x20|(val & 31)) + 63;
            [encodedString appendFormat:@"%c", value];
            val >>= 5;
        }
        [encodedString appendFormat:@"%c", val + 63];
        
        // Encode longitude
        val = round((coordinate.longitude - prevCoordinate.longitude) * 1e5);
        val = (val < 0) ? ~(val<<1) : (val <<1);
        while (val >= 0x20) {
            value = (0x20|(val & 31)) + 63;
            [encodedString appendFormat:@"%c", value];
            val >>= 5;
        }
        [encodedString appendFormat:@"%c", val + 63];
        
        prevCoordinate = coordinate;
    }
    
    return encodedString;
}


+ (CLLocationCoordinate2D)centerPointForRoute:(NSDictionary*)routeDict {
  
    NSArray *allpoints = [Routing parseLegs:routeDict];
    double lon = 0, lat = 0, latT = 0, lonT = 0;
    
    for (NSArray *coords in allpoints) {
         lonT += [[coords firstObject] doubleValue];
         latT += [[coords lastObject] doubleValue];
    }
    
    lon = lonT / allpoints.count;
    lat = latT / allpoints.count;
    
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lon);
    
    return coordinate;
}

// use it for annotation for route
+ (CLLocationCoordinate2D)middlePointForRoute:(NSDictionary*)routeDict {
    
    NSArray *allpoints = [Routing parseLegs:routeDict];
    if (allpoints == nil || allpoints.count == 0) {
        allpoints = routeDict[@"points"];
        if (!allpoints || allpoints.count == 0)
            return CLLocationCoordinate2DMake(49, 29);
    }
    NSArray *coords = [allpoints objectAtIndex:allpoints.count/2];
    double lon = [[coords firstObject] doubleValue];
    double lat = [[coords lastObject] doubleValue];
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lon);

    
    return coordinate;
}

+ (NSArray*)parseLegs:(NSDictionary*)routeDict {
   
    NSMutableArray *array = [NSMutableArray array];
    NSDictionary *legs = [routeDict[@"legs"] firstObject];
    NSArray *steps = legs[@"steps"];
    
    for (NSDictionary *step in steps) {
        
        
        
        NSDictionary *geometry = step[@"geometry"];
        
        if (!geometry) {
            // google ?
            
            NSString *polyline_points = [step[@"polyline"] objectForKey:@"points"];
            NSArray *points = [Routing decodedPolylineString:polyline_points];
            if (points) {
                [array addObjectsFromArray:points];
                continue;
            }
            
            NSDictionary *startLoc = step[@"start_location"];
          
            NSArray  *a = @[ startLoc[@"lng"], startLoc[@"lat"] ];
            [array addObject:a];
            
            NSDictionary *endLoc = step[@"start_location"];
           
            NSArray  *b = @[ endLoc[@"lng"], endLoc[@"lat"] ];
            [array addObject:b];
            continue;
        }
        
        NSArray *coords = geometry[@"coordinates"];
        [array addObjectsFromArray:coords];
        
    }
    
    
    return array;
}

@end
