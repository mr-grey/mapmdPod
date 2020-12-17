//
//  map.m
//  map
//
//  Created by user on 4/10/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import "map.h"
#import "MapView.h"
#import <Mapbox/Mapbox.h>
#import <Mapbox/MGLAnnotation.h>
#import "MapMarker.h"
#import "MarkerManager.h"
#import "MarkerAnnotationView.h"
#import <SVGKit/SVGKImage.h>
#import "RouteCalloutView.h"
#import "RouteAnnotationView.h"
#import "Routing.h"
#import "SMapRoute.h"
#import "SMapObject.h"

/*
 
static MGLCoordinateBounds mapBounds;

 .northeast = {.latitude = 48.48, .longitude = 26.59},
 .southwest = {.latitude = 45.45, .longitude = 30.14}

 */


@interface MapView ()  <MGLMapViewDelegate>
@property (nonatomic, retain) MGLPointFeature *selectedFeature;
@property (nonatomic, retain) MGLMapView *map;
@property (nonatomic, weak) MGLUserLocation *user;
@property (nonatomic, retain) UIButton *logo;
@property (nonatomic, retain) MarkerManager *manager;
@property (nonatomic, retain) NSMutableArray *mapObjects;
@property (nonatomic, retain) NSMutableArray *sourcesToRestore;
@property (nonatomic, retain) NSMutableArray *layersToRestore;
@property (nonatomic, retain) NSMutableArray *routes;
@property (nonatomic, retain) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, retain) NSTimer *dropPinTimer;
@property (readwrite) MapLogoPosition logo_position;
@property (readwrite) MapViewMode mapMode;
@property (readwrite) BOOL shouldRestoreClusters;
@property (readwrite) BOOL longPressEnabled;



@end


@implementation MapView
@synthesize delegate;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self postInit];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self postInit];
    return self;
}

- (instancetype)init {
    
    self = [super init];
    [self postInit];
    return self;
}

- (void)addMapObject:(SMapObject *)object {
    [self.mapObjects addObject:object];
}


- (MarkerManager *)markerManager {
    if (self.manager == nil)  {
        self.manager = [[MarkerManager alloc] initWithMap:self];
    }
    
    
    return self.manager;
}

- (void)dropPin:(NSTimer *)timer {
    
    NSDictionary *userinfo = [timer userInfo];
    NSValue *start = userinfo[@"start"];
    CGPoint firstTouch = [start CGPointValue];
    
    [timer invalidate];
    timer = nil;
    self.dropPinTimer = nil;
    
    CGPoint tapPoint = [self.longPressGestureRecognizer locationInView:self.map];
    if (self.tapGestureRecognizer) {
        UIGestureRecognizerState state = self.tapGestureRecognizer.state;
        if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStatePossible || state == UIGestureRecognizerStateRecognized) {
            [self.tapGestureRecognizer setEnabled:NO];
            [self.tapGestureRecognizer setEnabled:YES];
        }
    }
    
    NSArray *recognizers = [self.map gestureRecognizers];
    for (UIGestureRecognizer *gs in recognizers) {
        if (gs.enabled) {
            [gs setEnabled:NO];
            [gs setEnabled:YES];
        }
    }
    
    
    
    
    CGFloat deltaX = fabs(tapPoint.x - firstTouch.x);
    CGFloat deltaY = fabs(tapPoint.y - firstTouch.y);
    
    if (deltaX > 3 || deltaY > 3) { SMLog(@"to away from start %f %f",deltaX, deltaY);   return; }
    
    CLLocationCoordinate2D tapCoordinate = [self.map convertPoint:tapPoint toCoordinateFromView:self.map];
   
    
    [self.longPressGestureRecognizer setEnabled:NO];
    [self.longPressGestureRecognizer setEnabled:YES];
    
    MarkerManager *manager = [self markerManager];
    MapMarker *pin = [manager getDropedPin];
    if (pin) {
        // find pin default marker
        SMLog(@"remove old == pin: %@", pin);
        [[self map] deselectAnnotation:pin animated:NO];
        [[self map] removeAnnotation:pin];
       
    }
    
    [manager removeMarkerWhithId:@"drop_pin_id"];
    
    
    
    MapMarker *m = [[MapMarker alloc] init];
    m.coordinate = tapCoordinate;
    m.title = [SMapHelper localizedLocation];
    m.subtitle = @"";
    m.accessibilityLabel = @"drop_pin";
    m.objectid = @"drop_pin_id";
    m.marker_type = MarkerTypeDroppedPin;
    m.image = [UIImage imageNamed:@"pin"];
    m.selectedImage = [UIImage imageNamed:@"pin_selected"];
    m.isSelected = true;
    m.selectable = true;
    
    [manager addMarker:m];
    // userDidDropPin
    [[NSNotificationCenter defaultCenter] postNotificationName:@"userDidDropPin" object:m];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.map selectAnnotation:m animated:false];
    });
    
    if (delegate && [delegate respondsToSelector:@selector(didDropPin:)]) { [delegate didDropPin:m]; }
    
    MGLAnnotationView *v = [self.map viewForAnnotation:m];
    [v setCenterOffset:CGVectorMake(0,-33)];
    
}

- (void)handleMapTap:(UITapGestureRecognizer*) gs {
   
    if (gs.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    if ([gs class] == [UITapGestureRecognizer class]) {
        // single tap on map
        gs.enabled = false;
        CGPoint point = [gs locationInView:gs.view];
        CGRect compassFrame = self.map.compassView.frame;
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            gs.enabled = true;
        });
        
        if (gs.state != UIGestureRecognizerStateEnded) return;
        
        // check if tap on compass
        if (CGRectContainsPoint(compassFrame, point)) {
            // return its compass !
            NSLog(@"tap on compass!");
            return;
        }
        
        
        CGFloat width = 31;
        
        CLLocationCoordinate2D tapCoordinate = [self.map convertPoint:point toCoordinateFromView:self.map];
        NSDictionary *params = @{ @"location": [NSValue valueWithCGPoint:point], @"coordinate": [NSValue valueWithMKCoordinate:tapCoordinate] };
       
        
        CGRect rect = CGRectMake(point.x - width / 2, point.y - width / 2, width, width);
        
        NSArray<id<MGLFeature>> *features = [self.map visibleFeaturesInRect:rect inStyleLayersWithIdentifiers:[NSSet setWithObjects:@"clusteredPins", @"pin", @"clusters", @"cluster", @"rid_1", @"rid_0", @"vector-poi-cemetery", @"poi", nil]];
        
        NSArray<id<MGLFeature>> *allfeatures = [[self map] visibleFeaturesInRect:rect];
        if (allfeatures.count) {
            
            for (id feat in allfeatures) {
                if ([feat class] == [MGLPolylineFeature class]) {
                    MGLPolylineFeature *poly = feat;
                    NSString *identifier = [poly identifier];
                    if (!identifier) continue;
                    NSString *rid = [identifier description];
                    if ([rid rangeOfString:@"rid_"].location != NSNotFound) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"tapOnFeature" object:feat];
                        
                        
                        SMapRoute *ro = [self getRouteById:rid];
                        if (ro) {
                            
                        }
                        
                        return;
                    }
                    
                   
                    
                }
                
                if ([feat class] == [MGLPointFeatureCluster class]) {
                    // do zoom in
                    MGLPointFeatureCluster *cl = feat;
                    double z = [self.map zoomLevel];
                    double maxZ = [self.map maximumZoomLevel];
                    double newZ = z + 1.1;
                    if (newZ <= maxZ) {
                        // zoom to point
                        CLLocationCoordinate2D loc = cl.coordinate;
                        [self.map setCenterCoordinate:loc zoomLevel:newZ animated:true];
                        return;
                    }
                    
                }
                
                
                if ([feat isKindOfClass:[MGLPointFeature class]]) {
                    // try get id
                    MGLPointFeature *f = feat;
                    NSDictionary *attrib = [f attributes];
                    if ([attrib objectForKey:@"branch_id"]) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"tapOnFeature" object:f];
                        return;
                    }
                   
                
                }
            }
            SMLog(@"- none match");
            
        }
        
        
        // Pick the first feature (which may be a port or a cluster), ideally selecting
        // the one nearest nearest one to the touch point.
        id<MGLFeature> feature = features.firstObject;
        
        if (!feature) {
            // no any feature
            [[NSNotificationCenter defaultCenter] postNotificationName:@"tapOnMap" object:params];
          
            NSDate *date = [NSDate date];
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"YYYY-MM-DD hh:mm:ss"];
            NSString *output = [NSString stringWithFormat:@"<wpt lat=\"%.5f\" lon=\"%.5f\">  <name>%@</name>  <time>%@</time> </wpt>",
            tapCoordinate.latitude, tapCoordinate.longitude, NSStringFromClass(self.class), [df stringFromDate:date]];
            printf("%s\n",output.UTF8String);
            
                
          
            self.selectedFeature = nil;
            
            if (delegate && [delegate respondsToSelector:@selector(tapOnMap:)]) {
                [delegate tapOnMap:[NSValue valueWithMKCoordinate:tapCoordinate]];
            }
            
            
            return;
        }
        
        SMLog(@"tap on feature: %@",feature);
        
        NSArray *a = [self.map selectedAnnotations];
        for (id anni in a) {
            [self.map deselectAnnotation:anni animated:true];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"tapOnFeature" object:feature];
        if ([feature class] == [MGLPointFeatureCluster class]) {
            // do zoom in
            double z = [self.map zoomLevel];
            double maxZ = [self.map maximumZoomLevel];
            double newZ = z + 1.1;
            if (newZ <= maxZ) {
                // zoom to point
                CLLocationCoordinate2D loc = feature.coordinate;
                [self.map setCenterCoordinate:loc zoomLevel:newZ animated:true];
            }
            
        }
        
        
        
        if (self.selectedFeature) {
            NSDictionary *att = [self.selectedFeature attributes];
            NSMutableDictionary *newAtt = [NSMutableDictionary dictionaryWithDictionary:att];
            [newAtt setObject:[NSNumber numberWithDouble:1.0] forKey:@"aplha"];
            [newAtt setObject:@YES forKey:@"visible"];
            
            [self.selectedFeature setAttributes:newAtt];
        }
        

        
        return;
    }
    // long press !!
    // SMLog(@"%@ number : %zd",gs, gs.numberOfTouches);
   
    
}

- (void)disableLongPress {
    self.longPressGestureRecognizer.enabled = false;
    _longPressEnabled = false;
}

- (void)enableLongPress {
    // Add a single tap gesture recognizer. This gesture requires the built-in MGLMapView tap gestures (such as those for zoom and annotation selection) to fail.
    SMLog(@"%s",__func__);
    if (self.longPressGestureRecognizer == nil) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleMapTap:)];
        longPress.minimumPressDuration = .6;
        longPress.delaysTouchesBegan = NO;
        longPress.delaysTouchesEnded = NO;
        longPress.delegate = (id)self;
        self.longPressGestureRecognizer = longPress;
        
        for (UIGestureRecognizer *recognizer in self.map.gestureRecognizers) {
            if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
                [longPress requireGestureRecognizerToFail:recognizer];
            }
        }
        [self.map addGestureRecognizer:longPress];
    }
    

    self.longPressGestureRecognizer.enabled = true;
    _longPressEnabled = true;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint tapPoint = [self.longPressGestureRecognizer locationInView:self.map];
    SMLog(@"gestureRecognizer %@ ShouldBegin: %f %f", gestureRecognizer, tapPoint.x, tapPoint.y);
    
    if ([gestureRecognizer class] == [UILongPressGestureRecognizer class]) {
        if (self.dropPinTimer) {
            [self.dropPinTimer invalidate];
            self.dropPinTimer = nil;
        }
       
        if (self.dropPinTimer) {
            [self.dropPinTimer invalidate];
            self.dropPinTimer = nil;
        }
        self.dropPinTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(dropPin:) userInfo:@{ @"start":[NSValue valueWithCGPoint:tapPoint] } repeats:false];
        
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)moveToUserLocation {
    MGLUserLocation *usrlocation = [self.map userLocation];
    if (usrlocation) {
        CLLocation *location = usrlocation.location;
        if (location == nil) return;
        if ([self.map isUserLocationVisible]) {
            [self setCenterCoordinate:location.coordinate animated:YES];
        } else {
            [self setCenterCoordinate:location.coordinate animated:NO];
        }
    }
}

- (BOOL)isUserLocationInCenter {
    
    MGLMapCamera *currentCamera = [self.map camera];
    CLLocationCoordinate2D cameraCenter = [currentCamera centerCoordinate];
    MGLUserLocation *usrlocation = [self.map userLocation];
    if (usrlocation) {
        CLLocationCoordinate2D usr = usrlocation.coordinate;
        if ([SMapHelper distanceBetween:cameraCenter point:usr] < 3) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)isUserLocationVisible {
    return [self.map isUserLocationVisible];
}

- (CLLocation *)userLocation {
    MGLUserLocation *usrlocation = [self.map userLocation];
    CLLocation *location = usrlocation.location;
    return location;
    
}

- (void)stopUpdatingLocation {
    self.map.showsUserLocation = NO;
    [self.map.locationManager stopUpdatingLocation];
}

- (void)startUpdatingLocation {
    self.map.showsUserLocation = YES;
    [self.map.locationManager startUpdatingLocation];
}

- (void)postInit {
    CGRect mapRect = self.bounds;
    if (CGRectIsNull(mapRect)) {
        mapRect = [UIScreen mainScreen].bounds;
    }
    
    if (self.map != nil) return;
    
    [self configure];
    self.sourcesToRestore = [[NSMutableArray alloc] init];
    self.layersToRestore = [[NSMutableArray alloc] init];
    self.mapObjects = [[NSMutableArray alloc] init];
    
    self.map = [[MGLMapView alloc] initWithFrame: mapRect];
    
    
    self.map.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self.map setMaximumZoomLevel:19];
    [self.map setMinimumZoomLevel:6];
    self.map.delegate = self;
    self.map.styleURL = [NSURL URLWithString:@"https://map.md/api/tiles/styles/map/style.json"];
    
    
    
    [self addSubview:self.map];
    
    // self.map.attributionButton.hidden = YES;
    self.map.logoView.hidden = YES;
    self.map.attributionButtonMargins = CGPointMake(99999, 99999);
    
    self.logo_position = MapLogoPositionBottomLeft;
    
    self.map.latitude = 47.023006;
    self.map.longitude = 28.833677;
    self.map.zoomLevel = 10;
    
    [self markerManager];
    [self buildLogo];
    self.routes = [[NSMutableArray alloc] init];
    
    _satelliteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 51, 51)];
    [_satelliteButton addTarget:self action:@selector(satelliteButtonTouched:) forControlEvents:(UIControlEventTouchUpInside)];
    _satelliteButton.translatesAutoresizingMaskIntoConstraints = false;
    
    [self addSubview:_satelliteButton];
    
    // bot
    NSLayoutConstraint *bot = [NSLayoutConstraint constraintWithItem:_satelliteButton attribute:(NSLayoutAttributeBottom) relatedBy:NSLayoutRelationEqual toItem:self attribute:(NSLayoutAttributeBottom) multiplier:1.0 constant:-31];
    
    [self addConstraint:bot];
    
    // right NSLayoutAttributeTrailing
    NSLayoutConstraint *trail = [NSLayoutConstraint constraintWithItem:_satelliteButton attribute:NSLayoutAttributeTrailing relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeTrailing) multiplier:1.0 constant:-4];
    
    [self addConstraint:trail];
    
    
    NSLayoutConstraint *wi = [NSLayoutConstraint constraintWithItem:_satelliteButton attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1.0 constant:51];
    
    NSLayoutConstraint *hei = [NSLayoutConstraint constraintWithItem:_satelliteButton attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1.0 constant:51];
    
   
    [self addConstraint:wi];
    [self addConstraint:hei];
}

- (void)configure {
    
    NSString *apikey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapmdApiKey"];
    MGLNetworkConfiguration *config = [MGLNetworkConfiguration sharedManager];
    NSURLSessionConfiguration *co = [config sessionConfiguration];
    
    if (apikey == nil) {
        apikey = @"noKey";
    }
    
    [co setHTTPAdditionalHeaders:@{ @"platform": @"iOS" }];
    
    
    if (apikey) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", apikey, @""];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:(NSDataBase64EncodingEndLineWithLineFeed)]];
  
        [co setHTTPAdditionalHeaders:@{ @"Authorization": authValue , @"ApplicationId": [NSBundle mainBundle].bundleIdentifier , @"platform": @"iOS" } ];
        
    }
    config.sessionConfiguration = co;
    
    
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
   
    if (self.map) {
        self.map.frame = self.bounds;
    }
}

- (float)zoomLevel {
    return [self.map zoomLevel];
}

- (void)setZoomLevel:(double)level {
    [self.map setZoomLevel:level];
}

- (void)moveTo:(CLLocationCoordinate2D )location {
    [self.map setCenterCoordinate:location animated:NO];
}
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated {
    [self.map setCenterCoordinate:coordinate animated:animated];
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(double)zoomLevel animated:(BOOL)animated {
    [self.map setCenterCoordinate:centerCoordinate zoomLevel:zoomLevel animated:animated];
}

- (void)setMapViewMode:(MapViewMode)mode {
    
    bool wasDirvemode = (self.mapMode == MapViewModeDrive);
    self.mapMode = mode;
    /// changes be here
    if (mode == MapViewModeFollow) {
        [[self map] setUserTrackingMode:(MGLUserTrackingModeFollow)];
    }
    
    if (mode == MapViewModeDefault) {
        
        if (wasDirvemode) {
            MGLMapCamera *camera = [self.map camera];
            [camera setPitch:0];
            [camera setViewingDistance:320];
            [self.map setCamera:camera animated:YES];
        }
       
        
        [[self map] setUserTrackingMode:(MGLUserTrackingModeNone)];
        
    }
    
    if (mode == MapViewModeCompass) {
         [[self map] setUserTrackingMode:(MGLUserTrackingModeFollowWithHeading)];
    }
    
    if (mode == MapViewModeDrive) {
       
        [[self map] setZoomLevel:17];
        [self removeNotSelectedRoutes];
        
        SMapRoute *r = [self.routes firstObject];
        
        if (r){
            
            NSArray *annotations = [[self map] annotations];
            for (id <MGLAnnotation> annotation in annotations) {
                SMLog(@"%@",annotation);
                MapMarker *m = annotation;
                if (m.marker_type == MarkerTypeRouteCenterPin) {
                    [[self map] removeAnnotation:annotation];
                }
            }
            
            
        }
        
        if (self.userLocation) {
            CLLocationCoordinate2D center = [self userLocation].coordinate;
            MGLMapCamera *camera = [self.map camera];
            [camera setPitch:49];
            [camera setCenterCoordinate:center];
            [camera setViewingDistance:130];
            [self.map setCamera:camera animated:YES];
            [[self map] setUserTrackingMode:(MGLUserTrackingModeFollowWithCourse)];
            [self.map setCamera:camera animated:NO];
        }
        

        
    }
}

- (void)removeFromSuperview {
    self.map.delegate = nil;
    [self.map removeFromSuperview];
    self.map = nil;
}

- (void)removeNotSelectedRoutes {
    NSMutableArray *toRemove = [NSMutableArray array];
    
    for (SMapRoute *r in self.routes) {
        if (r.selected == false) {
            [toRemove addObject:r.routeId];
        }
    }
    
    for (NSString *rid in toRemove) {
        [self removeRoute:rid];
    }
    
}

- (BOOL)isShowingClusters {
    
    NSArray *layers = [self.map.style layers];
    for (MGLStyleLayer *layer in layers) {
        NSString *rid = layer.identifier;
        
        //clusteredPins
        if ([rid rangeOfString:@"clusters"].location != NSNotFound) {
            return true;
        }
        
        //clusteredPins
        if ([rid rangeOfString:@"clusteredPins"].location != NSNotFound) {
            return true;
        }
    }
    
    return false;
}

// MARK: - Markers
- (void)addMarker:(NSDictionary *)marker {
    
    NSString *type = marker[@"type"];
    
    
    NSValue *coords = [marker valueForKey:@"coordinate"];
    
    MapMarker *m = [[MapMarker alloc] init];
    m.coordinate = [coords MGLCoordinateValue];
    m.title = marker[@"title"];
    m.subtitle = marker[@"subtitle"];
    m.marker_type = [type integerValue];
    m.accessibilityLabel = @"default_marker";

    // Add marker `hello` to the map
    [self.map addAnnotation:m];
    
}

- (void)selectMarker:(MapMarker *)m animated:(BOOL)a {
    if (!m) return;
    [self.map selectAnnotation:m animated:a];
}


- (void)selectMarker:(MapMarker *)m {
    if (!m) return;
    [self.map selectAnnotation:m animated:YES];
}

- (void)deselectMarker:(MapMarker *)m animated:(BOOL)a {
    if (!m) return;
    [self.map deselectAnnotation:m animated:a];
}


- (void)deselectMarker:(MapMarker *)m {
    if (!m) return;
    [self.map deselectAnnotation:m animated:YES];
}

- (void)deselectAll {
    NSArray *a = [self.map selectedAnnotations];
    for (id anni in a) {
        [self.map deselectAnnotation:anni animated:true];
    }
}

- (CLLocationCoordinate2D)centerCoordinate {
    CLLocationCoordinate2D coord = [self.map.camera centerCoordinate];
    return coord;
}

- (MGLMapView *)getMapView {
    return self.map;
}


- (void)satelliteButtonTouched:(UIButton *)sender {
    if (sender.isSelected) {
        [sender setSelected:NO];
        [self showSatellite:NO];
        return;
    }
    
    [sender setSelected:YES];
    [self showSatellite:YES];
    
}

- (void)showSatellite:(BOOL)show {
    
    _shouldRestoreClusters = [self isShowingClusters];
    
    // remove all custom objects
    @synchronized (self.mapObjects) {
        NSMutableArray *toDelete = [NSMutableArray arrayWithArray:self.mapObjects];
        for (SMapObject *object in toDelete) {
            if ([object isKindOfClass:[SMapRoute class]]) {
                SMapRoute *r = (SMapRoute *) object;
                MGLSource *sour = [r source];
                MGLStyleLayer *la = r.layer;
                MGLStyleLayer *la_stroke = r.strokeLayer;
                
            
                [[[self map] style] removeLayer:la];
                [[[self map] style] removeLayer:la_stroke];
                [[[self map] style] removeSource:sour];
                
                [self.routes removeObject:r];
                
                continue;
            }
            if ([object isKindOfClass:[SMapObject class]]) {
                MGLSource *sour = [object source];
                NSArray *layers = [object layers];
                
                
                for (MGLStyleLayer *la in layers) {
                    [[[self map] style] removeLayer:la];
                }
                
                if (sour) { [[[self map] style] removeSource:sour]; }
            }
            
        }
    }
    
    
    
    NSArray *layers = [self.map.style layers];
    for (MGLStyleLayer *layer in layers) {
        NSString *rid = layer.identifier;
        if ([rid hasPrefix:@"rid"]) {
            // possible is route layer
            
            [self.map.style removeLayer:layer];
            [self.layersToRestore addObject:layer];
            
            continue;
        }
        
        
        //arrows , route_pin_direction
        if ([rid hasPrefix:@"route_pin_direction"]) {
            // possible is route layer
            
            [self.map.style removeLayer:layer];
            [self.layersToRestore addObject:layer];
            
            continue;
        }
        //arrows , route_pin_direction
        if ([rid hasPrefix:@"arrows"]) {
            // possible is route layer
            
            [self.map.style removeLayer:layer];
            [self.layersToRestore addObject:layer];
            
            continue;
        }
        
        
        //clusteredPins
        if ([rid rangeOfString:@"clusters"].location != NSNotFound) {
            [self.map.style removeLayer:layer];
            // not save. it will create again
            continue;
        }
        
        //clusteredPins
        if ([rid rangeOfString:@"clusteredPins"].location != NSNotFound) {
          
            [self.map.style removeLayer:layer];
            // not save. it will create again
            continue;
        }
    }
    
    NSSet *sources = [self.map.style sources];
    self.selectedFeature = nil;
    
    for (MGLSource *s in sources.allObjects) {
        //   SMLog(@"clearMap: %@",s.identifier);
        NSString *rid = s.identifier;
        if ([rid hasPrefix:@"rid"]) {
            [self.sourcesToRestore addObject:s];
            [self.map.style removeSource:s];
        }
        
        // arrows
        if ([rid hasPrefix:@"arrows"]) {
            [self.sourcesToRestore addObject:s];
            [self.map.style removeSource:s];
        }
        
        
        
        //clusteredPins
        if ([rid rangeOfString:@"clusteredPins"].location != NSNotFound) {
            [self.sourcesToRestore addObject:s];
            [self.map.style removeSource:s];
        }
    }
    
    if (show) {
        [self.map setStyleURL:[NSURL URLWithString:@"https://map.md/api/tiles/styles/satelite/style.json"]];
    } else {
       [self.map setStyleURL:[NSURL URLWithString:@"https://map.md/api/tiles/styles/map/style.json"]];
    }
    
    [self.map reloadStyle:nil];
    
    
}

- (void)restoreClusters:(MGLSource *)source {
   
}

- (void)restoreSource:(MGLSource *)source {
    
    NSMutableArray *toAdd = [[NSMutableArray alloc] init];
    MGLStyle *style = [self.map style];
    
   // UIImage *pinImage = [SMapHelper imageForGroup:1];   // for 999
   // UIImage *clusterImage = [SMapHelper imageForGroup:0]; // for 999
  
  UIImage *clusterImage = [UIImage imageNamed:@"cluster"];
  if (clusterImage) {
    [style setImage:clusterImage forName:@"cluster"];
  } else {
    [style setImage:[SMapHelper imageForGroup:0] forName:@"cluster"];
  }
  
  UIImage *pinImage = [UIImage imageNamed:@"pin"];
  if (pinImage) {
    [style setImage:pinImage forName:@"pin"];
  } else {
    [style setImage: [SMapHelper imageForGroup:1] forName:@"pin"];
  }
  
  UIImage *route_dir_pin = [UIImage imageNamed:@"route_dir_pin"];
  if (route_dir_pin) {
    [style setImage:route_dir_pin forName:@"route_dir_pin"];
  }
    @synchronized (self.mapObjects) {
        for (SMapObject *object in self.mapObjects) {
            if ([object isKindOfClass:[SMapRoute class]]) {
                SMapRoute *r = (SMapRoute *)object;
                [toAdd addObject:r];
                
                // add route to map
                      MGLShapeSource *source = r.source;
                      MGLLineStyleLayer *layer = r.layer;
                      MGLLineStyleLayer *layer_stroke = r.strokeLayer;
                      
                      [self.map.style addSource:source];
                      
                      BOOL inserted = false;
                      
                      MGLStyle *style = [self.map style];
                      MGLStyleLayer *la = [style layerWithIdentifier:@"vector-highway-name-primary-copy"];
                      if (la) {
                          [style insertLayer:layer_stroke belowLayer:la];
                          [style insertLayer:layer belowLayer:la];
                          inserted = YES;
                      } else {
                          la = [style layerWithIdentifier:@"vector-highway-name-secondary"];
                                 
                          if (la) {
                              [style insertLayer:layer_stroke belowLayer:la];
                              [style insertLayer:layer belowLayer:la];
                              inserted = YES;
                          }
                      }
                      
                      if (inserted == false) {
                          [self.map.style addLayer:layer_stroke];
                          [self.map.style addLayer:layer];
                      }
                      
                      [self.routes addObject:r];

                
            }
            
            if ([object isKindOfClass:[SMapObject class]]) {
                MGLSource *source = [object source];
                NSArray *layers = [object layers];
                
                if (source) {
                    [[[self map] style] addSource:source];
                }
                
                for (MGLStyleLayer *la in layers) {
                    [[[self map] style] addLayer:la];
                }
                
                [toAdd addObject:object];
            }
            
        }
    }
    
    [self.mapObjects removeAllObjects];
    [self.mapObjects addObjectsFromArray:toAdd];
    
    toAdd = nil;
    
    
    for (MGLShapeSource *s in self.sourcesToRestore) {
      NSString *uri = [s URL].description;
      if (uri == nil) continue;
        
       if (delegate) {
            if ([delegate respondsToSelector:@selector(mapView:shouldRestoreSource:)]) {
                _shouldRestoreClusters = [delegate mapView:self shouldRestoreSource:s];
                if (_shouldRestoreClusters == false) continue;
            }
        }

    }
        
        
       
    
    [self.sourcesToRestore removeAllObjects];
    
   
    for (MGLStyleLayer *l in self.layersToRestore) {
         SMLog(@"add layer: %@",l.identifier);
        [[self.map style] addLayer:l];
        
    }
   
    [self.layersToRestore removeAllObjects];
    
    
   
    
}

- (void)clearMapKeepAnnotations:(NSArray *)annotations {
   
    NSArray *array = [self.map annotations];
    if (!annotations) annotations = @[];
    
    NSMutableArray *toRemove = [NSMutableArray array];
    for (id annotation in array) {
        if ([annotations containsObject:annotation]) {
            continue;
        }
        [toRemove addObject:annotation];
    }
    
    [self.map removeAnnotations:toRemove];
    toRemove = nil;
    annotations = nil;
    array = nil;
    
   
    
    @synchronized (self.mapObjects) {
        for (SMapObject *object in self.mapObjects) {
            if ([object isKindOfClass:[SMapRoute class]]) {
                SMapRoute *r = (SMapRoute*)object;
                MGLSource *s = [r source];
                MGLStyleLayer *l = [r layer];
                MGLStyleLayer *stroke = [r strokeLayer];
                
                 [[self.map style] removeLayer:l];
                 [[self.map style] removeLayer:stroke];
                 [[self.map style] removeSource:s];
                
                [[self routes] removeObject:r];
                
                continue;
            }
            if ([object isKindOfClass:[SMapObject class]]) {
                // remove source and layers
                MGLSource *s = [object source];
                NSArray *layers = [object layers];
                
             
                
                for (MGLStyleLayer *l in layers) {
                    [[self.map style] removeLayer:l];
                }
                
                if (s) { [[self.map style] removeSource:s]; }
            }
            
        }
    }
    
    [self.mapObjects removeAllObjects];
    [self.routes removeAllObjects];
    
    NSArray *layers = [self.map.style layers];
    for (MGLStyleLayer *layer in layers) {
        NSString *rid = layer.identifier;
        if ([rid hasPrefix:@"rid"]) {
            // possible is route layer
            [self.map.style removeLayer:layer];
            
        }
        
        if ([rid hasPrefix:@"route_pin_direction"]) {
            // possible is route layer
            [self.map.style removeLayer:layer];
        }
        
        if ([rid hasPrefix:@"arrows"]) {
            // possible is route layer
            [self.map.style removeLayer:layer];
        }
        
        //clusteredPins
        if ([rid rangeOfString:@"clusters"].location != NSNotFound) {
            [self.map.style removeLayer:layer];
        }
        
        //clusteredPins
        if ([rid rangeOfString:@"clusteredPins"].location != NSNotFound) {
            [self.map.style removeLayer:layer];
        }
    }
    
    NSSet *sources = [self.map.style sources];
    self.selectedFeature = nil;
    
    for (MGLSource *s in sources.allObjects) {
        //   SMLog(@"clearMap: %@",s.identifier);
        NSString *rid = s.identifier;
        if ([rid hasPrefix:@"rid"]) {
            [self.map.style removeSource:s];
        }
        if ([rid hasPrefix:@"arrows"]) {
            [self.map.style removeSource:s];
        }
        //clusteredPins
        if ([rid rangeOfString:@"clusteredPins"].location != NSNotFound) {
            [self.map.style removeSource:s];
        }
    }
    
    
}


- (void)clearMap:(BOOL)keepSelected {
    NSArray *array = [self.map selectedAnnotations];
    
    [self clearMap];
    
    for (id <MGLAnnotation >a  in array) {
        if ([a class] == [MapMarker class]) {
            MapMarker *marker = a;
            if (marker.marker_type == MarkerTypeTemporary) continue;
            if (marker.marker_type == MarkerTypeRouteCenterPin) continue;
        }
        [[self markerManager] addMarker:a];
    }
}


- (void)clearMap {
   
    NSArray *array = [self.map annotations];
    [self.map removeAnnotations:array];
    
    
    @synchronized (self.mapObjects) {
        for (SMapObject *object in self.mapObjects) {
            if ([object isKindOfClass:[SMapRoute class]]) {
                    SMapRoute *r = (SMapRoute *) object;
                    MGLSource *sour = [r source];
                    MGLStyleLayer *la = r.layer;
                    MGLStyleLayer *la_stroke = r.strokeLayer;
                   
                    [[[self map] style] removeLayer:la];
                    [[[self map] style] removeLayer:la_stroke];
                    [[[self map] style] removeSource:sour];
                    
                    [self.routes removeObject:r];
               
                continue;
            }
            if ([object isKindOfClass:[SMapObject class]]) {
                // remove source and layers
                MGLSource *s = [object source];
                NSArray *layers = [object layers];
               
                for (MGLStyleLayer *l in layers) {
                    [[self.map style] removeLayer:l];
                }
                
                if (s) {  [[self.map style] removeSource:s]; }
            }
            
        }
    }
    
    
    [self.routes removeAllObjects];
    [self.mapObjects removeAllObjects];
    
    NSArray *layers = [self.map.style layers];
    for (MGLStyleLayer *layer in layers) {
         NSString *rid = layer.identifier;
        
         if ([rid hasPrefix:@"rid"]) {
             // possible is route layer
             [self.map.style removeLayer:layer];
             
         }
        
        if ([rid hasPrefix:@"arrows"]) {
            // possible is route layer
            [self.map.style removeLayer:layer];
            
        }
        
        if ([rid hasPrefix:@"route_pin_direction"]) {
            // possible is route layer
            [self.map.style removeLayer:layer];
            
        }
        
         //clusteredPins
         if ([rid rangeOfString:@"clusters"].location != NSNotFound) {
            [self.map.style removeLayer:layer];
         }
       
         //clusteredPins
         if ([rid rangeOfString:@"clusteredPins"].location != NSNotFound) {
            [self.map.style removeLayer:layer];
         }
    }
    
    NSSet *sources = [self.map.style sources];
    self.selectedFeature = nil;
    
    for (MGLSource *s in sources.allObjects) {
     //   SMLog(@"clearMap: %@",s.identifier);
        NSString *rid = s.identifier;
        if ([rid hasPrefix:@"rid"]) {
            [self.map.style removeSource:s];
        }
        
        if ([rid hasPrefix:@"arrows"]) {
            [self.map.style removeSource:s];
        }
        
        //clusteredPins
        if ([rid rangeOfString:@"clusteredPins"].location != NSNotFound) {
            [self.map.style removeSource:s];
        }
    }
}

// MARK: -
- (void)deselectAllRoutes {
    
    // find some route layers with id
    for (int i = 0 ; i < 5; i++) {
          
        if (i < self.routes.count) {
            SMapRoute *r = [self.routes objectAtIndex:i];
            if (r.canSelect == false) continue;
            
            [r setSelected:NO];
            
            MapMarker *m = [r marker];
            RouteAnnotationView *view = (RouteAnnotationView *)[self.map viewForAnnotation:m];
            [view setTintColor:[UIColor whiteColor]];
            [view setStyle:(RouteAnnotationViewStyleWhite)];
        }
    }
    
    
}

- (void)setRouteSelected:(BOOL )selected routeId:(NSString *)rid {
    
    [self deselectAllRoutes];
    
    SMapRoute  *ro = [self getRouteById:rid];
    if (ro) {
        [ro setSelected:selected];
        
        if (delegate && [delegate respondsToSelector:@selector(didSelectRoute:)]) { [delegate didSelectRoute:ro];  }
        
        NSString* route_id = [NSString stringWithFormat:@"rid_%@",rid];
        NSString* stroke_id = [NSString stringWithFormat:@"rid_stroke_%@",rid];
                 
        MGLLineStyleLayer *slayer = (MGLLineStyleLayer *)[[self.map style] layerWithIdentifier:stroke_id];
        MGLLineStyleLayer *layer = (MGLLineStyleLayer *)[[self.map style] layerWithIdentifier:route_id];
        
        
        if (layer && slayer) {
                  // move it to top
                     [[self.map style] removeLayer:slayer];
                     [[self.map style] removeLayer:layer];
                     
            MGLStyle *style = [self.map style];
            BOOL inserted = false;
            
            MGLStyleLayer *la = [style layerWithIdentifier:@"vector-highway-name-primary-copy"];
            if (la) {
                [style insertLayer:slayer belowLayer:la];
                [style insertLayer:layer belowLayer:la];
                inserted = true;
            } else {
                la = [style layerWithIdentifier:@"vector-highway-name-secondary"];
                
                if (la) {
                    [style insertLayer:slayer belowLayer:la];
                    [style insertLayer:layer belowLayer:la];
                    inserted = true;
                }
            }
            
            if (inserted == false) {
                [[self.map style] addLayer:slayer];
                [[self.map style] addLayer:layer];
            }
            
        } else {
                     SMLog(@"no route layer to select!!");
                 }
        
    }
}

- (void)selectRoute:(NSString *)rid {
    if (!rid) return;
    
    [self deselectAllRoutes];
    NSString *route_id;
    NSString *_id = [rid description];
    NSString *stroke_id;
    NSArray *components = [_id componentsSeparatedByString:@"_"];
    NSString *nr = components.lastObject;
    if (nr == nil) return;
    if (_id == nil) return;
    
    SMapRoute  *ro = [self getRouteById:rid];
    if (ro) {
        [ro setSelected:YES];
        
        route_id = [NSString stringWithFormat:@"rid_%@",nr];
        stroke_id = [NSString stringWithFormat:@"rid_stroke_%@",nr];
           
        MGLLineStyleLayer *slayer = (MGLLineStyleLayer *)[[self.map style] layerWithIdentifier:stroke_id];
        MGLLineStyleLayer *layer = (MGLLineStyleLayer *)[[self.map style] layerWithIdentifier:route_id];
        
        if (layer && slayer) {
            // move it to top
               [[self.map style] removeLayer:slayer];
               [[self.map style] removeLayer:layer];
               
               MGLStyle *style = [self.map style];
               BOOL inserted = false;
               
               MGLStyleLayer *la = [style layerWithIdentifier:@"vector-highway-name-primary-copy"];
               if (la) {
                   [style insertLayer:slayer belowLayer:la];
                   [style insertLayer:layer belowLayer:la];
                   inserted = true;
               } else {
                   la = [style layerWithIdentifier:@"vector-highway-name-secondary"];
                   
                   if (la) {
                       [style insertLayer:slayer belowLayer:la];
                       [style insertLayer:layer belowLayer:la];
                       inserted = true;
                   }
               }
               
               if (inserted == false) {
                   [[self.map style] addLayer:slayer];
                   [[self.map style] addLayer:layer];
               }
            
           } else {
               SMLog(@"no route layer to select!!");
           }
        if (delegate && [delegate respondsToSelector:@selector(didSelectRoute:)]) {
            [delegate didSelectRoute:ro];
        }
        
        return;
    }
    
    
    route_id = [NSString stringWithFormat:@"rid_%@",nr];
    stroke_id = [NSString stringWithFormat:@"rid_stroke_%@",nr];
    
    MGLLineStyleLayer *slayer = (MGLLineStyleLayer *)[[self.map style] layerWithIdentifier:stroke_id];
    //slayer.lineColor = [NSExpression expressionForConstantValue:[UIColor colorWithRed:0.65 green:0.65 blue:0.65 alpha:1]]; not selected
    slayer.lineColor = [NSExpression expressionForConstantValue:[UIColor colorWithRed:1 green:(80/255) blue:(14/255) alpha:1]];
    
    MGLLineStyleLayer *layer = (MGLLineStyleLayer *)[[self.map style] layerWithIdentifier:route_id];
    layer.lineColor = [NSExpression expressionForConstantValue:[UIColor colorWithRed:1 green:0.43 blue:0 alpha:1]];
   
    if (layer && slayer) {
        [[self.map style] removeLayer:slayer];
        [[self.map style] removeLayer:layer];
        
        MGLStyle *style = [self.map style];
        BOOL inserted = false;
        
        MGLStyleLayer *la = [style layerWithIdentifier:@"vector-highway-name-primary-copy"];
        if (la) {
            [style insertLayer:slayer belowLayer:la];
            [style insertLayer:layer belowLayer:la];
            inserted = true;
        } else {
            la = [style layerWithIdentifier:@"vector-highway-name-secondary"];
            
            if (la) {
                [style insertLayer:slayer belowLayer:la];
                [style insertLayer:layer belowLayer:la];
                inserted = true;
            }
        }
        
        if (inserted == false) {
            [[self.map style] addLayer:slayer];
            [[self.map style] addLayer:layer];
        }
        
        
    } else {
        SMLog(@"no route layer to select!!");
    }
    
  
    
    @synchronized (self.routes) {
        for (SMapRoute *r in self.routes) {
            
            MapMarker *m = [r marker];
            RouteAnnotationView *view = (RouteAnnotationView *)[[self map] viewForAnnotation: m];
            [view setTintColor:[UIColor whiteColor]];
            [view setStyle:(RouteAnnotationViewStyleWhite)];
            
            
            if ([r.routeId isEqual:nr]) {
                [r setSelected:YES];

                [view setTintColor:[UIColor colorWithRed:1.0 green:(114.0/255.0) blue:0 alpha:1.0]];
                [view setStyle:(RouteAnnotationViewStyleOrange)];
                
                if (delegate && [delegate respondsToSelector:@selector(didSelectRoute:)]) {
                    [delegate didSelectRoute:ro];
                }
                
            }
        }
    }
    
    
   
}

- (void)addNavigationRoutes:(NSArray *)routes {
   
    NSMutableArray *routeAnnotations = [NSMutableArray array];
    for (NSDictionary *routeInfo in routes) {
        
        SMapRoute *r = [[SMapRoute alloc] initWithRouteInfo:routeInfo];
        
        MapMarker *routePin = r.marker;
        
        [[self markerManager] addMarker:routePin];
        [routeAnnotations addObject:routePin];
       
        MGLShapeSource *source = r.source;
        MGLLineStyleLayer *layer = r.layer;
        MGLLineStyleLayer *layer_stroke = r.strokeLayer;
        
        [self.map.style addSource:source];
       
        SMapObject *object = [[SMapObject alloc] initWithUrl:[NSURL new]];
        object.source = source;
        
        [object addLayer:layer_stroke];
        [object addLayer:layer];
        [self addMapObject:object];
        
        BOOL inserted = false;
        
        MGLStyle *style = [self.map style];
        MGLStyleLayer *la = [style layerWithIdentifier:@"vector-highway-name-primary-copy"];
        if (la) {
            [style insertLayer:layer_stroke belowLayer:la];
            [style insertLayer:layer belowLayer:la];
            inserted = YES;
        } else {
            la = [style layerWithIdentifier:@"vector-highway-name-secondary"];
                   
            if (la) {
                [style insertLayer:layer_stroke belowLayer:la];
                [style insertLayer:layer belowLayer:la];
                inserted = YES;
            }
        }
        
        if (inserted == false) {
            [self.map.style addLayer:layer_stroke];
            [self.map.style addLayer:layer];
        }
        
        [self.routes addObject:r];

    }
    
    if (routes.count == 2) {
        SMapRoute *route1 = [self.routes objectAtIndex:0];
        SMapRoute *route2 = [self.routes objectAtIndex:1];
        
        NSArray *points1 = [route1 getPoints];
        NSArray *points2 = [route2 getPoints];
        
        NSDictionary *di = [SMapHelper maxDistanceFromTwooPointsOfRoutes:points1 second:points2];
        NSValue *v1 = [di objectForKey:@"1"];
        NSValue *v2 = [di objectForKey:@"2"];
        
        if (v1 && v2) {
            CLLocationCoordinate2D loc1 = [v1 MKCoordinateValue];
            CLLocationCoordinate2D loc2 = [v2 MKCoordinateValue];
            
            MapMarker *marker1 = [route1 marker];
            MapMarker *marker2 = [route2 marker];
            
            marker1.coordinate = loc1;
            marker2.coordinate = loc2;
            
            
        }
        
    }
    
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//
//        [self.map setSelectedAnnotations:routeAnnotations];
//    });
    
   
}

- (void)removeAllRoutes {
  
    NSInteger i = 0;
    NSInteger count = self.routes.count;
    
    for (i=0; i< count; i++ ) {
        SMapRoute *r = [[self routes] firstObject];
        NSString *rid = r.routeId;
        [self removeRoute:rid];
        [self.mapObjects removeObject:r];
    }
    
   
}

- (void)removeRoute:(NSString *)rid {
    if (!rid) return;
    NSRange r = [rid rangeOfString:@"rid"];
    if (r.location != NSNotFound) {
        NSArray *com = [rid componentsSeparatedByString:@"_"];
        NSString *nr = com.lastObject;
        NSString *stroke_id = [NSString stringWithFormat:@"rid_stroke_%@",nr];
        MGLLineStyleLayer *layer = (MGLLineStyleLayer *)[[self.map style] layerWithIdentifier:rid];
        if (layer) {
            [[self.map style] removeLayer:layer];
        }
        
        MGLLineStyleLayer *slayer = (MGLLineStyleLayer *)[[self.map style] layerWithIdentifier:stroke_id];
        if (slayer) {
            [[self.map style] removeLayer:slayer];
        }
    } else {
        NSString *routeid = [NSString stringWithFormat:@"rid_%@",rid];
        NSString *stroke_id = [NSString stringWithFormat:@"rid_stroke_%@",rid];
        MGLLineStyleLayer *layer = (MGLLineStyleLayer *)[[self.map style] layerWithIdentifier:stroke_id];
        if (layer) {
            [[self.map style] removeLayer:layer];
        }
        
        MGLLineStyleLayer *slayer = (MGLLineStyleLayer *)[[self.map style] layerWithIdentifier:routeid];
        if (slayer) {
            [[self.map style] removeLayer:slayer];
        }
    }
    
    NSInteger idx = -1;
    for (SMapRoute *r in self.routes) {
        if ([r.routeId isEqualToString:rid]) {
           idx = [self.routes indexOfObject:r];
        }
    }
    
    if (idx >= 0) {
        SMapRoute *r = [self.routes objectAtIndex:idx];
        [self.routes removeObjectAtIndex:idx];
        [self.mapObjects removeObject:r];
        // also remove pin
        MapMarker *marker = r.marker;
        [self.map removeAnnotation:marker];
        [self.map.style removeSource:r.source];
        
        r = nil;
        marker = nil;
    }
}

- (SMapRoute*)getRouteById:(NSString *)ID {
    SMapRoute *route = nil;
    for (SMapRoute *r in self.routes) {
        if ([[r routeId] isEqualToString:ID.description]) {
            route = r;
        }
    }
    return route;
}


- (void)addRoute:(NSDictionary *)routeInfo {
   
    SMapRoute *route = [[SMapRoute alloc] initWithRouteInfo:routeInfo];
    
    [self.map.style addSource:route.source];
    
    [self addMapObject:(id)route];
    
    BOOL inserted = false;
    MGLStyle *style = [self.map style];
    MGLStyleLayer *la = [style layerWithIdentifier:@"vector-highway-name-primary-copy"];
    if (la) {
        [style insertLayer:route.strokeLayer belowLayer:la];
        [style insertLayer:route.layer belowLayer:la];
        inserted = true;
    } else {
        la = [style layerWithIdentifier:@"vector-highway-name-secondary"];
        
        if (la) {
            [style insertLayer:route.strokeLayer belowLayer:la];
            [style insertLayer:route.layer belowLayer:la];
            inserted = true;
        }
    }
    
    if (inserted == false) {
        
        [self.map.style addLayer:route.strokeLayer];
        [self.map.style addLayer:route.layer];
    }
    
    
    [self.routes addObject:route];
}

- (void)zoomToRoute:(NSString *)rid edgePadding:(UIEdgeInsets)padding {
   
    SMapRoute *route = nil;
    for (SMapRoute *r in self.routes) {
        if ([[r routeId] isEqualToString:rid.description]) {
            route = r;
        }
    }
    
    if (route == nil) return;
    NSArray *points = [route getPoints];
    NSInteger numberOfSteps = 4;
    CLLocationCoordinate2D coordinates[numberOfSteps];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    double maxLat = 0;
    double maxLon = 0;
    double minLat = 99;
    double minLon = 99;
    
    
    for (NSArray *point in  points)
    {
        double lat = [point.lastObject doubleValue];
        double lon = [point.firstObject doubleValue];
        
        CLLocationCoordinate2D lo = CLLocationCoordinate2DMake(lat, lon);
        
        if (lat < minLat) {
            // set min lat
            dict[@"minLat"] = [NSValue valueWithMKCoordinate:lo];
            minLat = lat;
        }
        
        if (lat > maxLat) {
            // set max lat
            dict[@"maxLat"] = [NSValue valueWithMKCoordinate:lo];
            maxLat = lat;
        }
        
        if (lon < minLon) {
            // set minLon
            dict[@"minLon"] = [NSValue valueWithMKCoordinate:lo];
            minLon = lon;
        }
        
        if (lon > maxLon) {
            // set maxLon
            dict[@"maxLon"] = [NSValue valueWithMKCoordinate:lo];
            maxLon = lon;
        }
        
    }
    
    NSValue *c1 = [dict objectForKey:@"minLat"];
    NSValue *c2 = [dict objectForKey:@"maxLat"];
    NSValue *c3 = [dict objectForKey:@"minLon"];
    NSValue *c4 = [dict objectForKey:@"maxLon"];
    
    
    coordinates[0] = [c1 MKCoordinateValue];
    coordinates[1] = [c2 MKCoordinateValue];
    coordinates[2] = [c3 MKCoordinateValue];
    coordinates[3] = [c4 MKCoordinateValue];
    
    
    [self.map setVisibleCoordinates:coordinates count:numberOfSteps edgePadding:padding animated:YES];
   
}

// MARK: - logo

- (void)setLogoPosition:(MapLogoPosition)position {
    
    if (!_logo) { return; }
    
    self.logo_position = position;
    UIImage *image = [_logo currentImage];
    if (!image) {
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        NSString *file = [bundle pathForResource:@"map_logo_apps" ofType:@"svg"];
        SMLog(@"$svg : %@",file);
        
        SVGKImage *i = [SVGKImage imageWithContentsOfFile:file];
        image = [i UIImage];
        [_logo setImage:image forState:(UIControlStateNormal)];
    }
    NSArray *co = [self constraints];
    for (NSLayoutConstraint *c in co) {
        if (c.firstItem == _logo) {
            [self removeConstraint:c];
        }
    }
    
    NSLayoutConstraint *hei = [NSLayoutConstraint constraintWithItem:_logo attribute:(NSLayoutAttributeHeight) relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:image.size.height];
    NSLayoutConstraint *wi = [NSLayoutConstraint constraintWithItem:_logo attribute:(NSLayoutAttributeWidth) relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:image.size.width];
    
    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObject:hei];
    [constraints addObject:wi];
    
    switch (position) {
        case MapLogoPositionTopLeft: {
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:29]];
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:10]];
            
            break;
        }
            
        case MapLogoPositionTopRight: {
           
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:10]];
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:-10]];

            break;
        }
       
        case MapLogoPositionBottomLeft: {
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:10]];
            
            break;
        }
            
        case MapLogoPositionBottomRight: {
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:-10]];
            
            break;
        }
            
        default: {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:10]];
            
            break;
            
        }
    }
    
    
    [self addConstraints:constraints];
    [NSLayoutConstraint activateConstraints:constraints];
    [self setNeedsLayout];
}

- (void)openMapmd {
    NSURL *uri = [NSURL URLWithString:@"https://map.md"];
   
    if (@available (iOS 10, *)) {
        [[UIApplication sharedApplication] openURL:uri options:@{} completionHandler:^(BOOL success) {
       SMLog(@"open uri mapmd %i",success);
    }];
    } else {
        // old iOS
        [[UIApplication sharedApplication] openURL:uri];
    }
}

- (void)showLogo {
    if (_logo) {
        [_logo setHidden:NO];
    } else {
        
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        NSString *file = [bundle pathForResource:@"map_logo_apps" ofType:@"svg"];
        
        // SMLog(@"$svg : %@",file);
        SVGKImage *image = [SVGKImage imageWithContentsOfFile:file];
        SMLog(@"%s",__func__);
        SMLog(@"%@",image);
        
        _logo = [[UIButton alloc] init];
        [_logo setBackgroundColor:[UIColor clearColor]];
        [_logo setImage:image.UIImage forState:(UIControlStateNormal)];
        
        _logo.translatesAutoresizingMaskIntoConstraints = NO;
        [_logo addTarget:self action:@selector(openMapmd) forControlEvents:(UIControlEventTouchUpInside)];
        [self addSubview:_logo];
        
        NSLayoutConstraint *hei = [NSLayoutConstraint constraintWithItem:_logo attribute:(NSLayoutAttributeHeight) relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:image.size.height];
        NSLayoutConstraint *wi = [NSLayoutConstraint constraintWithItem:_logo attribute:(NSLayoutAttributeWidth) relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:image.size.width];
        
        
        
        NSMutableArray *constraints = [NSMutableArray array];
        
        [constraints addObject:wi];
        [constraints addObject:hei];
        
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:(-_logo.frame.size.height - 10)]];
        
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:-16]];
        
        [self addConstraints:constraints];
        
        image = nil;
        
    }
}

- (void)hideLogo {
    if (_logo) {
        [_logo setHidden:YES];
    }
}


- (void)buildLogo {
   
    NSString *mainBundle = [NSBundle mainBundle].bundleIdentifier;
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSString *file = [bundle pathForResource:@"map_logo_apps" ofType:@"svg"];
   
    if ([mainBundle rangeOfString:@"md.simpals"].location != NSNotFound) return;
    if (!file) {
      file = [[NSBundle mainBundle] pathForResource:@"map_logo_apps" ofType:@"svg"];
    }
    if (!file) {return;}
  
   // SMLog(@"$svg : %@",file);
    SVGKImage *image = [SVGKImage imageWithContentsOfFile:file];
    SMLog(@"%s",__func__);
    SMLog(@"%@",image);
    
    _logo = [[UIButton alloc] init];
    [_logo setBackgroundColor:[UIColor clearColor]];
    [_logo setImage:image.UIImage forState:(UIControlStateNormal)];
    
    _logo.translatesAutoresizingMaskIntoConstraints = NO;
    [_logo addTarget:self action:@selector(openMapmd) forControlEvents:(UIControlEventTouchUpInside)];
    [self addSubview:_logo];
    
    NSLayoutConstraint *hei = [NSLayoutConstraint constraintWithItem:_logo attribute:(NSLayoutAttributeHeight) relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:image.size.height];
    NSLayoutConstraint *wi = [NSLayoutConstraint constraintWithItem:_logo attribute:(NSLayoutAttributeWidth) relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:image.size.width];
    
    
    
    NSMutableArray *constraints = [NSMutableArray array];
    
    [constraints addObject:wi];
    [constraints addObject:hei];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-9]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_logo attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:9]];
    
    [self addConstraints:constraints];
    
    image = nil;
}
// MARK: -

// MARK: - MapViewDelegate
- (void)mapView:(MGLMapView *)mapView didUpdateUserLocation:(nullable MGLUserLocation *)userLocation {
    if (userLocation) {
         [[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateUserLocation" object:userLocation.location];
        if (self.mapMode == MapViewModeDrive) {
            UIView *view = [mapView viewForAnnotation:userLocation];
            if (view) {
                view.tintColor = [UIColor orangeColor];
            }
        }
    }
    MGLMapCamera *camera = [mapView camera];
    SMLog(@"%f zoom: %f",camera.pitch, mapView.zoomLevel);
    
}

- (void)mapView:(MGLMapView *)mapView didFinishLoadingStyle:(MGLStyle *)style {
    // setup gesture recognizer
    SMLog(@"%s",__func__);
    if (self.tapGestureRecognizer == nil) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMapTap:)];
        tap.delegate = (id)self;
        tap.numberOfTouchesRequired = 1;
        tap.numberOfTapsRequired = 1;
        
        self.tapGestureRecognizer = tap;
        
        for (UIGestureRecognizer *recognizer in self.map.gestureRecognizers) {
            if ([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
                [tap requireGestureRecognizerToFail:recognizer];
            }
        }
        [self.map addGestureRecognizer:tap];
    }
   
    self.tapGestureRecognizer.enabled = true;
    
    [self performSelectorOnMainThread:@selector(restoreSource:) withObject:nil waitUntilDone:false];
   
}

- (BOOL)mapView:(MGLMapView *)mapView shouldChangeFromCamera:(MGLMapCamera *)oldCamera toCamera:(MGLMapCamera *)newCamera {
    
    CLLocationCoordinate2D ne = CLLocationCoordinate2DMake(49, 33.84); //
    CLLocationCoordinate2D sw = CLLocationCoordinate2DMake(43.0, 24.0); //
    
    MGLCoordinateBounds inside = MGLCoordinateBoundsMake(sw, ne);
    MGLMapCamera *current = mapView.camera;
    CLLocationCoordinate2D newCameraCenter = newCamera.centerCoordinate;
    
    // Set the map’s visible bounds to newCamera.
    mapView.camera = newCamera;
   
    MGLCoordinateBounds  newVisibleCoordinates = mapView.visibleCoordinateBounds;
   
    // Revert the camera.
    mapView.camera = current;
    
    // Test if the newCameraCenter and newVisibleCoordinates are inside Global map bounds.
    bool ins = MGLCoordinateInCoordinateBounds(newCameraCenter, inside);
    bool intersects = MGLCoordinateInCoordinateBounds( newVisibleCoordinates.ne, inside) && MGLCoordinateInCoordinateBounds( newVisibleCoordinates.sw, inside);
    
    
    return ins && intersects;
}

- (MGLAnnotationImage *)mapView:(MGLMapView *)mapView viewForAnnotation:(id <MGLAnnotation>)annotation {
    
    if ([annotation class] == [MGLUserLocation class]) {
        SMLog(@"%s",__func__);
        return nil;
    }
    
    if ([annotation class] == [MapMarker class]) {
        MapMarker *marker = annotation;
        
        if (marker.marker_type == MarkerTypePolylinePin) {
            // part of poly line
          
            UIImage *image = marker.image;
            if (!image) image = [UIImage imageNamed:@"pin"];
            
            MarkerAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"poly_pin"];
            if (!annotationView) {
                annotationView = [[MarkerAnnotationView alloc] initWithAnnotation:marker reuseIdentifier:@"poly_pin"];
            }
            
            annotationView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
            annotationView.backgroundColor = [UIColor colorWithPatternImage:image];
            
            return (id)annotationView;
        }
        
        
        MarkerAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
       
        
        if (!annotationView) {
           
            annotationView = [[MarkerAnnotationView alloc] initWithReuseIdentifier:@"pin"];
            UIImage *image = [UIImage imageNamed:@"pin"];
            
            annotationView.frame = CGRectMake(0, 0, 31, 31);
            annotationView.backgroundColor = [UIColor colorWithPatternImage:image];
            
           
        }
        
        if (marker.marker_type == MarkerTypeGroup) {
            
            annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"group-pin"];
           
            if (!annotationView) {
                annotationView = [[MarkerAnnotationView alloc] initWithAnnotation:marker reuseIdentifier:@"group-pin"];
            }
            
            annotationView.annotation = annotation;
            [annotationView prepareForReuse];
           
            return (id)annotationView;
        }
        
        if (marker.marker_type == MarkerTypeRouteStartPin) {
            MarkerAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"start-pin"];
            UIImage *image = marker.image;
            if (!image) image = [UIImage imageNamed:@"pin"];
            if (!annotationView) {
                
                annotationView = [[MarkerAnnotationView alloc] initWithReuseIdentifier:@"start-pin"];
                
                
                annotationView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
                annotationView.backgroundColor = [UIColor colorWithPatternImage:image];
                annotationView.centerOffset = CGVectorMake(0, -image.size.height/2.0);
                
            }
            return (id)annotationView;
        }
        
        if (marker.marker_type == MarkerTypeDefault) {
            
            MarkerAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"pin-default"];
            if (!annotationView) {
                annotationView = [[MarkerAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin-default"];
            }
            annotationView.backgroundColor = [UIColor clearColor];
            [annotationView setSelected:NO];
            
            if (marker.image) {
                CGSize size = marker.image.size;
                if (CGSizeEqualToSize(size, CGSizeZero)) {
                    size =  CGSizeMake( 1, 1);
                }
                annotationView.frame = CGRectMake(0, 0, size.width, size.height);
                annotationView.backgroundColor = [UIColor colorWithPatternImage:marker.image];
                
                UIImage *selectedImage = [marker selectedImage];
                
                if (marker.isSelected) {
                    CGSize size = selectedImage.size;
                    annotationView.frame = CGRectMake(0, 0, size.width, size.height);
                    annotationView.backgroundColor = [UIColor colorWithPatternImage:selectedImage];
                }
                
            }
            
            return (id)annotationView;
        }
        
        if (marker.marker_type == MarkerTypeRouteCenterPin) {
           
            RouteAnnotationView *rAnnotationView = [[RouteAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"rid"];
            rAnnotationView.backgroundColor = [UIColor clearColor];
            marker.canShowCallout = NO;
            
            [rAnnotationView setTitle:marker.title];
            
            return (id)rAnnotationView;
        }
        
        UIImage *image = [marker image];
        UIImage *selectedImage = [marker selectedImage];
        
        if (marker.marker_type == MarkerTypePin) {
            
            if (marker.isSelected && selectedImage) {
                annotationView.frame = CGRectMake(0, 0, selectedImage.size.width, selectedImage.size.height);
                annotationView.backgroundColor = [UIColor colorWithPatternImage:selectedImage];
                 [annotationView setSelected:YES];
            } else {
                
                [annotationView setSelected:NO];
             
                if (image) {
                    annotationView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
                    annotationView.backgroundColor = [UIColor colorWithPatternImage:image];
                }
            }
            
            return (id)annotationView;
        }
        
        if ( marker.marker_type == MarkerTypeDroppedPin) {
            
            MarkerAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"MarkerTypeDroppedPin"];
            if (!annotationView) {
                annotationView = [[MarkerAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MarkerTypeDroppedPin"];
            }
            
            [annotationView setSelected:NO];
        
            annotationView.backgroundColor = [UIColor clearColor];
            
            
            if (marker.isSelected && selectedImage) {
                annotationView.frame = CGRectMake(0, 0, selectedImage.size.width, selectedImage.size.height);
                annotationView.backgroundColor = [UIColor colorWithPatternImage:selectedImage];
                [annotationView setSelected:YES];
            } else {
                if (image) {
                    annotationView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
                    annotationView.backgroundColor = [UIColor colorWithPatternImage:image];
                }
            }
            
            return (id)annotationView;
        }
        
        
        
        if (image && marker.isSelected == false) {
            annotationView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
            annotationView.backgroundColor = [UIColor colorWithPatternImage:image];
        }
        
        
        
        return (id)annotationView;
    }
    
    SMLog(@"$viewForAnnotation %@ return nil", annotation);
    
    return nil;
}

- (BOOL)mapView:(MGLMapView *)mapView shapeAnnotationIsEnabled:(MGLShape *)annotation {
    
    if ([annotation class] == [MapPolygon class]) {
        MapPolygon *poly = (id)annotation;
        return poly.selectable;
    }
    
    return YES;
}

// Allow callout view to appear when an annotation is tapped.
- (BOOL)mapView:(MGLMapView *)mapView annotationCanShowCallout:(id <MGLAnnotation>)annotation {
  
    if ([annotation class] == [MapMarker class]) {
        MapMarker *marker = annotation;
        return marker.canShowCallout;
    }
    
    if ([annotation class] == [MapPolygon class]) {
       
        MapPolygon *poly = (id)annotation;
        MapMarker *m = [poly centerPin];
        [mapView selectAnnotation:m animated:false];
        
        return false;
    }
    
    NSNumber *can = [[NSUserDefaults standardUserDefaults] objectForKey:@"AnnotationsCanShowCallout"];
    if (can != nil) {
        if ([can respondsToSelector:@selector(boolValue)]) { return can.boolValue; }
    }
    
    return YES;
}

- (UIView<MGLCalloutView> *)mapView:(__unused MGLMapView *)mapView calloutViewForAnnotation:(id<MGLAnnotation>)annotation
{
    
    if ([annotation class] == [MapMarker class]) {
        MapMarker *marker = annotation;
        if (marker.canShowCallout)
           if (marker.calloutView)
             return marker.calloutView;
        
        if (delegate && [delegate respondsToSelector:@selector(calloutViewForAnnotation:)]) {
            UIView <MGLCalloutView >*view = [delegate calloutViewForAnnotation:marker];
            return view;
        }
        
        
    }
    
    if ([annotation class] == [MapPolygon class]) {
       
        if (delegate && [delegate respondsToSelector:@selector(calloutViewForAnnotation:)]) {
            UIView <MGLCalloutView >*view = [delegate calloutViewForAnnotation:annotation];
            return view;
        }
    }
    
    
    
    return nil;
}




- (void)mapView:(MGLMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    if (self.longPressGestureRecognizer) {
        UIGestureRecognizer *gs = self.longPressGestureRecognizer;
        if (gs.state == UIGestureRecognizerStatePossible || gs.state == UIGestureRecognizerStateBegan) {
            [gs setEnabled:NO];
            [gs setEnabled:YES];
        }
    }
    
    
}

- (void)mapView:(MGLMapView *)mapView regionDidChangeWithReason:(MGLCameraChangeReason)reason animated:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"regionDidChangeWithReason" object:[NSNumber numberWithUnsignedInteger:reason]];
    
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(regionDidChange:)]) {
            [self.delegate regionDidChange:[NSNumber numberWithUnsignedInteger:reason]];
        }}
    
    switch (reason) {
        case MGLCameraChangeReasonNone:
            SMLog(@"MGLCameraChangeReasonNone");
            break;
        case MGLCameraChangeReasonProgrammatic:
            SMLog(@"MGLCameraChangeReasonProgrammatic");
            break;
        case MGLCameraChangeReasonGesturePan:
            SMLog(@"MGLCameraChangeReasonGesturePan");
            break;
        case MGLCameraChangeReasonGesturePinch:
            SMLog(@"MGLCameraChangeReasonGesturePinch");
            break;
        case MGLCameraChangeReasonGestureZoomIn:
            SMLog(@"MGLCameraChangeReasonGestureZoomIn");
            break;
        case MGLCameraChangeReasonGestureZoomOut:
            SMLog(@"MGLCameraChangeReasonGestureZoomOut");
            break;
        case MGLCameraChangeReasonTransitionCancelled:
            SMLog(@"MGLCameraChangeReasonTransitionCancelled");
            break;
        case MGLCameraChangeReasonGestureTilt:
            SMLog(@"MGLCameraChangeReasonGestureTilt");
            break;
         case MGLCameraChangeReasonGestureRotate:
            SMLog(@"MGLCameraChangeReasonGestureRotate");
            break;
         case MGLCameraChangeReasonGestureOneFingerZoom:
            SMLog(@"MGLCameraChangeReasonGestureOneFingerZoom");
            break;
        default:
            break;
    } SMLog(@"");
    
}

- (void)mapView:(MGLMapView *)mapView regionWillChangeWithReason:(MGLCameraChangeReason)reason animated:(BOOL)animated {
    
    switch (reason) {
        case MGLCameraChangeReasonNone:
            SMLog(@"MGLCameraChangeReasonNone");
            break;
        case MGLCameraChangeReasonProgrammatic:
            SMLog(@"MGLCameraChangeReasonProgrammatic");
            break;
        case MGLCameraChangeReasonGesturePan:
            SMLog(@"MGLCameraChangeReasonGesturePan");
            break;
        case MGLCameraChangeReasonGesturePinch:
            SMLog(@"MGLCameraChangeReasonGesturePinch");
            break;
        case MGLCameraChangeReasonGestureZoomIn:
            SMLog(@"MGLCameraChangeReasonGestureZoomIn");
            break;
        case MGLCameraChangeReasonGestureZoomOut:
            SMLog(@"MGLCameraChangeReasonGestureZoomOut");
            break;
        case MGLCameraChangeReasonTransitionCancelled:
            SMLog(@"MGLCameraChangeReasonTransitionCancelled");
            break;
        default:
            break;
    } SMLog(@"");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"regionWillChangeWithReason" object:[NSNumber numberWithUnsignedInteger:reason]];
    
    
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(regionWillChange:)]) {
            [self.delegate regionWillChange:[NSNumber numberWithUnsignedInteger:reason]];
        }}
    
    /*
     MGLCameraChangeReasonNone = 0,
     
     /// :nodoc: Set when a public API that moves the camera is called. This may be set for some gestures,
     /// for example MGLCameraChangeReasonResetNorth.
     MGLCameraChangeReasonProgrammatic = 1 << 0,
     
     /// :nodoc: The user tapped the compass to reset the map orientation so North is up.
     MGLCameraChangeReasonResetNorth = 1 << 1,
     
     /// :nodoc: The user panned the map.
     MGLCameraChangeReasonGesturePan = 1 << 2,
     
     /// :nodoc: The user pinched to zoom in/out.
     MGLCameraChangeReasonGesturePinch = 1 << 3,
     
     // :nodoc: The user rotated the map.
     MGLCameraChangeReasonGestureRotate = 1 << 4,
     
     /// :nodoc: The user zoomed the map in (one finger double tap).
     MGLCameraChangeReasonGestureZoomIn = 1 << 5,
     
     /// :nodoc: The user zoomed the map out (two finger single tap).
     MGLCameraChangeReasonGestureZoomOut = 1 << 6,
     
     /// :nodoc: The user long pressed on the map for a quick zoom (single tap, then long press and drag up/down).
     MGLCameraChangeReasonGestureOneFingerZoom = 1 << 7,
     
     // :nodoc: The user panned with two fingers to tilt the map (two finger drag).
     MGLCameraChangeReasonGestureTilt = 1 << 8,
     
     // :nodoc: Cancelled
     MGLCameraChangeReasonTransitionCancelled = 1 << 16

     */
    
}

- (void)mapView:(MGLMapView *)mapView didChangeUserTrackingMode:(MGLUserTrackingMode)mode animated:(BOOL)animated {
    //didChangeUserTrackingMode
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didChangeUserTrackingMode" object:[NSNumber numberWithInteger:mode]];
}

- (void)mapView:(MGLMapView *)mapView didSelectAnnotation:(id <MGLAnnotation>)annotation {
    SMLog(@"%@",annotation);
    if ([annotation class] == [MapMarker class]) {
        MapMarker *m = annotation;
        if (m.selectable) {
            m.isSelected = true;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didSelectAnnotation" object:annotation];
      
        
        if (self.delegate) {
            if ([self.delegate respondsToSelector:@selector(didSelectAnnotation:)]) {
                [self.delegate didSelectAnnotation:annotation];
            }}
        
        return;
    }
    
    
    
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(didSelectAnnotation:)]) {
            [self.delegate didSelectAnnotation:annotation];
        }}
    
}


- (void)mapView:(MGLMapView *)mapView didDeselectAnnotation:(id<MGLAnnotation>)annotation {
    if ([annotation class] == [MapMarker class]) {
        
        SMLog(@"deselect %@",annotation);
        
        MapMarker *m = annotation;
        if (m.selectable) {
            m.isSelected = false;
        }
        
        if (m.marker_type == MarkerTypeRouteCenterPin) {
            SMLog(@"deselect MarkerTypeRouteCenterPin");
        }
        
            
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didDeselectAnnotation" object:annotation];
        
        
        
        if (m.marker_type == MarkerTypeTemporary) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [mapView removeAnnotation:m];
            });
        }
    }
    
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(didDeselectAnnotation:)]) {
            [self.delegate didDeselectAnnotation:annotation];
        }}
    
    
    if ([annotation class] == [MGLUserLocation class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didDeselectAnnotation" object:@"UserLocation"];
    }
    
}

- (CGPoint)mapViewUserLocationAnchorPoint:(MGLMapView *)mapView {
    
    if (self.mapMode == MapViewModeDrive) {
        return CGPointMake(self.bounds.size.width / 2, self.bounds.size.height - 200);
    }
    
    return CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

// MARK: Polygon



- (CGFloat)mapView:(MGLMapView *)mapView lineWidthForPolylineAnnotation:(MGLPolyline *)annotation {
    
    return 4.0;
}

- (UIColor *)mapView:(MGLMapView *)mapView strokeColorForShapeAnnotation:(MGLShape *)annotation {
    
    if ([annotation class] == [MapPolygon class]) {
        MapPolygon *poly = (id)annotation;
        if (poly.strokeColor) {
            return poly.strokeColor;
        }
    }
    
    
    return [UIColor colorWithRed:1 green:(114.0/255.0) blue:0 alpha:1];
    
}

- (UIColor *)mapView:(MGLMapView *)mapView fillColorForPolygonAnnotation:(MGLPolygon *)annotation {
    
    if ([annotation class] == [MapPolygon class]) {
        MapPolygon *poly = (id)annotation;
        if (poly.fillColor) {
            return poly.fillColor;
        }
    }
    
    
    return [UIColor clearColor];
}


//A `CGPoint` indicating the position offset of the compass.
- (void)setCompassOffset:(CGPoint)offset {
    self.map.compassViewMargins = offset;
}

// MARK: - Other
- (void)dealloc {
    
    self.mapObjects = nil;
    self.layersToRestore = nil;
    self.sourcesToRestore = nil;
    
    NSLog(@"MapView was deallocated");
}

@end
