//
//  MangaPagesViewController.m
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "MangaPagesViewController.h"
#import "MangaChapter.h"
#import "MangaPage.h"
#import "MangaPageViewCell.h"
#import "DBManager.h"
#import "AppDelegate.h"
#import <UIImageView+WebCache.h>
#import <SIAlertView.h>
#import <AppsfireAdSDK.h>
#import <AFAdSDKSashimiMinimalView.h>
#import <MBProgressHUD.h>
#import <SDImageCache.h>

#define AD_HEIGHT 100

@interface MangaPagesViewController () <UICollectionViewDelegateFlowLayout, AppsfireAdSDKDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSOperationQueue *pagesOperationQueue;
@property (nonatomic, weak) AFAdSDKSashimiMinimalView *adView;
@property (nonatomic, assign) BOOL viewWillDisappear;

@end

@implementation MangaPagesViewController

static NSString * const reuseIdentifier = @"pageCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:USER_HAS_PURCHASED_ADS_REMOVE_KEY]) {
        [AppsfireAdSDK setDelegate:self];
        NSUInteger sashimiMinimalAdsCount = [AppsfireAdSDK numberOfSashimiAdsAvailableForFormat:AFAdSDKSashimiFormatMinimal];
        NSLog(@"has %d ads", (int)sashimiMinimalAdsCount);
        if (sashimiMinimalAdsCount > 0) {
            NSError *error;
            AFAdSDKSashimiMinimalView *sashimiMinimalView;
            
            // Get sashimi view
            sashimiMinimalView = (AFAdSDKSashimiMinimalView *)[AppsfireAdSDK sashimiViewForFormat:AFAdSDKSashimiFormatMinimal withController:[UIApplication sharedApplication].keyWindow.rootViewController andError:&error];
            
            // Before using this view make sure the returned view is not `nil` and that there is not error.
            if (sashimiMinimalView != nil && error == nil) {
                
                // You can safely use the view
                [self.navigationController.view addSubview:sashimiMinimalView];
                sashimiMinimalView.frame = ({
                    CGRect frame = sashimiMinimalView.frame;
                    frame.origin.x = 0;
                    frame.size.height = AD_HEIGHT;
                    frame.origin.y = CGRectGetHeight(self.navigationController.view.frame) - CGRectGetHeight(frame);
                    frame.size.width = CGRectGetWidth(self.navigationController.view.frame);
                    frame;
                });
                self.adView = sashimiMinimalView;
                [self.collectionView.collectionViewLayout invalidateLayout];
            }
        }
    }
    
    
    self.pagesOperationQueue = [[NSOperationQueue alloc] init];
    [self.pagesOperationQueue setMaxConcurrentOperationCount:1];
    
    [self.collectionView setScrollEnabled:NO];
    
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MangaPageViewCell class]) bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    
    __block MangaChapter *ch;
    [[[DBManager sharedManager] readConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        ch = [transaction objectForKey:self.chapter.url.absoluteString inCollection:kMangaChapterCollection];
    }];
    if (ch && ch.pages.count > 0) {
        self.chapter = ch;
        [self.collectionView setScrollEnabled:YES];
        [self setTitleForPage:1 total:(int)self.chapter.pages.count];
        [self showRightBarLoadingView:NO];
    } else {
        [self showRightBarLoadingView:YES];
        __weak typeof (self) selfie = self;
        self.dataTask = [self.chapter loadPagesWithCompletion:^(NSArray *pages, NSError *error) {
            NSLog(@"%d pages received", (int)pages.count);
            
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) andMessage:error.localizedDescription];
                    
                    [alertView addButtonWithTitle:NSLocalizedString(@"Dismiss", nil)
                                             type:SIAlertViewButtonTypeCancel
                                          handler:^(SIAlertView *alert) {
                                              NSLog(@"Button1 Clicked");
                                          }];
                    [alertView show];
                    [selfie showRightBarLoadingView:NO];
                });
            } else {
                NSBlockOperation *blockOperation = [[NSBlockOperation alloc] init];
                __weak NSBlockOperation *weakOperation = blockOperation;
                [blockOperation addExecutionBlock:^{
                    int count = 1;
                    int pagesCount = (int)selfie.chapter.pages.count;
                    for (MangaPage *page in selfie.chapter.pages) {
                        if ([weakOperation isCancelled]) {
                            break;
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            selfie.title = [NSString stringWithFormat:NSLocalizedString(@"Loading page %d/%d", nil), count,pagesCount];
                        });
                        
                        NSData *data = [NSData dataWithContentsOfURL:page.url];
                        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        NSURL *imageURL = [page imageURLWithContentURLString:string];
                        [page setValue:imageURL forKey:NSStringFromSelector(@selector(imageURL))];
                        
                        [[SDWebImageManager sharedManager] downloadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                            
                        }];
                        if (count%5==0) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [selfie.collectionView reloadData];
                                [selfie.collectionView setScrollEnabled:YES];
                            });
                            
                        }
                        
                        count++;
                    }
                    if ([weakOperation isCancelled]) {
                        return;
                    }
                    
                    [[[DBManager sharedManager] writeConnection] asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                        if ([transaction hasObjectForKey:selfie.chapter.url.absoluteString inCollection:kMangaChapterCollection]) {
                            [transaction replaceObject:selfie.chapter forKey:selfie.chapter.url.absoluteString inCollection:kMangaChapterCollection];
                        } else {
                            [transaction setObject:selfie.chapter forKey:selfie.chapter.url.absoluteString inCollection:kMangaChapterCollection];
                        }
                    } completionBlock:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [selfie.collectionView reloadData];
                            [selfie setTitleForPage:1 total:pagesCount];
                            [selfie.collectionView setScrollEnabled:YES];
                            [selfie showRightBarLoadingView:NO];
                        });
                    }];
                }];
                [selfie.pagesOperationQueue addOperation:blockOperation];
            }
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"canceling data task");
    self.viewWillDisappear = YES;
    [self.dataTask cancel];
    [self.pagesOperationQueue cancelAllOperations];
    [self.adView removeFromSuperview];
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.viewWillDisappear = NO;
}

- (void)showRightBarLoadingView:(BOOL)show {
    if (show) {
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithCustomView:view];
        [view startAnimating];
        [self.navigationItem setRightBarButtonItem:right];
    } else {
        UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(didTapActionButton:)];
        [self.navigationItem setRightBarButtonItem:shareButton];
    }
}

- (void)setTitleForPage:(int)page total:(int)total{
    if (self.viewWillDisappear) {
        return;
    }
    NSString *pagination = [NSString stringWithFormat:@"%d/%d", page, total];
    NSString *title = self.chapter.title;
    NSString *combine = [NSString stringWithFormat:@"%@\n%@", title, pagination];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:combine];
    [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17] range:NSMakeRange(0, combine.length)];
    [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:[combine rangeOfString:pagination]];
    [attr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, combine.length)];
    NSMutableParagraphStyle *paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraph setAlignment:NSTextAlignmentCenter];
    [attr addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, combine.length)];
    UILabel *label = [[UILabel alloc] init];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setAttributedText:attr];
    [label setNumberOfLines:2];
    [label sizeToFit];
    [self.navigationItem setTitleView:label];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons 

- (void)didTapActionButton:(UIButton *)sender {
    MangaPageViewCell *cell = (MangaPageViewCell *)[[self.collectionView visibleCells] firstObject];
    UIImage *image = cell.imageView.image;
    if (image) {
        UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
        [self presentViewController:activity animated:YES completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please wait", nil) message:NSLocalizedString(@"Image is still loading", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - <UISCrollViewDelegate>

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self endDecelerating:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self endDecelerating:scrollView];
    }
}

- (void)endDecelerating:(UIScrollView *)scrollView {
    int page = [self currentPage];
    [self setTitleForPage:page+1 total:(int)self.chapter.pages.count];
}

- (int)currentPage {
    return (int)floorf(self.collectionView.contentOffset.x / self.collectionView.frame.size.width);
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.chapter.pages.count>0?1:0;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.chapter.pages.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MangaPageViewCell *cell = (MangaPageViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    NSInteger currentTag = cell.tag + 1;
    cell.tag = currentTag;
    MangaPage *page = [self.chapter.pages objectAtIndex:indexPath.item];
    
    [cell.indicatorView setHidden:YES];
    [cell.scrollView setZoomScale:1];
    [cell.imageView sd_setImageWithURL:page.imageURL];
    if (!cell.imageView.image) {
        __block MangaPage *dbPage;
        
        [[[DBManager sharedManager] readConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            dbPage = [transaction objectForKey:page.url.absoluteString inCollection:kMangaPageCollection];
        }];
        
        void (^imageLoadingBlock)(NSURL *imgURL) = ^void(NSURL *imgURL) {
            __weak MangaPageViewCell *weakCell = cell;
            [cell.imageView sd_setImageWithURL:imgURL placeholderImage:nil options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                __strong MangaPageViewCell *strongCell = weakCell;
                if (!strongCell.indicatorView.isAnimating) [strongCell.indicatorView startAnimating];
                [strongCell.indicatorView setHidden:NO];
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                __strong MangaPageViewCell *strongCell = weakCell;
                [strongCell.indicatorView stopAnimating];
                [strongCell.indicatorView setHidden:YES];
            }];
        };

        [cell.indicatorView setHidden:NO];
        [cell.indicatorView startAnimating];
        if (dbPage && dbPage.imageURL) {
            imageLoadingBlock(dbPage.imageURL);
        } else {
            [page loadImageURLWithCompletion:^(NSURL *imageURL, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (cell.tag == currentTag) {
                        imageLoadingBlock(page.imageURL);
                    }
                    [[[DBManager sharedManager] writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                        [transaction setObject:page forKey:page.url.absoluteString inCollection:kMangaPageCollection];
                    }];
                });
            }];
        }
    }
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (UIEdgeInsets)collectionViewInset {
    if (self.adView) {
        return UIEdgeInsetsMake(0, 0, AD_HEIGHT, 0);
    }
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = CGRectGetWidth(collectionView.frame);
    CGFloat height = CGRectGetHeight(collectionView.frame);
    UIEdgeInsets inset = [self collectionViewInset];
    return CGSizeMake(width - inset.left - inset.right, height - inset.top - inset.bottom - collectionView.contentInset.top - collectionView.contentInset.bottom);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return [self collectionViewInset];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

#pragma mark - <AppsfireAdSDKDelegate>

- (void)sashimiAdsRefreshedAndAvailable {
    
    NSLog(@"Sashimi ads were received");
    
    // check if a sashimi ad is available for the format
    NSUInteger sashimiMinimalAdsCount = [AppsfireAdSDK numberOfSashimiAdsAvailableForFormat:AFAdSDKSashimiFormatMinimal];
    NSLog(@"Number of Sashimi Minimal ads received:%lu", (unsigned long)sashimiMinimalAdsCount);
    
}

- (void)sashimiAdsRefreshedAndNotAvailable {
    NSLog(@"no sashimi ads");
}

@end
