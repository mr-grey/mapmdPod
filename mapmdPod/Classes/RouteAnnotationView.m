//
//  RouteAnnotationView.m
//  mapmd
//
//  Created by user on 5/8/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import "RouteAnnotationView.h"
#import "RouteCalloutView.h"

@interface RouteAnnotationView ()
@property (nonatomic, strong) RouteCalloutBackgroundView *backgroundView;
@property (nonatomic, strong) UILabel *titleLabel;
@end


@implementation RouteAnnotationView
@synthesize coordinate;
@synthesize title;
@synthesize tintColor;
@synthesize canSelect;
@synthesize canDeselect;

- (instancetype)initWithAnnotation:(id<MGLAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    
    
    self.frame = CGRectMake(20, 2, 2, 2);
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 2, 60, 20)];
    self.titleLabel.text = @"124";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    UIFont *font = [UIFont systemFontOfSize:15 weight:(UIFontWeightSemibold)];
    
    if (font)
        self.titleLabel.font = font;
    
    tintColor = [UIColor colorWithRed:1 green:(114.0/255.0) blue:0 alpha:1.0];
    
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeMake(100, 20)];
    self.titleLabel.frame = CGRectMake(20, 2, titleSize.width, 20);
    
    self.backgroundView = [[RouteCalloutBackgroundView alloc] initWithFrame:CGRectMake(0, 0, titleSize.width +32 , 40)];
    self.backgroundView.backgroundColor = [UIColor clearColor];
    [self.backgroundView addSubview:self.titleLabel];
    
    [self addSubview:self.backgroundView];
    self.backgroundColor = [UIColor clearColor];
    return self;
}


- (instancetype)init {
    
    self = [super initWithFrame:CGRectMake(20, 2, 2, 2)];
    
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 2, 60, 20)];
    self.titleLabel.text = @"124";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    UIFont *font = [UIFont systemFontOfSize:15 weight:(UIFontWeightSemibold)];
    
    if (font)
        self.titleLabel.font = font;
    
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeMake(100, 20)];
    self.titleLabel.frame = CGRectMake(20, 2, titleSize.width, 20);
    
    self.backgroundView = [[RouteCalloutBackgroundView alloc] initWithFrame:CGRectMake(0, 0, titleSize.width +32 , 40)];
    self.backgroundView.backgroundColor = [UIColor clearColor];
    
    [self.backgroundView addSubview:self.titleLabel];
    
    [self addSubview:self.backgroundView];
    self.backgroundColor = [UIColor clearColor];
   
    tintColor = [UIColor colorWithRed:1 green:(114.0/255.0) blue:0 alpha:1.0];
    
    
    return self;
}

- (void)setStyle:(RouteAnnotationViewStyle)st {
    _style = st;
    if (st == RouteAnnotationViewStyleOrange) {
        self.backgroundView.fillColor = tintColor;
        self.titleLabel.textColor = [UIColor whiteColor];
        tintColor = [UIColor colorWithRed:1 green:(114.0/255.0) blue:0 alpha:1.0];
      
        self.backgroundView.strokeColor = tintColor;
        self.backgroundView.fillColor = [UIColor colorWithRed:1.0 green:(114.0/255.0) blue:0 alpha:1.0];
        self.backgroundView.strokeColor = [UIColor colorWithRed:(245.0/255.0) green:(240.0/255.0) blue:(228.0/255.0) alpha:1.0];
    }
    
    if (st == RouteAnnotationViewStyleWhite) {
        self.backgroundView.fillColor = [UIColor whiteColor];
        tintColor = [UIColor whiteColor];
        self.titleLabel.textColor = [UIColor colorWithRed:1 green:(114.0/255.0) blue:0 alpha:1.0];
        self.backgroundView.strokeColor = [UIColor whiteColor];
        self.backgroundView.fillColor = [UIColor whiteColor];
    }
    [self.backgroundView setNeedsDisplay];
    [self setNeedsDisplay];
}

- (void)setTitle:(NSString*)text {
    
    self.titleLabel.text = text;
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeMake(100, 20)];
    self.titleLabel.frame = CGRectMake(20, 2, titleSize.width, 20);
    CGFloat bgW = titleSize.width +32;
    
    self.backgroundView.frame = CGRectMake(1, -33, bgW , 40);
    if (tintColor) {
        self.backgroundView.fillColor = tintColor;
    }
        
    CGPoint c = self.center;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 4, 4);
    self.center = c;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.anchorPoint = CGPointMake(0.5, 0.5);
}

- (void)setSelected:(BOOL)selected {
    
    if (canSelect == false) return;
    if (canDeselect == true && selected == false) return;
    
    [super setSelected:selected];
    
   
}

@end

