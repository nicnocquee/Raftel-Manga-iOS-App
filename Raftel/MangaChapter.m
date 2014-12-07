//
//  MangaChapter.m
//  Raftel
//
//  Created by  on 12/6/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "MangaChapter.h"
#import "NSString+Matches.h"
#import "NSArray+SourcesPlist.h"

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
        if (pageURL) {
            [pages addObject:pageURL];
        }
    }
    
    return pages;
}

- (void)loadPagesWithCompletion:(void (^)(NSArray *pages, NSError *error))completion {
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:self.url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
        } else {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSArray *pages = [self pagesWithContentURLString:string];
            if (completion) {
                completion(pages, nil);
            }
        }
    }];
    [task resume];
}

@end
