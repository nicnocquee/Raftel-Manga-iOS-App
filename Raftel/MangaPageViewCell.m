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
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapScrollView:)];
    [tapGesture setNumberOfTapsRequired:2];
    [self.scrollView addGestureRecognizer:tapGesture];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)didDoubleTapScrollView:(UITapGestureRecognizer *)gesture {
    CGPoint touch = [gesture locationInView:self.imageView];
    if (self.scrollView.zoomScale == 1) [self.scrollView zoomToRect:(CGRect){touch, CGSizeMake(20, 20)} animated:YES];
    else [self.scrollView setZoomScale:1 animated:YES];
}

@end
