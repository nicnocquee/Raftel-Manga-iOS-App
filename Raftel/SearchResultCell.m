//
//  SearchResultCell.m
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "SearchResultCell.h"

@implementation SearchResultCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.layer.borderColor = [UIColor colorWithWhite:0.880 alpha:1.000].CGColor;
    self.layer.borderWidth = 1;
}

@end
