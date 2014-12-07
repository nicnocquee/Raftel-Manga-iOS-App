//
//  MangaChapter.h
//  Raftel
//
//  Created by  on 12/6/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <MTLModel.h>

@interface MangaChapter : MTLModel

@property (nonatomic, copy, readonly) NSNumber *index;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *source;
@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, copy, readonly) NSArray *pages;

- (NSArray *)pagesWithContentURLString:(NSString *)contentURLString;
- (void)loadPagesWithCompletion:(void(^)(NSArray *pages, NSError *error))completion;

@end
