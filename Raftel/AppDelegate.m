//
//  AppDelegate.m
//  Raftel
//
//  Created by  on 12/6/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "AppDelegate.h"
#import <SDWebImageManager.h>
#import <Crashlytics/Crashlytics.h>
#import <AppsfireSDK.h>
#import <AppsfireAdSDK.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    if (isRunningTests()) {
        // if unit test, need to return quickly. Reference: http://www.objc.io/issue-1/testing-view-controllers.html
        return YES;
    }
    
    [[[SDWebImageManager sharedManager] imageCache] setMaxCacheAge:30*24*60*60*12];
    [AppsfireSDK connectWithSDKToken:@"1B0D21DBE444DBC97C9FF7F3783CE10C" secretKey:@"8e7d7710f71bfb609feb41c54f978d74" features:AFSDKFeatureMonetization parameters:nil];
    [Crashlytics startWithAPIKey:@"e2c34125953b33a5ab021b095a449f744b70187a"];
    
    UIColor *darkColor = [UIColor colorWithRed:0.118 green:0.125 blue:0.157 alpha:1.000];
    [[UINavigationBar appearance] setBarTintColor:darkColor];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [[UITabBar appearance] setBarTintColor:darkColor];
    [[UITabBar appearance] setTintColor:[UIColor colorWithRed:0.227 green:0.506 blue:0.718 alpha:1.000]];
    
#ifdef DEBUG
    [AppsfireAdSDK setDebugModeEnabled:YES];
#endif
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Ads

- (BOOL)displayModalAdIfPossible {
    
    // if there is no ad or if one is already displayed, stop there!
    if ([AppsfireAdSDK isThereAModalAdAvailableForType:AFAdSDKModalTypeSushi] != AFAdSDKAdAvailabilityYes || [AppsfireAdSDK isModalAdDisplayed])
        return NO;
    
    // else, request the ad that should quickly appears
    [AppsfireAdSDK requestModalAd:AFAdSDKModalTypeSushi withController:[UIApplication sharedApplication].keyWindow.rootViewController withDelegate:nil];
    
    return YES;
    
}

#pragma mark - Unit Test

static BOOL isRunningTests(void)
{
    
    NSDictionary* environment = [[NSProcessInfo processInfo] environment];
    NSString* injectBundle = environment[@"XCInjectBundle"];
    return [[injectBundle pathExtension] isEqualToString:@"xctest"];
}

@end
