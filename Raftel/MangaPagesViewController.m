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
#import <UIImageView+WebCache.h>
#import <SIAlertView.h>

@interface MangaPagesViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSOperationQueue *pagesOperationQueue;

@end

@implementation MangaPagesViewController

static NSString * const reuseIdentifier = @"pageCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
                        
                        
                        count++;
                    }
                    if ([weakOperation isCancelled]) {
                        return;
                    }
                    
                    [[[DBManager sharedManager] writeConnection] asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                        [transaction setObject:selfie.chapter forKey:selfie.chapter.url.absoluteString inCollection:kMangaChapterCollection];
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
    [super viewWillDisappear:animated];
    NSLog(@"canceling data task");
    [self.dataTask cancel];
    [self.pagesOperationQueue cancelAllOperations];
}

- (void)showRightBarLoadingView:(BOOL)show {
    if (show) {
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithCustomView:view];
        [view startAnimating];
        [self.navigationItem setRightBarButtonItem:right];
    } else {
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

- (void)setTitleForPage:(int)page total:(int)total{
    NSString *pagination = [NSString stringWithFormat:@"%d/%d", page, total];
    NSString *title = self.chapter.title;
    NSString *combine = [NSString stringWithFormat:@"%@\n%@", title, pagination];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:combine];
    [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17] range:NSMakeRange(0, combine.length)];
    [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:[combine rangeOfString:pagination]];
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

#pragma mark - <UISCrollViewDelegate>

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    int page = (int)floorf(self.collectionView.contentOffset.x / scrollView.frame.size.width);
    [self setTitleForPage:page+1 total:(int)self.chapter.pages.count];
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return collectionView.frame.size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

@end
