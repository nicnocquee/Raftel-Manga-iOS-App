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
    
    
    [SVProgressHUD show];
    [self.chapter loadPagesWithCompletion:^(NSArray *pages, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            if (error) {
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
                
                self.title = [NSString stringWithFormat:@"1/%d", (int)pages.count];
            }
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - <UISCrollViewDelegate>

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    int page = (int)floorf(self.collectionView.contentOffset.x / scrollView.frame.size.width);
    self.title = [NSString stringWithFormat:@"%d/%d", page+1, (int)self.chapter.pages.count];
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
        [cell.indicatorView setHidden:NO];
        [cell.indicatorView startAnimating];
        [page loadImageURLWithCompletion:^(NSURL *imageURL, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (cell.tag == currentTag) {
                    __weak MangaPageViewCell *weakCell = cell;
                    [cell.imageView sd_setImageWithURL:page.imageURL placeholderImage:nil options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                        __strong MangaPageViewCell *strongCell = weakCell;
                        if (!strongCell.indicatorView.isAnimating) [strongCell.indicatorView startAnimating];
                        [strongCell.indicatorView setHidden:NO];
                    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                        __strong MangaPageViewCell *strongCell = weakCell;
                        [strongCell.indicatorView stopAnimating];
                        [strongCell.indicatorView setHidden:YES];
                    }];
                }
            });
        }];
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
