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
#import "DBManager.h"
#import <UIImageView+WebCache.h>
#import <SVProgressHUD.h>
#import <SIAlertView.h>

@interface MangaViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end

@implementation MangaViewController

static NSString * const headerIdentifier = @"headerCell";
static NSString * const chapterIdentifier = @"chapterCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MangaHeaderViewCell class]) bundle:nil] forCellWithReuseIdentifier:headerIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MangaChapterCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:chapterIdentifier];
    
    self.title = self.searchResult.name?:self.manga.name;
    
    NSString *key = self.searchResult.url.absoluteString?:self.manga.url.absoluteString;
    __block Manga *m;
    [[[DBManager sharedManager] readConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        m = [transaction objectForKey:key inCollection:kMangaCollection];
    }];
    
    if (m) {
        self.manga = m;
        [self.collectionView reloadData];
        [self setUpdatingTitleView];
        [self showAddToCollectionButton:YES];
    } else {
        [SVProgressHUD show];
    }
    
    self.dataTask = [Mangapanda mangaWithURL:self.searchResult.url?:self.manga.url completion:^(Manga *manga, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"done fetching manga");
            [SVProgressHUD dismiss];
            self.navigationItem.titleView = nil;
            self.title = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d chapters)", nil), self.searchResult.name?:self.manga.name, (int)manga.chapters.count];
            self.manga = manga;
            [self.collectionView reloadData];
            [self showAddToCollectionButton:YES];
            
            [[[DBManager sharedManager] writeConnection] asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                if ([transaction hasObjectForKey:self.searchResult.url.absoluteString?:self.manga.url.absoluteString inCollection:kMangaCollection]) {
                    [transaction replaceObject:manga forKey:self.searchResult.url.absoluteString?:self.manga.url.absoluteString inCollection:kMangaCollection];
                } else {
                    [transaction setObject:manga forKey:self.searchResult.url.absoluteString?:self.manga.url.absoluteString inCollection:kMangaCollection];
                }
            }];
        });
    }];
}

- (void)showAddToCollectionButton:(BOOL)show {
    if (show) {
        UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didTapAddButton:)];
        [self.navigationItem setRightBarButtonItem:right];
    } else {
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

- (void)didTapAddButton:(id)sender {
    [sender setEnabled:NO];
    if (self.manga) {
        [[[DBManager sharedManager] writeConnection] asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            if ([transaction hasObjectForKey:self.searchResult.url.absoluteString?:self.manga.url.absoluteString inCollection:kMangaCollection]) {
                [transaction replaceMetadata:@{kFavoritedDateKey: [NSDate date]} forKey:self.searchResult.url.absoluteString?:self.manga.url.absoluteString inCollection:kMangaCollection];
            } else {
                [transaction setObject:self.manga forKey:self.searchResult.url.absoluteString?:self.manga.url.absoluteString inCollection:kMangaCollection withMetadata:@{kFavoritedDateKey: [NSDate date]}];
            }
        } completionBlock:^{
            [sender setEnabled:YES];
            
            SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:NSLocalizedString(@"Added to Collections", nil) andMessage:[NSString stringWithFormat:NSLocalizedString(@"%@ has been added to your collection.", nil), self.manga.name]];
            
            [alertView addButtonWithTitle:NSLocalizedString(@"Dismiss", nil)
                                     type:SIAlertViewButtonTypeCancel
                                  handler:^(SIAlertView *alert) {
                                      NSLog(@"Button1 Clicked");
                                  }];
            [alertView show];
        }];
    }
}

- (void)setUpdatingTitleView {
    NSString *updating = NSLocalizedString(@"Updating ...", nil);
    NSString *titleString = [NSString stringWithFormat:@"%@\n%@", self.title, updating];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:titleString];
    [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17] range:NSMakeRange(0, titleString.length)];
    [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:[titleString rangeOfString:updating]];
    NSMutableParagraphStyle *paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraph setAlignment:NSTextAlignmentCenter];
    [attr addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, titleString.length)];
    UILabel *label = [[UILabel alloc] init];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setAttributedText:attr];
    [label setNumberOfLines:2];
    [label sizeToFit];
    [self.navigationItem setTitleView:label];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.dataTask suspend];
    self.navigationItem.titleView = nil;
    self.title = self.manga.name;
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.dataTask && self.dataTask.state == NSURLSessionTaskStateSuspended) {
        [self setUpdatingTitleView];
        [self.dataTask resume];
    }
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
