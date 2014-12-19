//
//  AppDelegate.m
//  Raftel
//
//  Created by  on 12/6/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

@import StoreKit;
#import "AppDelegate.h"
#import "SearchCollectionViewController.h"
#import <SDWebImageManager.h>
#import <Crashlytics/Crashlytics.h>
#import <AppsfireSDK.h>
#import <AppsfireAdSDK.h>
#import <MBProgressHUD.h>

@interface AppDelegate () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong) NSArray *iapProducts;
@property (nonatomic, assign) BOOL purchaseInitiated;

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
    
    [[UIToolbar appearance] setBarTintColor:darkColor];
    [[UIToolbar appearance] setTintColor:[UIColor whiteColor]];
    
#ifdef DEBUG
    [AppsfireAdSDK setDebugModeEnabled:YES];
#endif
    
    BOOL returnResult = NO;
    if (launchOptions) {
        NSURL *URL = launchOptions[UIApplicationLaunchOptionsURLKey];
        if (URL && [URL.scheme isEqualToString:@"raftel"]) {
            returnResult = YES;
        }
    }
    
    return returnResult;
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

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"open url: %@", url);
    if (![url.scheme isEqualToString:@"raftel"]) {
        return NO;
    }
    NSString *path = url.relativePath;
    NSString *mangaURLString = [NSString stringWithFormat:@"http://www.mangapanda.com%@", path];
    NSURL *mangaURL = [NSURL URLWithString:mangaURLString];
    
    UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
    SearchCollectionViewController *searchVC = (SearchCollectionViewController *)[[[tabBar.viewControllers firstObject] viewControllers] firstObject];
    [searchVC openMangaWithURL:mangaURL];
    return YES;
}

#pragma mark - Ads

- (BOOL)displayModalAdIfPossible {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:USER_HAS_PURCHASED_ADS_REMOVE_KEY]) {
        // if there is no ad or if one is already displayed, stop there!
        if ([AppsfireAdSDK isThereAModalAdAvailableForType:AFAdSDKModalTypeSushi] != AFAdSDKAdAvailabilityYes || [AppsfireAdSDK isModalAdDisplayed])
            return NO;
        
        // else, request the ad that should quickly appears
        [AppsfireAdSDK requestModalAd:AFAdSDKModalTypeSushi withController:[UIApplication sharedApplication].keyWindow.rootViewController withDelegate:nil];
        
        return YES;
    }
    
    return NO;
}

- (void)removeAds {
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [MBProgressHUD showHUDAddedTo:self.window animated:YES];
    NSString *productId = @"removeads";
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
                                          initWithProductIdentifiers:[NSSet setWithObject:productId]];
    productsRequest.delegate = self;
    [productsRequest start];
}

- (void)restorePurchase {
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark - <SKProductsRequestDelegate>

- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
    [MBProgressHUD hideHUDForView:self.window animated:YES];
    self.iapProducts = response.products;
    
    NSLog(@"Products: %@", self.iapProducts);
    SKProduct *product = [self.iapProducts firstObject];
    if (product) {
        NSLog(@"Product %@", product.localizedTitle);
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:product.priceLocale];
        NSString *formattedPrice = [numberFormatter stringFromNumber:product.price];
        
        NSLog(@"Price: %@", formattedPrice);
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirm Purchase", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Remove ads for %@?", nil), formattedPrice] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Buy", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.purchaseInitiated = YES;
            SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [alert addAction:action];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
                // Call the appropriate custom method for the transaction state.
            case SKPaymentTransactionStatePurchasing:{
                NSLog(@"purchasing");
                MBProgressHUD *progressHud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
                progressHud.labelText = NSLocalizedString(@"Purchasing ... ", nil);
                break;
            } case SKPaymentTransactionStateDeferred:{
                NSLog(@"deferred");
                MBProgressHUD *progressHud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
                progressHud.labelText = NSLocalizedString(@"Waiting for authorization", nil);
                break;
            } case SKPaymentTransactionStateFailed:{
                NSLog(@"failed");
                [MBProgressHUD hideHUDForView:self.window animated:YES];
                if (self.purchaseInitiated) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Purchase Failed", nil) message:transaction.error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil];
                    [alert addAction:cancel];
                    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                }
                
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:USER_HAS_PURCHASED_ADS_REMOVE_KEY];
                [[NSUserDefaults standardUserDefaults] synchronize];
                break;
            } case SKPaymentTransactionStatePurchased:{
                NSLog(@"purchased");
                [MBProgressHUD hideHUDForView:self.window animated:YES];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Purchase Succeeded", nil) message:NSLocalizedString(@"Thank you for removing the ads!", nil) preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:cancel];
                [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_HAS_PURCHASED_ADS_REMOVE_KEY];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [queue finishTransaction:transaction];
                [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
                break;
            } case SKPaymentTransactionStateRestored:{
                NSLog(@"restored");
                [MBProgressHUD hideHUDForView:self.window animated:YES];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Purchase Restored", nil) message:NSLocalizedString(@"You have purchased ads removal. Ads won't be shown anymore.", nil) preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:cancel];
                [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_HAS_PURCHASED_ADS_REMOVE_KEY];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [queue finishTransaction:transaction];
                [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
                break;
            } default:
                // For debugging
                NSLog(@"Unexpected transaction state %@", @(transaction.transactionState));
                break;
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    NSLog(@"complete restore: %@", queue);
    if (![[NSUserDefaults standardUserDefaults] boolForKey:USER_HAS_PURCHASED_ADS_REMOVE_KEY]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No Purchase History", nil) message:NSLocalizedString(@"You have not purchased ads removal.", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSLog(@"fail restore: %@", error);
}

#pragma mark - Unit Test

static BOOL isRunningTests(void)
{
    
    NSDictionary* environment = [[NSProcessInfo processInfo] environment];
    NSString* injectBundle = environment[@"XCInjectBundle"];
    return [[injectBundle pathExtension] isEqualToString:@"xctest"];
}

@end
