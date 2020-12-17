//
//  ApiProvider.m
//  mapmd
//
//  Created by user on 4/13/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import "ApiProvider.h"
#import "MSearchOperation.h"

@import MapKit;

static ApiProvider *provider;

@interface ApiProvider()
@property (nonatomic, retain) NSURLSession *session;
@property (nonatomic, retain) NSOperationQueue *searchQueque;
@end


@implementation ApiProvider

+ (instancetype)shared {
    @synchronized (provider) {
        if (provider == nil) {
            provider = [[ApiProvider alloc] init];
        }
    }
    
    return provider;
}

- (instancetype)init {
    
    self = [super init];
    
    NSURLSessionConfiguration *config =  [NSURLSessionConfiguration defaultSessionConfiguration];
    NSString *apikey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    
    if (apikey) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", apikey, @""];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:(NSDataBase64EncodingEndLineWithLineFeed)]];
        
        [config setHTTPAdditionalHeaders:@{ @"Authorization": authValue , @"ApplicationId": [NSBundle mainBundle].bundleIdentifier , @"platform": @"iOS" } ];
    }

    
    NSString *key = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    if (key) {
        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"apikey"];
    }
    
    self.session = [NSURLSession sessionWithConfiguration:config delegate:(id)self delegateQueue:nil];

    self.searchQueque = [[NSOperationQueue alloc] init];
    
    return self;
}


- (NSURLSession *)getSession {
    return self.session;
}

- (void)geocode:(NSValue *)location {
    CLLocationCoordinate2D loc = [location MKCoordinateValue];
    NSURL *uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@companies/webmap/near?lat=%f&lon=%f",apiDomain,loc.latitude, loc.longitude]];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:uri];
    NSString *apikey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    
    if (apikey) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", apikey, @""];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:(NSDataBase64EncodingEndLineWithLineFeed)]];
        
        [theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        [theRequest setValue:@"iOS" forHTTPHeaderField:@"platform"];
    }
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:MGeocodeDidFinish object:@{ @"error": error} ];
            return;
        }
        if (data) {
            NSDictionary *re = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:MGeocodeDidFinish object: re ];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:MGeocodeDidFinish object:@{ @"error": @"noDataError"} ];
        }
    }];
    
    [task resume];
}

- (void)getObjects:(NSString *)category_id  response:( void(^)(NSDictionary *))result {
    NSURL *uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@companies/webmap/get_branches?parent_id=%@",apiDomain,category_id]];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:uri];
    NSString *apikey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    
    if (apikey) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", apikey, @""];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:(NSDataBase64EncodingEndLineWithLineFeed)]];
        
        [theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        [theRequest setValue:@"iOS" forHTTPHeaderField:@"platform"];
    }
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            result ( @{ @"Error": error} );
            return;
        }
        if (data) {
            NSDictionary *re = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:nil];
            result (re);
        } else {
            result ( @{ @"Error": @"no data error"} );
        }
    }];
    
    [task resume];
    
}


- (void)getCategories:( void(^)(NSDictionary *))result {
    NSURL *uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@companies/webmap/categories",apiDomain]];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:uri];
    NSString *apikey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    
    if (apikey) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", apikey, @""];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:(NSDataBase64EncodingEndLineWithLineFeed)]];
        
        [theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        [theRequest setValue:@"iOS" forHTTPHeaderField:@"platform"];
    }
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            result ( @{ @"Error": error} );
            return;
        }
        if (data) {
            NSDictionary *re = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:nil];
            result (re);
        } else {
            result ( @{ @"Error": @"no data error"} );
        }
    }];
    
    [task resume];
}

- (void)search:(NSString *)query {
    [self.searchQueque cancelAllOperations];
    
    MSearchOperation *operation = [[MSearchOperation alloc] initWithQuery:query];
    [self.searchQueque addOperation:operation];
    
}

- (void)getStreet:(NSString *)street_id number:(NSString *)nr completion:( void(^)(NSDictionary *))result {
    
    NSString *urlString = [NSString stringWithFormat:@"%@companies/webmap/get_street?id=%@",apiDomain,street_id];
    
    if (nr) {
        urlString = [urlString stringByAppendingFormat:@"&number=%@" ,nr];
    }
    
    NSURL *uri = [NSURL URLWithString:urlString];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:uri];
    NSString *apikey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    NSString *bundleid = [NSBundle mainBundle].bundleIdentifier;
    
    if (apikey) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", apikey, @""];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:(NSDataBase64EncodingEndLineWithLineFeed)]];
        
        [theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        [theRequest setValue:@"iOS" forHTTPHeaderField:@"platform"];
        [theRequest setValue:bundleid forHTTPHeaderField:@"ApplicationId"];
        
    }
    
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            result ( @{ @"Error": error} );
            return;
        }
        if (data) {
            NSDictionary *re = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:nil];
            result (re);
        } else {
            result ( @{ @"Error": @"no data error"} );
        }
    }];
    
    [task resume];
    
}

- (void)getObject:(NSString*)object_id completion:( void(^)(NSDictionary *))result {
    NSURL *uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@companies/webmap/get_object?id=%@",apiDomain,object_id]];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:uri];
    NSString *apikey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    NSString *bundleid = [NSBundle mainBundle].bundleIdentifier;
    
    if (apikey) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", apikey, @""];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:(NSDataBase64EncodingEndLineWithLineFeed)]];
        
        [theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        [theRequest setValue:@"iOS" forHTTPHeaderField:@"platform"];
        [theRequest setValue:bundleid forHTTPHeaderField:@"ApplicationId"];
    }
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            result ( @{ @"Error": error} );
            return;
        }
        if (data) {
            NSDictionary *re = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:nil];
            result (re);
        } else {
            result ( @{ @"Error": @"no data error"} );
        }
    }];
    
    [task resume];
}

- (void)getCity:(NSString*)city_id completion:( void(^)(NSDictionary *))result {
    NSURL *uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@companies/webmap/city?id=%@",apiDomain,city_id]];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:uri];
    NSString *apikey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    NSString *bundleid = [NSBundle mainBundle].bundleIdentifier;
    
    if (apikey) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", apikey, @""];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:(NSDataBase64EncodingEndLineWithLineFeed)]];
        
        [theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        [theRequest setValue:@"iOS" forHTTPHeaderField:@"platform"];
        [theRequest setValue:bundleid forHTTPHeaderField:@"ApplicationId"];
    }
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            result ( @{ @"Error": error} );
            return;
        }
        if (data) {
            NSDictionary *re = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:nil];
            result (re);
        } else {
            result ( @{ @"Error": @"no data error"} );
        }
    }];
    
    [task resume];
}


- (void)getCompany:(NSString*)company_id completion:( void(^)(NSDictionary *))result {
    NSURL *uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@companies/webmap/get_object?id=%@",apiDomain,company_id]];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:uri];
    NSString *apikey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    NSString *bundleid = [NSBundle mainBundle].bundleIdentifier;
    
    if (apikey) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", apikey, @""];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:(NSDataBase64EncodingEndLineWithLineFeed)]];
        
        [theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        [theRequest setValue:@"iOS" forHTTPHeaderField:@"platform"];
        [theRequest setValue:bundleid forHTTPHeaderField:@"ApplicationId"];
    }
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            result ( @{ @"Error": error} );
            return;
        }
        if (data) {
            NSDictionary *re = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:nil];
            result (re);
        } else {
            result ( @{ @"Error": @"no data error"} );
        }
    }];
    
    [task resume];
}

- (void)getCompanyBranches:(NSDictionary*)params completion:( void(^)(NSDictionary *))result {
    NSString *company_id = params[@"company_id"];
    NSNumber *skip = params[@"skip"];
    NSNumber *take = params[@"take"];
    NSNumber *lat = params[@"lat"];
    NSNumber *lon = params[@"lon"];
    //get_company_branches?id=115647&skip=10&take=20&lat=45.89&lon=28.66
    NSString *urlString = [NSString stringWithFormat:@"%@companies/webmap/get_company_branches?id=%@",apiDomain,company_id];
    if (skip) { urlString = [urlString stringByAppendingFormat:@"&skip=%@",skip]; }
    if (take) { urlString = [urlString stringByAppendingFormat:@"&take=%@",take]; }
    if (lat) { urlString = [urlString stringByAppendingFormat:@"&lat=%@",lat]; }
    if (lon) { urlString = [urlString stringByAppendingFormat:@"&lon=%@",lon]; }
    
    NSURL *uri = [NSURL URLWithString:urlString];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:uri];
    NSString *apikey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    NSString *bundleid = [NSBundle mainBundle].bundleIdentifier;
    
    if (apikey) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", apikey, @""];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:(NSDataBase64EncodingEndLineWithLineFeed)]];
        
        [theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        [theRequest setValue:@"iOS" forHTTPHeaderField:@"platform"];
        [theRequest setValue:bundleid forHTTPHeaderField:@"ApplicationId"];
    }
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            result ( @{ @"Error": error} );
            return;
        }
        if (data) {
            NSDictionary *re = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:nil];
            result (re);
        } else {
            result ( @{ @"Error": @"no data error"} );
        }
    }];
    
    [task resume];

}


//MARK: Publictransport
- (void)getRouteById:(NSString *)route_id completion:( void(^)(NSDictionary *))result {
    NSURL *uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@companies/webmap/route?rid=%@",apiDomain,route_id]];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:uri];
    NSString *apikey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    NSString *bundleid = [NSBundle mainBundle].bundleIdentifier;
    
    if (apikey) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", apikey, @""];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:(NSDataBase64EncodingEndLineWithLineFeed)]];
        
        [theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        [theRequest setValue:@"iOS" forHTTPHeaderField:@"platform"];
        [theRequest setValue:bundleid forHTTPHeaderField:@"ApplicationId"];
    }
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            result ( @{ @"Error": error} );
            return;
        }
        if (data) {
            NSDictionary *re = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:nil];
            result (re);
        } else {
            result ( @{ @"Error": @"no data error"} );
        }
    }];
    
    [task resume];
}

// MARK - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    NSLog(@"%s",__func__);
    NSString *apikey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    NSString *bundleid = [[NSBundle mainBundle] bundleIdentifier];
    NSURLCredential *credential = [NSURLCredential credentialWithUser:apikey
                                                             password:bundleid
                                                          persistence:NSURLCredentialPersistenceForSession];
    
    completionHandler (NSURLSessionAuthChallengeUseCredential, credential );
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSLog(@"%s",__func__);
    NSURLRequest *re = [dataTask currentRequest];
    NSLog(@"%@",re.allHTTPHeaderFields);
    completionHandler (NSURLSessionResponseAllow);
    NSLog(@"");
}
@end
