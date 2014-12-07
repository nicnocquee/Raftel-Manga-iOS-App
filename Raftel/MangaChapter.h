//
//  MangaChapter.h
//  Raftel
//
//  Created by  on 12/6/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MangaChapter : NSObject

@property (nonatomic, copy, readonly) NSNumber *index;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *source;
@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, copy, readonly) NSArray *pages;

- (void)loadPagesWithCompletion:(void(^)(NSArray *pages, NSError *error))completion;

@end
