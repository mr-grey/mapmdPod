//
//  RouteCalloutView.m
//  mapmd
//
//  Created by user on 5/8/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import "RouteCalloutView.h"
#import "MapMarker.h"

@implementation RouteCalloutView

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (instancetype)init {
    
    self = [super initWithFrame:CGRectMake(0, 0, 70, 40)];
    self.dismissesAutomatically = NO;
    
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 2, 60, 20)];
    titleLabel.text = @"124";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.backgroundColor = [UIColor clearColor];
    UIFont *font = [UIFont systemFontOfSize:15 weight:(UIFontWeightSemibold)];
    
    if (font)
        titleLabel.font = font;
    
 
    
    CGSize titleSize = [titleLabel sizeThatFits:CGSizeMake(100, 20)];
    titleLabel.frame = CGRectMake(20, 2, titleSize.width, 20);
    
    backgroundView = [[RouteCalloutBackgroundView alloc] initWithFrame:CGRectMake(45, -45, titleSize.width +32 , 40)];
    backgroundView.backgroundColor = [UIColor clearColor];
    [backgroundView addSubview:titleLabel];
    
    [self addSubview:backgroundView];
    self.backgroundColor = [UIColor blueColor];
    
    
    return self;
}

- (void)setTitle:(NSString*)text {
    
    titleLabel.text = text;
    CGSize titleSize = [titleLabel sizeThatFits:CGSizeMake(100, 20)];
    titleLabel.frame = CGRectMake(20, 2, titleSize.width, 20);
    backgroundView.frame = CGRectMake(45, -45, titleSize.width +32 , 40);
    
    CGPoint c = self.center;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, titleSize.width +32, 40);
    self.center = c;
}


- (void)setRepresentedObject:(id)object {
    self.marker = object;
    
    if (self.marker) {
        [self setTitle:self.marker.title];
    }
    
}

- (void)presentCalloutFromRect:(CGRect)rect inView:(UIView *)view constrainedToRect:(CGRect)constrainedRect animated:(BOOL)animated {
    [view addSubview:self];
    self.frame = CGRectMake(rect.origin.x, rect.origin.y, self.frame.size.width, self.frame.size.height);
}

- (id)representedObject {
    return self.marker;
}

- (void)dismissCalloutAnimated:(BOOL)animated {
    self.hidden = true;
}

@synthesize leftAccessoryView;

@synthesize representedObject;

@synthesize rightAccessoryView;

@end



@implementation RouteCalloutBackgroundView

@synthesize fillColor;
@synthesize strokeColor;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    self.layer.shadowOpacity = .22;
    self.layer.shadowRadius = 4;
    self.layer.shadowOffset = CGSizeMake(4, 4);
    
    self.backgroundColor = [UIColor clearColor];
    
    fillColor = [UIColor colorWithRed:1.0 green:(114.0/255.0) blue:0 alpha:1.0];
    strokeColor = [UIColor colorWithRed:(245.0/255.0) green:(240.0/255.0) blue:(228.0/255.0) alpha:1.0];
    
    return self;
}

- (void)setTintColor:(UIColor *)tintColor {
    
}

- (void)layoutSubviews {
  
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    self.clipsToBounds = NO;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGMutablePathRef path = CGPathCreateMutable();
    
    
    rect = CGRectMake(rect.origin.x + 10, rect.origin.y, rect.size.width - 10, rect.size.height - 10);
    
    
    CGFloat radius = 4;
    
    
    
    CGContextSetFillColorWithColor(context, fillColor.CGColor);
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    CGContextSetLineWidth(context, 1);
    CGPoint topLeft = CGPointMake(rect.origin.x, rect.origin.y);
    CGPoint topRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
    CGPoint bottomRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    CGPoint bottomLeft = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
    
    CGFloat bottom = rect.size.height - 5;
    
    
    // move to top left
    CGPathMoveToPoint(path, NULL, topLeft.x + radius, topLeft.y);
    
    // add top line
    CGPathAddLineToPoint(path, NULL, topRight.x - radius, topRight.y);
    
    // add top right curve
    CGPathAddQuadCurveToPoint(path, NULL, topRight.x, topRight.y, topRight.x, topRight.y + radius);
    
    // add right line
    CGPathAddLineToPoint(path, NULL, bottomRight.x, bottom - radius);
    
    // add bottom right curve
    CGPathAddQuadCurveToPoint(path, NULL, bottomRight.x, bottom, bottomRight.x - radius, bottom);
    
    // add arrow
    CGPathAddLineToPoint(path, NULL, bottomLeft.x +4, bottom);
    CGPathAddLineToPoint(path, NULL, bottomLeft.x - 10 ,bottom + 10);
    CGPathAddLineToPoint(path, NULL, bottomLeft.x, bottom-8);
    // arrow
    
    
    
    // add left line
    CGPathAddLineToPoint(path, NULL, topLeft.x, topLeft.y + radius);
    
    // add top left curve
    CGPathAddQuadCurveToPoint(path, NULL, topLeft.x, topLeft.y, topLeft.x + radius, topLeft.y);
    
    CGPathCloseSubpath(path);
    
    CGPathRef path2  = CGPathCreateCopy(path);
    
    CGContextAddPath(context, path);
    
    CGContextFillPath(context);
    
    CGContextAddPath(context, path2);
    CGContextStrokePath(context);
    
    
    
    
    
}

@end
