//
//  map.h
//  map
//
//  Created by user on 4/10/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for map.
FOUNDATION_EXPORT double mapVersionNumber;

//! Project version string for map.
FOUNDATION_EXPORT const unsigned char mapVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <map/PublicHeader.h>

#import "MapView.h"

#if DEBUG
#define LOG_ENABLED 0
#else
#define LOG_ENABLED 0
#endif

#define SMLog(format, ...) do { if(LOG_ENABLED) { NSLog(@"[DEBUG:%s:(%@):%d] "format, object_getClassName(self), NSStringFromSelector(_cmd), __LINE__, ##__VA_ARGS__); } } while(0)
