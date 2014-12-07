//
//  MangaPageViewCell.m
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "MangaPageViewCell.h"

@implementation MangaPageViewCell

- (void)awakeFromNib {
    // Initialization code
    [self.scrollView setDelegate:self];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

@end
