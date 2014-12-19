//
//  FavoritedViewCollectionViewController.m
//  Raftel
//
//  Created by  on 12/8/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "FavoritedViewCollectionViewController.h"
#import "SearchResultCell.h"
#import "DBManager.h"
#import "MangaViewController.h"
#import "Manga.h"
#import "AppDelegate.h"
#import <UIImageView+WebCache.h>

static CGFloat const cellSpacing = 10;

static int const column = 3;

static NSString *const favoriteCellIdentifier = @"searchResult";

@interface FavoritedViewCollectionViewController ()

@property (nonatomic, strong) YapDatabaseConnection *readConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *databaseViewMappings;

@end

@implementation FavoritedViewCollectionViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Collections", nil);
    
    self.readConnection = [[[DBManager sharedManager] database] newConnection];
    
    self.readConnection.objectCacheLimit = 500; // increase object cache size
    self.readConnection.metadataCacheEnabled = NO; // not using metadata on this connection
    
    self.databaseViewMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[@""] view:kUserFavoriteView];
    
    [self.readConnection beginLongLivedReadTransaction];
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.databaseViewMappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:nil];
    
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([SearchResultCell class]) bundle:nil] forCellWithReuseIdentifier:favoriteCellIdentifier];
    // Do any additional setup after loading the view.
    
    UIBarButtonItem *setting = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Setting"] style:UIBarButtonItemStyleDone target:self action:@selector(didTapSetting:)];
    [self.navigationItem setLeftBarButtonItem:setting];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons

- (void)didTapSetting:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Remove ads", nil) preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [((AppDelegate *)[[UIApplication sharedApplication] delegate]) removeAds];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:action];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showMangaFromFavorite"]) {
        MangaViewController *mangaVC = (MangaViewController *)segue.destinationViewController;
        [mangaVC setHidesBottomBarWhenPushed:YES];
        mangaVC.manga = sender;
    }
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.databaseViewMappings numberOfSections];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.databaseViewMappings numberOfItemsInSection:section];
}

#pragma mark <UICollectionViewDelegate>

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SearchResultCell *cell = (SearchResultCell *)[collectionView dequeueReusableCellWithReuseIdentifier:favoriteCellIdentifier forIndexPath:indexPath];
    
    __block Manga *manga;
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        manga = [[transaction ext:kUserFavoriteView] objectAtIndexPath:indexPath withMappings:self.databaseViewMappings];
    }];
    [cell.imageView sd_setImageWithURL:manga.coverURL];
    [cell.searchName setText:manga.name];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = floorf((CGRectGetWidth(self.collectionView.frame)-(column+1)*cellSpacing)/column);
    return CGSizeMake(width, 200);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return cellSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return cellSpacing;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(cellSpacing, cellSpacing, cellSpacing, cellSpacing);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    __block Manga *result;
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        result = [[transaction ext:kUserFavoriteView] objectAtIndexPath:indexPath withMappings:self.databaseViewMappings];
    }];
    [self performSegueWithIdentifier:@"showMangaFromFavorite" sender:result];
}

#pragma mark - Notifications

- (void)yapDatabaseModified:(NSNotification *)sender {
    [self.readConnection beginLongLivedReadTransaction];
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.databaseViewMappings updateWithTransaction:transaction];
    }];
    
    [self.collectionView reloadData];
}

@end
