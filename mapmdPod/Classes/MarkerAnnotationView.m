//
//  MarkerAnnotationView.m
//  mapmd
//
//  Created by user on 4/24/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import "MarkerAnnotationView.h"
#import "MapMarker.h"
#import "SMapHelper.h"

#define DEG2RAD(degrees) (degrees * 0.01745327)


@interface MarkerAnnotationView()
@property (nonatomic, retain) UIImageView *pinImage;
@property (nonatomic, retain) UILabel *countLabel; // used for cluster
@end


@implementation MarkerAnnotationView
@synthesize image;
@synthesize selectedImage;
@synthesize countLabel;


- (void)prepareForReuse {
    
    MapMarker *marker = self.annotation;
    if ([marker class] == [MapMarker class]) {
        if (marker.marker_type == MarkerTypeGroup) {
         
          // clear old image
          self.image = nil;
          
          if (self.image == nil) {
            self.image = [SMapHelper imageForGroup_v2:marker.count];
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.image.size.width, self.image.size.height);
            self.backgroundColor = [UIColor colorWithPatternImage:self.image];
          }
          
            CGSize size = self.image.size;
            NSLog(@"prepareForReuse image-%@", NSStringFromCGSize(size));
            if (!image) {
                NSLog(@"no image!");
                self.image = [SMapHelper imageForGroup_v2:marker.count];
                self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.image.size.width, self.image.size.height);
                self.backgroundColor = [UIColor colorWithPatternImage:self.image];
                return;
            }
                
            NSString *txt = [NSString stringWithFormat:@"%zd",marker.count];
            self.countLabel.text = txt;
            
        }
    }
    
}

- (void)setupLabel {
    
    self.countLabel = [[UILabel alloc] initWithFrame:self.bounds];
    self.countLabel.textAlignment = NSTextAlignmentCenter;
    self.countLabel.textColor = [UIColor whiteColor];
    self.countLabel.font = [UIFont systemFontOfSize:15 weight:(UIFontWeightBold)];
    
    [self addSubview:self.countLabel];
}

- (instancetype)initWithAnnotation:(id<MGLAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    
    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0].CGColor;
    
    
    MapMarker *marker = self.annotation;
    if ([marker class] == [MapMarker class]) {
        if (marker.marker_type == MarkerTypeGroup) {
           
            UIImage *groupImage = [marker image];
            self.image = groupImage;
            
            if (self.image == nil) {
              self.image = [self imageForGroup];
            }
            CGSize size = self.image.size;
            NSLog(@"Init image-%@", NSStringFromCGSize(size));
            
            if (size.width == 0) {
                NSLog(@"wft count: %zd %@",marker.count, self.image);
                size = CGSizeMake(30, 30);
            }
            
            self.layer.anchorPoint = CGPointMake(0.5, 0.5);
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.image.size.width, self.image.size.height);
            self.backgroundColor = [UIColor colorWithPatternImage:self.image];
            
            self.layer.shadowOffset = CGSizeMake(0, 2);
            self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.29].CGColor;
            self.layer.shadowOpacity = 1;
            self.layer.shadowRadius = 1;
            self.clipsToBounds = false;
            
            [self setupLabel];
        }
    }
    
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = self.bounds.size.width / 2;
    
    MapMarker *marker = self.annotation;
    if ([marker class] == [MapMarker class]) {
        if (marker.marker_type == MarkerTypeGroup) {
            
            countLabel.center = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
            
        }
        
    }
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    if (hidden) {
        [self.layer removeAllAnimations];
    }
}

- (void)selectionForMarkerType:(MapMarker *)marker {
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
   
    if (self.isHidden) return;
    
    // Animate the border width in/out, creating an iris effect.
    if ([self.annotation class] != [MapMarker class]) {
        [super setSelected:selected animated:animated];
        return;
    }
    MapMarker *marker = self.annotation;
    NSLog(@"setSelected: %i animated: %i ", selected, animated);
    marker.isSelected = selected;
    
    self.image = marker.image;
    self.selectedImage = marker.selectedImage;
    
    if (marker.marker_type == MarkerTypeTemporary) {
        
        if (selected) {
            UIImage *img = [marker selectedImage];
            CGPoint c = self.center;
            self.layer.anchorPoint = CGPointMake(0.5, 0.5);
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, img.size.width, img.size.height);
            self.center = c;
            self.backgroundColor = [UIColor colorWithPatternImage:img];
            
        } else {
            CGPoint c = self.center;
            UIImage *img = [marker image];
            CGAffineTransform t = CGAffineTransformScale(self.transform, 1.0/2.5, 1.0/2.5);
            self.layer.anchorPoint = CGPointMake(0.5, 0.5);
            [UIView animateWithDuration:0.2 animations:^{
                self.transform = t;
                self.center = c;
                
            } completion:^(BOOL finished) {
                self.transform = CGAffineTransformIdentity;
                self.frame = CGRectMake(self.frame.origin.x
                                        , self.frame.origin.y, img.size.width, img.size.height);
                
                self.center = c;
                
                self.backgroundColor = [UIColor clearColor];
                
                
            }];
        }
        
        [super setSelected:selected animated:animated];
    return;
    } //end MarkerTypeTemporary
    
    
    if (!animated) {
        if (selected && marker.selectedImage) {
            
            UIImage *img = [marker selectedImage];
            
            CGPoint c = self.center;
            self.transform = CGAffineTransformIdentity;
            self.frame = CGRectMake(self.frame.origin.x
                                        , self.frame.origin.y, img.size.width, img.size.height);
                
            self.center = c;
            self.backgroundColor = [UIColor colorWithPatternImage:img];
                
            [super setSelected:selected animated:animated];
            return;
            
        }
        
        if (!selected && [marker image]) {
            UIImage *img = [marker image];
            
            CGPoint c = self.center;
            self.transform = CGAffineTransformIdentity;
            self.frame = CGRectMake(self.frame.origin.x
                                    , self.frame.origin.y, img.size.width, img.size.height);
            
            self.center = c;
            self.backgroundColor = [UIColor colorWithPatternImage:img];
            
            [super setSelected:selected animated:animated];
            return;
        }
        
    }
    
    /// animated !
    
    if (self.isSelected == false)  {
        // become selected
        if (selected && marker.selectedImage) {
            
            UIImage *img = [marker selectedImage];
       
            CGPoint c = self.center;
            CGAffineTransform t = CGAffineTransformScale(self.transform, 2.5, 2.5);
            
            [UIView animateWithDuration:0.2 animations:^{
                self.transform = t;
                self.center = c;
                
            } completion:^(BOOL finished) {
                self.transform = CGAffineTransformIdentity;
                self.frame = CGRectMake(self.frame.origin.x
                                                 , self.frame.origin.y, img.size.width, img.size.height);
                
                self.center = c;
                
                self.backgroundColor = [UIColor colorWithPatternImage:img];
               
                
            }];
            
        } else {
        
        }
    } else {
        // become not-selected from selected state
        if (selected == false && marker.image) {
            
            UIImage *img = [marker image];
            
            
            CGPoint c = self.center;
            CGAffineTransform t = CGAffineTransformScale(self.transform, 1.0/2.5, 1.0/2.5);
            
            [UIView animateWithDuration:0.2 animations:^{
                self.transform = t;
                self.center = c;
                
            } completion:^(BOOL finished) {
                self.transform = CGAffineTransformIdentity;
                self.frame = CGRectMake(self.frame.origin.x
                                                 , self.frame.origin.y, img.size.width, img.size.height);
                
                self.center = c;
                
                self.backgroundColor = [UIColor colorWithPatternImage:img];
               
                
            }];
        }
    }
    
    [super setSelected:selected animated:animated];
    
}



// MARK: - grouped
- (UIImage*)imageForGroup {
    MapMarker *marker = self.annotation;
    NSInteger total = marker.count;
    
    CGRect rect = CGRectMake(0.0f, 0.0f, 29.0f, 29.0f);
    
    if(total<=10)
        rect = CGRectMake(0,0,29,29);
    if(total<=100 && total > 10)
        rect = CGRectMake(0,0,45,45);
    if(total>100)
        rect = CGRectMake(0,0,53,53);
    
    
    
    
    UIColor *color = [UIColor colorWithRed:(46.0/255.0) green:(127.0/255.0) blue:(209.0/255.0) alpha:1.0];
    
    UIGraphicsBeginImageContextWithOptions(rect.size,NO, 2);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    

    
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextAddArc(context, rect.size.width/2, rect.size.height/2, (rect.size.height/2), 0, DEG2RAD(360), 0);
    CGContextFillEllipseInRect (context, rect);
    
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextAddArc(context, rect.size.width/2, rect.size.height/2, ((rect.size.height/2.0) - 3), 0, DEG2RAD(360), 0);
    CGContextFillEllipseInRect (context, CGRectInset(rect, 3, 3));
    [[UIColor whiteColor] setStroke];
    
    //CGContextSetStrokeColor(context, [UIColor whiteColor].CGColor);
    
    
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    return image;
}

// MARK: -
@end
