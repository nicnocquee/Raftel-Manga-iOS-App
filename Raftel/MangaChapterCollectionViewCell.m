//
//  MangaChapterCollectionViewCell.m
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "MangaChapterCollectionViewCell.h"

@implementation MangaChapterCollectionViewCell

- (void)setIsRead:(BOOL)isRead {
    if (_isRead != isRead) {
        _isRead = isRead;
        
        [self.isReadView setHidden:_isRead];
    }
}

@end
