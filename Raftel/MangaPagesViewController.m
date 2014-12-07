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
#import <SVProgressHUD.h>

@interface MangaPagesViewController () <UICollectionViewDelegateFlowLayout>

@end

@implementation MangaPagesViewController

static NSString * const reuseIdentifier = @"pageCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MangaPageViewCell class]) bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    
    __block MangaChapter *ch;
    [[[DBManager sharedManager] readConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        ch = [transaction objectForKey:self.chapter.url.absoluteString inCollection:kMangaChapterCollection];
    }];
    if (ch && ch.pages.count > 0) {
        self.chapter = ch;
        [self setTitleForPage:1 total:(int)self.chapter.pages.count];
    } else {
        [SVProgressHUD show];
        [self.chapter loadPagesWithCompletion:^(NSArray *pages, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    [SVProgressHUD dismiss];
                    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) andMessage:error.localizedDescription];
                    
                    [alertView addButtonWithTitle:NSLocalizedString(@"Dismiss", nil)
                                             type:SIAlertViewButtonTypeCancel
                                          handler:^(SIAlertView *alert) {
                                              NSLog(@"Button1 Clicked");
                                          }];
                    [alertView show];
                } else {
                    NSLog(@"%d pages received", (int)pages.count);
                    [self.collectionView reloadData];
                    
                    [self setTitleForPage:1 total:(int)self.chapter.pages.count];
                    
                    [[[DBManager sharedManager] writeConnection] asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                        [transaction setObject:self.chapter forKey:self.chapter.url.absoluteString inCollection:kMangaChapterCollection];
                    }];
                    
                    [SVProgressHUD dismiss];
                }
            });
        }];
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
