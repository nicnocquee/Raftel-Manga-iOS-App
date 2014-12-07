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
#import "MangaChapter.h"
#import "MangaSearchResult.h"
#import "MangaPagesViewController.h"
#import <UIImageView+WebCache.h>
#import <SVProgressHUD.h>

@interface MangaViewController () <UICollectionViewDelegateFlowLayout>

@end

@implementation MangaViewController

static NSString * const headerIdentifier = @"headerCell";
static NSString * const chapterIdentifier = @"chapterCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MangaHeaderViewCell class]) bundle:nil] forCellWithReuseIdentifier:headerIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MangaChapterCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:chapterIdentifier];
    
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPages"]) {
        MangaPagesViewController *pagesVC = (MangaPagesViewController *)segue.destinationViewController;
        [pagesVC setHidesBottomBarWhenPushed:YES];
        pagesVC.chapter = sender;
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.manga) {
        return 2;
    }
    return 0;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return self.manga.chapters.count;
    }
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell;
    
    if (indexPath.section == 0) {
        MangaHeaderViewCell *headerCell = (MangaHeaderViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:headerIdentifier forIndexPath:indexPath];
        [self configureHeaderCell:headerCell withManga:self.manga];
        cell = headerCell;
    } else {
        MangaChapter *chapter = [self.manga.chapters objectAtIndex:indexPath.item];
        MangaChapterCollectionViewCell *chapterCell = (MangaChapterCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:chapterIdentifier forIndexPath:indexPath];
        NSString *chapterIndex = [NSString stringWithFormat:@"#%d", chapter.index.intValue];
        NSString *chapterString = [NSString stringWithFormat:@"%@ %@", chapterIndex, chapter.title];
        NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:chapterString];
        [attr addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, chapterString.length)];
        [attr addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:[chapterString rangeOfString:chapterIndex]];
        [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:10] range:[chapterString rangeOfString:chapterIndex]];
        [chapterCell.nameLabel setAttributedText:attr];
        cell = chapterCell;
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
        
        return CGSizeMake(CGRectGetWidth(collectionView.frame), MAX(CGRectGetMaxY(cell.summaryLabel.frame), CGRectGetMaxY(cell.imageView.frame)) + 10);
    } else {
        return CGSizeMake(CGRectGetWidth(collectionView.frame), 44);
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        MangaChapter *chapter = [self.manga.chapters objectAtIndex:indexPath.item];
        [self performSegueWithIdentifier:@"showPages" sender:chapter];
    }
}

@end
