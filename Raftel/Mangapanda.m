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
#import "MangaGenre.h"
#import "NSString+Matches.h"

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
    NSString *mangaAlternateNameRegexPattern = mangaDictionary[@"alternateName"];
    NSString *yearRegexPattern = mangaDictionary[@"year"];
    NSString *ongoingRegexPattern = mangaDictionary[@"ongoing"];
    NSString *authorRegexPattern = mangaDictionary[@"author"];
    NSString *artistRegexPattern = mangaDictionary[@"artist"];
    NSString *synopsisRegexPattern = mangaDictionary[@"synopsis"];
    NSString *synopsisParagraphRegexPattern = mangaDictionary[@"synopsis_paragraph"];
    NSString *coverRegexPattern = mangaDictionary[@"cover"];
    NSString *imgRegexPattern = mangaDictionary[@"cover_img"];
    NSString *genreListRegexPattern = mangaDictionary[@"genre_list"];
    NSString *genreItemRegexPattern = mangaDictionary[@"genre_item"];
    NSString *genreLinkRegexPattern = mangaDictionary[@"genre_link"];
    NSString *genreNameRegexPattern = mangaDictionary[@"genre_name"];
    NSString *chapterBlockRegexPattern = mangaDictionary[@"chapter_block"];
    NSString *chapterItemRegexPattern = mangaDictionary[@"chapter_item"];
    NSString *chapterLinkRegexPattern = mangaDictionary[@"chapter_link"];
    NSString *chapterNameRegexPattern = mangaDictionary[@"chapter_name"];
    NSString *host = self.configuration[@"host"];
    
    NSString *mangaName = [[contentURLString matchInWithPattern:mangaNameRegexPattern] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *alternateName = [[contentURLString matchInWithPattern:mangaAlternateNameRegexPattern] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *yearString = [contentURLString matchInWithPattern:yearRegexPattern];
    NSString *ongoingString = [contentURLString matchInWithPattern:ongoingRegexPattern];
    BOOL ongoing = [[ongoingString lowercaseString] isEqualToString:@"ongoing"];
    NSString *author = [contentURLString matchInWithPattern:authorRegexPattern];
    NSString *artist = [contentURLString matchInWithPattern:artistRegexPattern];
    NSString *synopsis = [contentURLString matchInWithPattern:synopsisRegexPattern];
    NSString *cleanedSynopsis = [synopsis matchInWithPattern:synopsisParagraphRegexPattern];
    NSString *imgDiv = [contentURLString matchInWithPattern:coverRegexPattern];
    NSString *imgString = [imgDiv matchInWithPattern:imgRegexPattern];
    NSURL *imgURL = [NSURL URLWithString:imgString];
    NSString *genreList = [contentURLString matchInWithPattern:genreListRegexPattern];
    NSArray *genresStrings = [genreList matchesWithPattern:genreItemRegexPattern];
    NSMutableArray *genres = [NSMutableArray arrayWithCapacity:genresStrings.count];
    for (NSString *genreString in genresStrings) {
        NSString *genreLinkString = [genreString matchInWithPattern:genreLinkRegexPattern];
        NSString *genreName = [genreString matchInWithPattern:genreNameRegexPattern];
        NSURL *genreURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", host, genreLinkString]];
        
        MangaGenre *genre = [[MangaGenre alloc] init];
        [genre setValue:genreURL forKey:NSStringFromSelector(@selector(URL))];
        [genre setValue:genreName forKey:NSStringFromSelector(@selector(name))];
        
        [genres addObject:genre];
    }
    NSString *chapterBlock = [contentURLString matchInWithPattern:chapterBlockRegexPattern];
    NSArray *chapterItems = [chapterBlock matchesWithPattern:chapterItemRegexPattern];
    NSMutableArray *chapters = [NSMutableArray arrayWithCapacity:chapterItems.count];
    int i = 0;
    for (NSString *chapter in chapterItems) {
        NSString *chapterLink = [chapter matchInWithPattern:chapterLinkRegexPattern];
        NSString *chapterName = [chapter matchInWithPattern:chapterNameRegexPattern];
        NSURL *chapterURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", host, chapterLink]];
        MangaChapter *c = [[MangaChapter alloc] init];
        [c setValue:chapterURL forKey:NSStringFromSelector(@selector(url))];
        [c setValue:chapterName forKey:NSStringFromSelector(@selector(title))];
        [c setValue:@"mangapanda" forKey:NSStringFromSelector(@selector(source))];
        [c setValue:@(i) forKey:NSStringFromSelector(@selector(index))];
        i++;
        [chapters addObject:c];
    }
    
    Manga *manga = [[Manga alloc] init];
    [manga setValue:mangaName forKey:NSStringFromSelector(@selector(name))];
    [manga setValue:self.configuration[@"name"] forKey:NSStringFromSelector(@selector(source))];
    [manga setValue:alternateName forKey:NSStringFromSelector(@selector(alternateName))];
    [manga setValue:yearString forKey:NSStringFromSelector(@selector(year))];
    [manga setValue:@(ongoing) forKey:NSStringFromSelector(@selector(ongoing))];
    [manga setValue:author forKey:NSStringFromSelector(@selector(author))];
    [manga setValue:artist forKey:NSStringFromSelector(@selector(artist))];
    [manga setValue:cleanedSynopsis forKey:NSStringFromSelector(@selector(synopsis))];
    if (imgURL) [manga setValue:imgURL forKey:NSStringFromSelector(@selector(coverURL))];
    [manga setValue:genres forKey:NSStringFromSelector(@selector(genre))];
    [manga setValue:chapters forKey:NSStringFromSelector(@selector(chapters))];
    return manga;
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
