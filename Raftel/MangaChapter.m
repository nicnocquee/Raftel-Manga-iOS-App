//
//  MangaChapter.m
//  Raftel
//
//  Created by  on 12/6/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "MangaChapter.h"
#import "NSString+Matches.h"

@implementation MangaChapter

- (void)loadPagesWithCompletion:(void (^)(NSArray *pages, NSError *error))completion {
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:self.url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
        } else {
            
        }
    }];
    [task resume];
}

@end
