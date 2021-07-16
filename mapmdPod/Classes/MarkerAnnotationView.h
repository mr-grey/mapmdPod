//
//  MarkerAnnotationView.h
//  mapmd
//
//  Created by user on 4/24/19.
//  Copyright © 2019 simpals. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Mapbox;

NS_ASSUME_NONNULL_BEGIN

@interface MarkerAnnotationView : MGLAnnotationView



@property (nullable, nonatomic, retain) UIImage *image;
@property (nullable, nonatomic, retain) UIImage *selectedImage;

@end

NS_ASSUME_NONNULL_END
