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
#import "MangaProcessor.h"
#import "UserLastRead.h"
#import "AppDelegate.h"
#import <UIImageView+WebCache.h>
#import <MBProgressHUD.h>
#import <SIAlertView.h>

@interface MangaViewController () <UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSString *contentString;
@property (nonatomic, strong) NSOperation *operation;
@property (nonatomic, assign) BOOL ascending;
@property (nonatomic, strong) MangaChapter *currentlyReadChapter;
@property (nonatomic, assign) BOOL hasShownAds;

@end

@implementation MangaViewController

static NSString * const headerIdentifier = @"headerCell";
static NSString * const chapterIdentifier = @"chapterCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.ascending = YES;
    
    [self.navigationController setDelegate:self];
    
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
        self.title = self.manga.name;
        [self.collectionView reloadData];
        __weak typeof (self) selfie = self;
        NSURL *url = self.manga.url;
        [[[DBManager sharedManager] readConnection] asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
            UserLastRead *lastRead = [transaction objectForKey:url.absoluteString inCollection:kUserLastReadCollection];
            if (lastRead) {
                selfie.currentlyReadChapter = [transaction objectForKey:lastRead.chapterURL.absoluteString inCollection:kMangaChapterCollection];
            }
        } completionBlock:^{
            if (self.currentlyReadChapter) {
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentlyReadChapter.index.integerValue inSection:1] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
            }
        }];
        [self setUpdatingTitleView];
        [self showSortButton];
    } else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    
    NSURL *URL = self.searchResult.url?:self.manga.url;
    NSString *name = self.searchResult.name?:self.manga.name;
    __weak typeof (self) selfie = self;
    self.dataTask = [[NSURLSession sharedSession] dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Cannot Fetch %@", nil), name] andMessage:error.localizedDescription];
                
                [alertView addButtonWithTitle:NSLocalizedString(@"Dismiss", nil)
                                         type:SIAlertViewButtonTypeCancel
                                      handler:^(SIAlertView *alert) {
                                          NSLog(@"Button1 Clicked");
                                      }];
                [alertView show];
                [MBProgressHUD hideHUDForView:selfie.view animated:YES];
            });
        } else {
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            selfie.contentString = dataString;
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:selfie.view animated:YES];
                [selfie startProcessingContentString];
            });
        }
    }];
    [self.dataTask resume];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.dataTask suspend];
    self.navigationItem.titleView = nil;
    self.title = self.manga.name;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.dataTask && self.dataTask.state == NSURLSessionTaskStateSuspended) {
        [self setUpdatingTitleView];
        [self.dataTask resume];
    } else {
        if ([self.operation isExecuting]) {
            [self setUpdatingTitleView];
        }
        [self startProcessingContentString];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(didTapActionButton:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didTapAddButton:)];
    [self setToolbarItems:@[addButton, flexibleSpace, shareButton]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)showAdsWhileWaiting {
    if (!self.hasShownAds) {
        self.hasShownAds = YES;
        if (![[NSUserDefaults standardUserDefaults] boolForKey:USER_HAS_PURCHASED_ADS_REMOVE_KEY]) {
            [(AppDelegate *)[[UIApplication sharedApplication] delegate] displayModalAdIfPossible];
        }
    }
}

- (void)startProcessingContentString {
    if (self.contentString && ![self.operation isExecuting]) {
        __weak typeof (self) selfie = self;
        NSURL *URL = self.searchResult.url?:self.manga.url;
        if (!self.manga) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
        self.operation = [[MangaProcessor sharedProcessor] processMangaFromURL:URL contentString:self.contentString completion:^(Manga *manga) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:selfie.view animated:YES];
                selfie.navigationItem.titleView = nil;
                selfie.title = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d chapters)", nil), selfie.searchResult.name?:selfie.manga.name, (int)manga.chapters.count];
                selfie.manga = manga;
                [selfie.collectionView reloadData];
                [selfie showSortButton];
                
                [[[DBManager sharedManager] writeConnection] asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    if ([transaction hasObjectForKey:selfie.searchResult.url.absoluteString?:selfie.manga.url.absoluteString inCollection:kMangaCollection]) {
                        [transaction replaceObject:manga forKey:selfie.searchResult.url.absoluteString?:selfie.manga.url.absoluteString inCollection:kMangaCollection];
                    } else {
                        [transaction setObject:manga forKey:selfie.searchResult.url.absoluteString?:selfie.manga.url.absoluteString inCollection:kMangaCollection];
                    }
                }];
                selfie.contentString = nil;
            });
        } didProcessChapter:^(MangaChapter *chapter, int total) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!selfie.manga)  {
                    selfie.navigationItem.titleView = nil;
                    selfie.title = [NSString stringWithFormat:NSLocalizedString(@"Processing chapter %d/%d", nil), chapter.index.intValue, total];
                    if (total > 100 && chapter.index.intValue > 50 && !selfie.hasShownAds) {
                        [selfie showAdsWhileWaiting];
                    }
                }
            });
        }];
    }
}

#pragma mark - <UINavigationControllerDelegate>

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:((UIViewController *)[navigationController.viewControllers firstObject]).class]) {
        [[[MangaProcessor sharedProcessor] operationQueue] cancelAllOperations];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [navigationController setDelegate:nil];
    }
}

#pragma mark - Buttons

- (void)didTapActionButton:(UIButton *)sender {
    NSString *relative = self.manga.url.relativePath?:self.searchResult.url.relativePath;
    NSString *raftelURLString = [NSString stringWithFormat:@"raftel://manga%@", relative];
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Hey check out %@ in Raftel app! %@\n\n Download the app here first https://itunes.apple.com/us/app/raftel-manga-browser-reader/id949370715?ls=1&mt=8\n\n", nil), self.manga.name, raftelURLString];
    void (^completionHandler)(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) = ^void(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        
    };

    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[message] applicationActivities:nil];
    [activity setCompletionWithItemsHandler:completionHandler];
    [self presentViewController:activity animated:YES completion:nil];
}

- (void)showSortButton {
    UIImage *ascendingImage = [UIImage imageNamed:@"Ascending"];
    if (!self.ascending) {
        ascendingImage = [UIImage imageNamed:@"Descending"];
    }
    UIBarButtonItem *sort = [[UIBarButtonItem alloc] initWithImage:ascendingImage style:UIBarButtonItemStyleDone target:self action:@selector(didTapSort:)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [space setWidth:5];
    [self.navigationItem setRightBarButtonItems:@[sort]];
}

- (void)didTapSort:(id)sender {
    self.ascending = !self.ascending;
    [self.collectionView reloadData];
    [self showSortButton];
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
    [attr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, titleString.length)];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPages"]) {
        MangaPagesViewController *pagesVC = (MangaPagesViewController *)segue.destinationViewController;
        [pagesVC setHidesBottomBarWhenPushed:YES];
        pagesVC.chapter = sender;
        NSString *key = ((MangaChapter *)sender).url.absoluteString;
        NSDictionary *metadata = @{kChapterRead:[NSNumber numberWithBool:YES]};
        NSURL *mangaURL = self.manga.url;
        NSURL *chapterURL = ((MangaChapter *)sender).url;
        NSDate *date = [NSDate date];
        UserLastRead *lastRead = [[UserLastRead alloc] init];
        [lastRead setValue:mangaURL forKey:NSStringFromSelector(@selector(mangaURL))];
        [lastRead setValue:chapterURL forKey:NSStringFromSelector(@selector(chapterURL))];
        [lastRead setValue:date forKey:NSStringFromSelector(@selector(date))];
        self.currentlyReadChapter = sender;
        [[[DBManager sharedManager] writeConnection] asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            if (![transaction hasObjectForKey:key inCollection:kMangaChapterCollection]) {
                [transaction setObject:sender forKey:key inCollection:kMangaChapterCollection withMetadata:metadata];
            } else {
                [transaction replaceMetadata:metadata forKey:key inCollection:kMangaChapterCollection];
            }
            NSLog(@"setting reading metadata %@", key);
            [transaction setObject:lastRead forKey:mangaURL.absoluteString inCollection:kUserLastReadCollection];
        } completionBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
        }];
        
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
        MangaChapter *chapter = [self chapterAtIndexPath:indexPath];
        MangaChapterCollectionViewCell *chapterCell = (MangaChapterCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:chapterIdentifier forIndexPath:indexPath];
        NSString *chapterIndex = [NSString stringWithFormat:@"#%d", chapter.index.intValue];
        NSString *chapterString = [NSString stringWithFormat:@"%@ %@", chapterIndex, chapter.title];
        NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:chapterString];
        [attr addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, chapterString.length)];
        [attr addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:[chapterString rangeOfString:chapterIndex]];
        [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:10] range:[chapterString rangeOfString:chapterIndex]];
        [chapterCell.nameLabel setAttributedText:attr];
        [chapterCell setAccessibilityLabel:chapter.title];
        
        __block NSDictionary *metadata;
        [[[DBManager sharedManager] readConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            metadata = [transaction metadataForKey:chapter.url.absoluteString inCollection:kMangaChapterCollection];
        }];
        [chapterCell setIsRead:NO];
        if (metadata) {
            BOOL isRead = [[metadata objectForKey:kChapterRead] boolValue];
            [chapterCell setIsRead:isRead];
        }
        if ([chapter.url.absoluteString isEqualToString:self.currentlyReadChapter.url.absoluteString]) {
            [chapterCell.isReadingLabel setHidden:NO];
            [chapterCell.isReadingLabel setText:NSLocalizedString(@"Reading", nil)];
            [chapterCell sizeToFit];
        } else [chapterCell.isReadingLabel setHidden:YES];
        [chapterCell.isReadingLabelBackground setHidden:chapterCell.isReadingLabel.isHidden];
        
        cell = chapterCell;
    }
    
    
    return cell;
}

- (MangaChapter *)chapterAtIndexPath:(NSIndexPath *)indexPath {
    if (self.ascending) {
        return [self.manga.chapters objectAtIndex:indexPath.item];
    }
    int count = (int)self.manga.chapters.count;
    return [self.manga.chapters objectAtIndex:count-indexPath.item-1];
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
        MangaChapter *chapter = [self chapterAtIndexPath:indexPath];
        [self performSegueWithIdentifier:@"showPages" sender:chapter];
    }
}

@end
