//
//  MangaChapter.m
//  Raftel
//
//  Created by  on 12/6/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "MangaChapter.h"
#import "MangaPage.h"
#import "NSString+Matches.h"
#import "NSArray+SourcesPlist.h"

NSString *const kChapterRead = @"com.raftelapp.chapterIsRead";

@interface MangaChapter ()

@property (nonatomic, strong) NSDictionary *configuration;

@end

@implementation MangaChapter

- (void)loadConfiguration {
    NSArray *sources = [NSArray sourcesPlist];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", self.source];
    self.configuration = [[sources filteredArrayUsingPredicate:predicate] firstObject];
}

- (NSArray *)pagesWithContentURLString:(NSString *)contentURLString {
    [self loadConfiguration];
    NSString *pagesPattern = self.configuration[@"manga"][@"pages"];
    NSArray *pagesStrings = [contentURLString matchesWithPattern:pagesPattern];
    NSString *host = self.configuration[@"host"];
    NSMutableArray *pages = [NSMutableArray arrayWithCapacity:pagesStrings.count];
    for (NSString *page in pagesStrings) {
        NSString *urlString = [NSString stringWithFormat:@"%@%@", host, page];
        NSURL *pageURL = [NSURL URLWithString:urlString];
        
        MangaPage *pageObject = [[MangaPage alloc] init];
        [pageObject setValue:pageURL forKey:NSStringFromSelector(@selector(url))];
        [pageObject setValue:self.source forKey:NSStringFromSelector(@selector(source))];
        [pages addObject:pageObject];
    }
    
    return pages;
}

- (NSURLSessionDataTask *)loadPagesWithCompletion:(void (^)(NSArray *pages, NSError *error))completion {
    __weak typeof (self) selfie = self;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:self.url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"pages downloaded");
        if (error) {
            if (completion) completion(nil, error);
        } else {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSArray *pages = [selfie pagesWithContentURLString:string];
            _pages = pages;
            if (completion) {
                completion(pages, nil);
            }
        }
    }];
    [task resume];
    return task;
}

@end
