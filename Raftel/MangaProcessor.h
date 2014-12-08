//
//  MangaProcessor.h
//  Raftel
//
//  Created by  on 12/8/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Manga;
@class MangaChapter;

@interface MangaProcessor : NSObject

@property (nonatomic, strong) NSOperationQueue *operationQueue;

+ (instancetype)sharedProcessor;

- (NSOperation *)processMangaFromURL:(NSURL *)url contentString:(NSString *)contentString completion:(void (^)(Manga *))completion didProcessChapter:(void(^)(MangaChapter *chapter, int totalCount))didProcessChapter ;

@end
