//
//  MSearchOperation.m
//  mapmd
//
//  Created by user on 4/18/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import "MSearchOperation.h"
#import "ApiProvider.h"

@implementation MSearchOperation

- (instancetype)initWithQuery:(NSString *)q {
    
    self = [super init];
    
    q = [q stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    NSString *urlString = [NSString stringWithFormat:@"%@companies/webmap/group/search?q=%@", apiDomain, q];
    _url = [NSURL URLWithString:urlString];
    _data = [NSMutableData data];
    return self;
}

- (void)start {
    NSLog(@"Search Operation %s", __func__);
    NSURLSession *session = [[ApiProvider shared] getSession];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url];
    NSString *apikey = [[NSUserDefaults standardUserDefaults] objectForKey:@"apikey"];
    
    if (apikey) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", apikey, @""];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:(NSDataBase64EncodingEndLineWithLineFeed)]];
        
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
        [request setValue:@"iOS" forHTTPHeaderField:@"platform"];

        NSLog(@"use api key: %@", apikey);

    }
    
    task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self->_data appendData:data];
        }
        [self performSelectorOnMainThread:@selector(doFinish) withObject:nil waitUntilDone:false];
    }];
    
    [task resume];
}

- (void)main {
    NSLog(@"Search Operation %s", __func__);
   
}


- (void)cancel {
   NSLog(@"Search Operation %s", __func__);
   if (task) [task cancel];
}

- (void)doFinish {
    NSLog(@"Search Operation %s", __func__);
    NSDictionary *di = [NSJSONSerialization JSONObjectWithData:_data options:(NSJSONReadingAllowFragments) error:nil];
    [self finish:di];
}

- (void)finish: (NSDictionary *)di {
    //MSearchOperationFinish
    NSLog(@"Search Operation %s", __func__);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MSearchOperationFinish" object:di];
}

@end
