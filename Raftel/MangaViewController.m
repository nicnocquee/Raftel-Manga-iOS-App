//
//  MangaViewController.m
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "MangaViewController.h"
#import "MangaHeaderViewCell.h"
#import "MangaChapterCollectionViewCell.h"
#import "Manga.h"
#import "Mangapanda.h"
#import "MangaSearchResult.h"
#import <UIImageView+WebCache.h>
#import <SVProgressHUD.h>

@interface MangaViewController () <UICollectionViewDelegateFlowLayout>

@end

@implementation MangaViewController

static NSString * const headerIdentifier = @"headerCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MangaHeaderViewCell class]) bundle:nil] forCellWithReuseIdentifier:headerIdentifier];
    
    [SVProgressHUD show];
    [Mangapanda mangaWithURL:self.searchResult.url completion:^(Manga *manga, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            self.manga = manga;
            [self.collectionView reloadData];
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.manga) {
        return 1;
    }
    return 0;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        // return self.manga.chapters.count;
    }
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell;
    
    if (indexPath.section == 0) {
        MangaHeaderViewCell *headerCell = (MangaHeaderViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:headerIdentifier forIndexPath:indexPath];
        [self configureHeaderCell:headerCell withManga:self.manga];
        cell = headerCell;
    }
    
    
    return cell;
}

- (void)configureHeaderCell:(MangaHeaderViewCell *)headerCell withManga:(Manga *)manga {
    [headerCell.imageView sd_setImageWithURL:self.manga.coverURL];
    headerCell.titleLabel.text = manga.name;
    headerCell.yearLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Year: %@", nil), manga.year];
    headerCell.statusLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Status", ni), manga.ongoing.boolValue?NSLocalizedString(@"Ongoing", nil):NSLocalizedString(@"Completed", ni)];
    headerCell.authorLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Author: %@", ni), manga.author];
    headerCell.artistLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Artist: %@", ni), manga.artist];
    headerCell.summaryLabel.text = manga.synopsis;
}

#pragma mark <UICollectionViewDelegate>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        MangaHeaderViewCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MangaHeaderViewCell class]) owner:nil options:nil] firstObject];
        [self configureHeaderCell:cell withManga:self.manga];
        cell.frame = ({
            CGRect frame = cell.frame;
            frame.size.width = CGRectGetWidth(collectionView.frame);
            frame.size.height = CGFLOAT_MAX;
            frame;
        });
        [cell setNeedsUpdateConstraints];
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        
        return CGSizeMake(CGRectGetWidth(collectionView.frame), MAX(CGRectGetMaxY(cell.summaryLabel.frame), CGRectGetMaxY(cell.imageView.frame)));
    }
    return CGSizeZero;
}

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
