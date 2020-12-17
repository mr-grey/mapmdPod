//
//  SMapHelper.m
//  map_new_engine
//
//  Created by grey on 3/13/17.
//  Copyright © 2017 grey. All rights reserved.
//

#import "SMapHelper.h"


@implementation SMapHelper

+ (double)DegreeToRadian:(double)angle
{
    return M_PI * angle / 180.0;
}

+ (double)RadianToDegree:(double)angle
{
    return angle * (180.0 / M_PI);
}

+ (float)randomFloatBetween:(float)smallNumber and:(float)bigNumber {
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}


+ (float)calculateUserDirection:(CLLocationCoordinate2D)loc1 second:(CLLocationCoordinate2D)loc2 {
    
    double x1 = [SMapHelper DegreeToRadian:loc1.latitude];
    double x2 = [SMapHelper DegreeToRadian:loc2.latitude];
    
    double lambda = [SMapHelper DegreeToRadian:(loc2.longitude - loc1.longitude)];
    double y = sin(lambda) * cos(x2);
    double x = cos(x1) * sin(x2) - sin(x1)*cos(x2) * cos(lambda);
    double θ = atan2(y, x);
    
    int grad = [SMapHelper RadianToDegree:θ];
    
    int res = (grad + 360) % 360;

    return res;
}
    
/*
 var φ1 = this.lat.toRadians(), φ2 = point.lat.toRadians();
 var Δλ = (point.lon-this.lon).toRadians();
 var y = Math.sin(Δλ) * Math.cos(φ2);
 var x = Math.cos(φ1)*Math.sin(φ2) - Math.sin(φ1)*Math.cos(φ2)*Math.cos(Δλ);
 var θ = Math.atan2(y, x);
 
 return (θ.toDegrees()+360) % 360;
 */

/* return angle in degrees */
+ (double)directionBetweenPoints:(MKMapPoint )sourcePoint dest:(MKMapPoint)destinationPoint {
    double x = destinationPoint.x - sourcePoint.x;
    double y = destinationPoint.y - sourcePoint.y;
   
    return fmod(XXRadiansToDegrees(atan2(y, x)), 360.0f) + 90.0f;
}

+ (double)DegreesToRadians:(double)degrees {
    return degrees * M_PI / 180.0f;
}

static inline double XXRadiansToDegrees(double radians) {
    return radians * 180.0f / M_PI;
}

double XXDegreesToRadians(double degrees) {
    return degrees * M_PI / 180.0f;
}

+ (double)distanceBetween:(CLLocationCoordinate2D)loc1 point:(CLLocationCoordinate2D)loc2 {
    CLLocation *oldLocation = [[CLLocation alloc] initWithLatitude:loc1.latitude longitude:loc1.longitude];
    CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:loc2.latitude longitude:loc2.longitude];
    
    
    CLLocationDistance dist = [oldLocation distanceFromLocation:newLocation];
    
    oldLocation = nil;
    newLocation = nil;
    
    return dist;
}

+ (NSString *)formatDuration:(double)timeSeconds {
    
    
    return @"";
}


+ (NSString *) localizedLocation {
    
    NSString *timeString = @"";
    NSString *la = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] description];
    if ([la rangeOfString:@"ro"].location != NSNotFound) timeString = @"Locație necunoscută";
    if ([la rangeOfString:@"ru"].location != NSNotFound) timeString = @"Местоположение не определено";
    if ([la rangeOfString:@"md"].location != NSNotFound) timeString = @"Местоположение не определено";
    if ([la rangeOfString:@"en"].location != NSNotFound) timeString = @"unknown location";
    
   
    
    return timeString;
}


+ (NSAttributedString*)localizedTime:(int)secs {
    
    /* format time */
    int mins = secs / 60;
    secs %= 60;
    
    int hours = mins / 60;
    mins %= 60;
    
    NSString *timeString = @"";
    
    NSString *unitMin = @"min";
    NSString *unitHour = @"hour";
    NSString *unitSecs = @"sec";
    NSNumber *Lang = @0;
    
    NSString *la = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] description];
    if ([la rangeOfString:@"ro"].location != NSNotFound) Lang = @2;
    if ([la rangeOfString:@"ru"].location != NSNotFound) Lang = @1;
    if ([la rangeOfString:@"md"].location != NSNotFound) Lang = @2;
    
    
    if ([Lang integerValue] == 1) { unitMin = @"мин"; unitHour = @"час"; unitSecs = @"сек"; }
    if ([Lang integerValue] == 2) { unitMin = @"min"; unitHour = @"oră"; unitSecs = @"sec";  }
    
    if (hours == 0) {
        
        if (mins < 10) {
            if (mins == 0)
                timeString = [NSString stringWithFormat:@"%i %@",secs,unitSecs];
            else
                timeString = [NSString stringWithFormat:@"%i %@",mins,unitMin];
        }else
            timeString = [NSString stringWithFormat:@"%02d %@",mins,unitMin];
        
    } else {
        timeString = [NSString stringWithFormat:@"%i %@ %02d %@",hours, unitHour, mins, unitMin];
    }
    
    NSMutableAttributedString *astr = [[NSMutableAttributedString alloc] initWithString:timeString attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Helvetica-Bold" size:19], NSForegroundColorAttributeName: [UIColor colorWithRed:(52/255) green:(52/255) blue:(52/255) alpha:1.0] }];
    
    //[UIFont fontWithName:@"Helvetica" size:12.5]
    NSRange r = [timeString rangeOfString:unitHour];
    
    if (r.location != NSNotFound) {
        [astr setAttributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:12.5] } range:r];
    }
    
    r = [timeString rangeOfString:unitSecs];
    
    if (r.location != NSNotFound) {
        [astr setAttributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:12.5] } range:r];
    }
    
    r =  [timeString rangeOfString:unitMin];
    
    if (r.location != NSNotFound) {
        [astr setAttributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:12.5] } range:r];
    }
    
    
    return astr;
}

+ (NSAttributedString*)localizedSpeed:(double)sp {
    
    NSString *txtMetrix;
    double inKm = sp *3.6;
    NSNumber *Lang = @0;
    NSString *la = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] description];
    if ([la rangeOfString:@"ro"].location != NSNotFound) Lang = @2;
    if ([la rangeOfString:@"ru"].location != NSNotFound) Lang = @1;
    if ([la rangeOfString:@"md"].location != NSNotFound) Lang = @2;
    
    if ([Lang integerValue] == 0) {
        // en
        txtMetrix = @"km/h";
    } else if ([Lang integerValue] == 1) {
        // ru
        txtMetrix = @"км/ч";
    } else {
        txtMetrix = @"km/h";
    }
    
    NSString *speedValueStr = [NSString stringWithFormat:@"%.1f",inKm];
    NSString *fullTxt = [NSString stringWithFormat:@"%@ %@",speedValueStr, txtMetrix];
    
    NSMutableAttributedString *astr = [[NSMutableAttributedString alloc] initWithString:fullTxt attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:12.5], NSForegroundColorAttributeName: [UIColor colorWithRed:(52/255) green:(52/255) blue:(52/255) alpha:1.0] }];
    
    NSRange r = [fullTxt rangeOfString:speedValueStr];
    
    if (r.location != NSNotFound) {
        [astr setAttributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Helvetica-Bold" size:19] } range:r];
    }
    
    return astr;
}
/* this function used for put annotation */
+ (NSDictionary*)maxDistanceFromTwooPointsOfRoutes:(NSArray*)points1 second:(NSArray *)points2 {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    double max = 0;
    
    if (points1.count == points2.count) {
        
        for (NSInteger i = 0; i < points1.count; i++ ) {
            NSArray *p1 = [points1 objectAtIndex:i];
            NSArray *p2 = [points2 objectAtIndex:i];
            
            double lat1 = [[p1 lastObject] doubleValue];
            double lon1 = [[p1 firstObject] doubleValue];
            
            double lat2 = [[p2 lastObject] doubleValue];
            double lon2 = [[p2 firstObject] doubleValue];
            
            
            CLLocationCoordinate2D loc1 = CLLocationCoordinate2DMake(lat1, lon1);
            CLLocationCoordinate2D loc2 = CLLocationCoordinate2DMake(lat2, lon2);
            
            double dist = [SMapHelper distanceBetween:loc1 point:loc2];
            if (dist > max) {
                max = dist;
                NSValue *val1 = [NSValue valueWithMKCoordinate:loc1];
                NSValue *val2 = [NSValue valueWithMKCoordinate:loc2];
                [result setObject:val1 forKey:@"1"];
                [result setObject:val2 forKey:@"2"];
                
            }
            
        }
        
        
    } else {
        // arrays not equals
        // take smaller ?
        NSInteger limit = (points1.count > points2.count) ? points2.count:points1.count;
        
        for (int i = 0; i < limit; i++) {
            NSArray *p1 = [points1 objectAtIndex:i];
            NSArray *p2 = [points2 objectAtIndex:i];
            
            double lat1 = [[p1 lastObject] doubleValue];
            double lon1 = [[p1 firstObject] doubleValue];
            
            double lat2 = [[p2 lastObject] doubleValue];
            double lon2 = [[p2 firstObject] doubleValue];
            
            
            CLLocationCoordinate2D loc1 = CLLocationCoordinate2DMake(lat1, lon1);
            CLLocationCoordinate2D loc2 = CLLocationCoordinate2DMake(lat2, lon2);
            
            double dist = [SMapHelper distanceBetween:loc1 point:loc2];
            if (dist > max) {
                max = dist;
                NSValue *val1 = [NSValue valueWithMKCoordinate:loc1];
                NSValue *val2 = [NSValue valueWithMKCoordinate:loc2];
                [result setObject:val1 forKey:@"1"];
                [result setObject:val2 forKey:@"2"];
                
            }
        }
        
        
    }
    
    return result;
}

+ (UIImage*)imageForGroup:(int)count {
   
    NSInteger total = count;
    NSString *txt = [NSString stringWithFormat:@"%li",(long)total];
    if (count == 0) txt = @"";
    
    UIFont *font = [UIFont fontWithName:@"Arial-BoldMT" size:15];
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    CGRect textRect = rect = CGRectMake(0,0,29,29);
    
    if(total<=10)
        rect = CGRectMake(0,0,29,29);
    if(total<=100 && total > 10)
        rect = CGRectMake(0,0,45,45);
    if(total>100)
        rect = CGRectMake(0,0,53,53);
    
    textRect = CGRectMake( 0, (rect.size.height/2.0) - 7.5 , rect.size.width, rect.size.height);
    
    
    
    UIColor *color = [UIColor colorWithRed:(46.0/255.0) green:(127.0/255.0) blue:(209.0/255.0) alpha:1.0];
    
    UIGraphicsBeginImageContextWithOptions(rect.size,NO, 2);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSTextAlignmentCenter;
    style.maximumLineHeight = 15;
    style.minimumLineHeight = 15;
    
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextAddArc(context, rect.size.width/2, rect.size.height/2, (rect.size.height/2), 0, [SMapHelper DegreeToRadian:360], 0);
    CGContextFillEllipseInRect (context, rect);
    
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextAddArc(context, rect.size.width/2, rect.size.height/2, ((rect.size.height/2.0) - 3), 0, [SMapHelper DegreeToRadian:360], 0);
    CGContextFillEllipseInRect (context, CGRectInset(rect, 3, 3));
    [[UIColor whiteColor] setStroke];
    
    //CGContextSetStrokeColor(context, [UIColor whiteColor].CGColor);
    
    [txt drawInRect:textRect withAttributes:@{ NSFontAttributeName: font, NSForegroundColorAttributeName:[UIColor whiteColor], NSParagraphStyleAttributeName:style }];
    
    
    
    
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    return image;
}

@end
