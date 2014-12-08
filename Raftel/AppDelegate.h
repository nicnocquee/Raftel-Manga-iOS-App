//
//  AppDelegate.h
//  Raftel
//
//  Created by  on 12/6/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <UIKit/UIKit.h>

#define USER_HAS_PURCHASED_ADS_REMOVE_KEY @"com.raftelapp.ADS_REMOVE_PURCHASED_KEY"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (BOOL)displayModalAdIfPossible;
- (void)removeAds;


@end

