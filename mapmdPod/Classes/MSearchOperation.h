//
//  MSearchOperation.h
//  mapmd
//
//  Created by user on 4/18/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSearchOperation : NSOperation
{
    NSURL * _url;
    NSInteger _statusCode;
    NSMutableData * _data;
    NSError * _error;
    NSString *_searchString;
    NSURLSessionDataTask *task;
    BOOL _isExecuting;
    BOOL _isFinished;
}

- (instancetype)initWithQuery:(NSString *)q;

@end

NS_ASSUME_NONNULL_END
