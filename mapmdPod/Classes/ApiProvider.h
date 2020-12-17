//
//  ApiProvider.h
//  mapmd
//
//  Created by user on 4/13/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *MSearchOperationFinish = @"MSearchOperationFinish";
static NSString *MGeocodeDidFinish = @"MGeocodeDidFinish";
#define apiDomain @"https://map.md/api/"

@interface ApiProvider : NSObject

+ (instancetype)shared;

- (void)search:(NSString *)query;

- (void)getRouteById:(NSString *)route_id completion:( void(^)(NSDictionary *))result;

/**
 Get city  by id
 @param city_id - is id given by search.
 Result will given in background thread
 */

- (void)getCity:(NSString*)city_id completion:( void(^)(NSDictionary *))result;

/**
 Get company (objects) by id
 @param params
 {
 company_id - is id given by search.
 skip - number to skip
 take - number to skip
 lat , lon - user coordinate to receive most nearest
 }
 
 Result will given in background thread
 */

- (void)getCompanyBranches:(NSDictionary*)params completion:( void(^)(NSDictionary *))result;


/**
 Get company (object) by id
 @param company_id - is id given by search.
 Result will given in background thread
 */

- (void)getCompany:(NSString*)company_id completion:( void(^)(NSDictionary *))result;


/**
 Get company (object) by id
 @param object_id - is id given by search.
 Result will given in background thread
 */
- (void)getObject:(NSString*)object_id completion:( void(^)(NSDictionary *))result;


/**
 Get street by id and number (optional)
 @param street_id - is id given by search.
 @param nr - is number of building (optional)
 */
- (void)getStreet:(NSString *)street_id number:(NSString *)nr completion:( void(^)(NSDictionary *))result;
/**
Geocoding place
Return nearest city, street, building and company by geo_point
@param location - is NSValue from CLLocationCoordinate2D
 
on result You will receive NSNotification named "MGeocodeDidFinish"
 */
- (void)geocode:(NSValue *)location;

/**
Get all categories
 */
- (void)getCategories:( void(^)(NSDictionary *))result;
- (void)getObjects:(NSString *)category_id  response:( void(^)(NSDictionary *))result;



/**
 You can get session to make your requests to API
 return: URLSession */

- (NSURLSession *)getSession;

@end

NS_ASSUME_NONNULL_END
