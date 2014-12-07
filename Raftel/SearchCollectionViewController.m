//
//  SearchCollectionViewController.m
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "SearchCollectionViewController.h"
#import "SearchResultCell.h"
#import "Mangapanda.h"
#import "MangaSearchResult.h"
#import <UIImageView+WebCache.h>
#import <SVProgressHUD.h>
#import <SIAlertView.h>

static CGFloat const cellSpacing = 10;

static int const column = 3;

static NSString *const searchResultCellIdentifier = @"searchResult";

@interface SearchCollectionViewController () <UISearchBarDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSArray *searches;
@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation SearchCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([SearchResultCell class]) bundle:nil] forCellWithReuseIdentifier:searchResultCellIdentifier];
    
    self.searchBar = [[UISearchBar alloc] init];
    [self.searchBar setPlaceholder:NSLocalizedString(@"Search manga", nil)];
    [self.searchBar setDelegate:self];
    [self.navigationItem setTitleView:self.searchBar];
    [self.searchBar sizeToFit];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.searches.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SearchResultCell *cell = (SearchResultCell *)[collectionView dequeueReusableCellWithReuseIdentifier:searchResultCellIdentifier forIndexPath:indexPath];
    MangaSearchResult *result = [self.searches objectAtIndex:indexPath.item];
    [cell.imageView sd_setImageWithURL:result.imageURL];
    cell.searchName.text = result.name;
    
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

#pragma mark <UISearchBarDelegate>

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar endEditing:YES];
    [SVProgressHUD show];
    if ([searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
        [Mangapanda search:searchBar.text completion:^(NSArray *results, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                if (error) {
                    NSLog(@"Error %@", error);
                    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:NSLocalizedString(@"Search Error", NSInteger) andMessage:error.localizedDescription];
                    
                    [alertView addButtonWithTitle:NSLocalizedString(@"Dismiss", nil)
                                             type:SIAlertViewButtonTypeCancel
                                          handler:^(SIAlertView *alert) {
                                              NSLog(@"Button1 Clicked");
                                          }];
                    [alertView show];
                } else {
                    self.searches = results;
                    [self.collectionView reloadData];
                }
            });
        }];
    }
}

@end
