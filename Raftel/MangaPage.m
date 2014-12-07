//
//  MangaPage.m
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "MangaPage.h"
#import "NSArray+SourcesPlist.h"
#import "NSString+Matches.h"

@interface MangaPage ()

@property (nonatomic, strong) NSDictionary *configuration;

@end

@implementation MangaPage

- (void)loadConfiguration {
    NSArray *sources = [NSArray sourcesPlist];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", self.source];
    self.configuration = [[sources filteredArrayUsingPredicate:predicate] firstObject];
}

- (NSURL *)imageURLWithContentURLString:(NSString *)contentURLString {
    [self loadConfiguration];
    NSString *pageImagePattern = self.configuration[@"manga"][@"page_image"];
    NSString *pageImageSrcPattern = self.configuration[@"manga"][@"page_image_src"];
    NSString *pageImageBlock = [contentURLString matchInWithPattern:pageImagePattern];
    NSString *pageImageURLString = [pageImageBlock matchInWithPattern:pageImageSrcPattern];
    NSURL *pageImageURL = [NSURL URLWithString:pageImageURLString];
    return pageImageURL;
}

- (void)loadImageURLWithCompletion:(void(^)(NSURL *imageURL, NSError *error))completion {
    if (self.imageURL) {
        if (completion) {
            completion(self.imageURL, nil);
        }
    } else {
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:self.url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                if (completion) completion(nil, error);
            } else {
                NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSURL *image = [self imageURLWithContentURLString:string];
                _imageURL = image;
                if (completion) {
                    completion(image, nil);
                }
            }
        }];
        [task resume];
    }
}

@end
