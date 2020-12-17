//
//  ViewController.m
//  mapTestPods
//
//  Created by user on 12/17/20.
//  Copyright © 2020 mapmd. All rights reserved.
//

#import "ViewController.h"
@import mapmdPod;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  NSLog(@"%s", __func__);
  // Do any additional setup after loading the view.
  CGRect rect = [UIScreen mainScreen].bounds;
  MapView *map = [[MapView alloc] initWithFrame:rect];
  
  [self.view addSubview:map];
}


@end
