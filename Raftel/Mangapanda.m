//
//  Mangapanda.m
//  Raftel
//
//  Created by  on 12/6/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "Mangapanda.h"
#import "Manga.h"
#import "MangaChapter.h"

@interface Mangapanda ()

@end

@implementation Mangapanda

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSArray *sources = [self.class sourcesPlist];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", @"mangapanda"];
        self.configuration = [[sources filteredArrayUsingPredicate:predicate] firstObject];
    }
    return self;
}

- (Manga *)mangaWithContentURLString:(NSString *)contentURLString {
    NSDictionary *mangaDictionary = self.configuration[@"manga"];
    NSString *mangaNameRegexPattern = mangaDictionary[@"name"];
    
    NSString *mangaName = [self matchInString:contentURLString pattern:mangaNameRegexPattern];
    
    Manga *manga = [[Manga alloc] init];
    [manga setValue:mangaName forKey:NSStringFromSelector(@selector(name))];
    [manga setValue:self.configuration[@"name"] forKey:NSStringFromSelector(@selector(source))];
    
    return manga;
}

- (NSString *)matchInString:(NSString *)string pattern:(NSString *)pattern {
    NSError *error;
    NSRegularExpression *mangaNameRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        return nil;
    }
    NSArray *matches = [mangaNameRegex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    NSTextCheckingResult *mangaNameResult = [matches firstObject];
    NSRange range = mangaNameResult.range;
    return [string substringWithRange:range];
}

+ (NSArray *)sourcesPlist {
    NSPropertyListFormat format;
    NSString *plistPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sources.plist"]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:@"sources" ofType:@"plist"];
    }
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSError *error;
    NSArray *temp = (NSArray *)[NSPropertyListSerialization
                                propertyListWithData:plistXML options:0 format:&format error:&error];
    
    return temp;
}

+ (NSArray *)popularMangas {
    return nil;
}

+ (NSArray *)list {
    return nil;
}

+ (void)mangaWithURL:(NSURL *)URL completion:(void (^)(Manga *manga, NSError *error))completion {
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
        } else {
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            Mangapanda *panda = [[Mangapanda alloc] init];
            Manga *manga = [panda mangaWithContentURLString:dataString];
            if (completion) {
                completion(manga, nil);
            }
        }
    }];
    [task resume];
}

@end
