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



@property (nullable, nonatomic, weak) UIImage *image;
@property (nullable, nonatomic, weak) UIImage *selectedImage;

@end

NS_ASSUME_NONNULL_END
