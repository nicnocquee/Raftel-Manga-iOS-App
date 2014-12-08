//
//  MangaChapterCollectionViewCell.h
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MangaChapterCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *isReadView;
@property (nonatomic,assign) BOOL isRead;
@property (weak, nonatomic) IBOutlet UILabel *isReadingLabel;
@property (weak, nonatomic) IBOutlet UIView *isReadingLabelBackground;

@end
