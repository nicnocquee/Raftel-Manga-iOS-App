//
//  MangaViewController.h
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Manga;
@class MangaSearchResult;

@interface MangaViewController : UICollectionViewController

@property (nonatomic, copy) Manga *manga;
@property (nonatomic, copy) MangaSearchResult *searchResult;

@end
