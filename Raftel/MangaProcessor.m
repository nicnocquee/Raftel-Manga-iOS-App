//
//  MangaProcessor.m
//  Raftel
//
//  Created by  on 12/8/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "MangaProcessor.h"
#import "NSString+Matches.h"
#import "NSArray+SourcesPlist.h"
#import "MangaGenre.h"
#import "MangaChapter.h"
#import "Manga.h"

@implementation MangaProcessor

+ (instancetype)sharedProcessor {
    static MangaProcessor *_sharedProcessor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedProcessor = [[MangaProcessor alloc] init];
    });
    
    return _sharedProcessor;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        [self.operationQueue setMaxConcurrentOperationCount:1];
        [self.operationQueue setName:@"manga-operation"];
    }
    return self;
}

- (NSOperation *)processMangaFromURL:(NSURL *)url contentString:(NSString *)contentString completion:(void (^)(Manga *))completion didProcessChapter:(void(^)(MangaChapter *chapter, int totalChapter))didProcessChapter {
    NSArray *sources = [NSArray sourcesPlist];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", @"mangapanda"];
    NSDictionary *configuration = [[sources filteredArrayUsingPredicate:predicate] firstObject];
    
    NSBlockOperation *blockOperation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakOperation = blockOperation;
    
    [blockOperation addExecutionBlock:^{
        if ([weakOperation isCancelled]) {
            return;
        }
        NSDictionary *mangaDictionary = configuration[@"manga"];
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
        NSString *host = configuration[@"host"];
        
        NSString *mangaName = [[contentString matchInWithPattern:mangaNameRegexPattern] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *alternateName = [[contentString matchInWithPattern:mangaAlternateNameRegexPattern] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *yearString = [contentString matchInWithPattern:yearRegexPattern];
        NSString *ongoingString = [contentString matchInWithPattern:ongoingRegexPattern];
        BOOL ongoing = [[ongoingString lowercaseString] isEqualToString:@"ongoing"];
        NSString *author = [contentString matchInWithPattern:authorRegexPattern];
        NSString *artist = [contentString matchInWithPattern:artistRegexPattern];
        NSString *synopsis = [contentString matchInWithPattern:synopsisRegexPattern];
        NSString *cleanedSynopsis = [synopsis matchInWithPattern:synopsisParagraphRegexPattern];
        NSString *imgDiv = [contentString matchInWithPattern:coverRegexPattern];
        NSString *imgString = [imgDiv matchInWithPattern:imgRegexPattern];
        NSURL *imgURL = [NSURL URLWithString:imgString];
        NSString *genreList = [contentString matchInWithPattern:genreListRegexPattern];
        NSArray *genresStrings = [genreList matchesWithPattern:genreItemRegexPattern];
        NSMutableArray *genres = [NSMutableArray arrayWithCapacity:genresStrings.count];
        
        for (NSString *genreString in genresStrings) {
            if ([weakOperation isCancelled]) {
                return;
            }
            NSString *genreLinkString = [genreString matchInWithPattern:genreLinkRegexPattern];
            NSString *genreName = [genreString matchInWithPattern:genreNameRegexPattern];
            NSURL *genreURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", host, genreLinkString]];
            
            MangaGenre *genre = [[MangaGenre alloc] init];
            [genre setValue:genreURL forKey:NSStringFromSelector(@selector(URL))];
            [genre setValue:genreName forKey:NSStringFromSelector(@selector(name))];
            
            [genres addObject:genre];
        }
        NSString *chapterBlock = [contentString matchInWithPattern:chapterBlockRegexPattern];
        NSArray *chapterItems = [chapterBlock matchesWithPattern:chapterItemRegexPattern];
        NSMutableArray *chapters = [NSMutableArray arrayWithCapacity:chapterItems.count];
        int i = 0;
        int total = (int)chapterItems.count;
        for (NSString *chapter in chapterItems) {
            if ([weakOperation isCancelled]) {
                break;
            }
            NSString *chapterLink = [chapter matchInWithPattern:chapterLinkRegexPattern];
            NSString *chapterName = [chapter matchInWithPattern:chapterNameRegexPattern];
            NSURL *chapterURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", host, chapterLink]];
            MangaChapter *c = [[MangaChapter alloc] init];
            [c setValue:chapterURL forKey:NSStringFromSelector(@selector(url))];
            [c setValue:chapterName forKey:NSStringFromSelector(@selector(title))];
            [c setValue:@"mangapanda" forKey:NSStringFromSelector(@selector(source))];
            [c setValue:@(i) forKey:NSStringFromSelector(@selector(index))];
            
            if (didProcessChapter) {
                didProcessChapter(c, total);
            }
            
            i++;
            [chapters addObject:c];
        }
        
        Manga *manga = [[Manga alloc] init];
        [manga setValue:mangaName forKey:NSStringFromSelector(@selector(name))];
        [manga setValue:configuration[@"name"] forKey:NSStringFromSelector(@selector(source))];
        [manga setValue:alternateName forKey:NSStringFromSelector(@selector(alternateName))];
        [manga setValue:yearString forKey:NSStringFromSelector(@selector(year))];
        [manga setValue:@(ongoing) forKey:NSStringFromSelector(@selector(ongoing))];
        [manga setValue:author forKey:NSStringFromSelector(@selector(author))];
        [manga setValue:artist forKey:NSStringFromSelector(@selector(artist))];
        [manga setValue:cleanedSynopsis forKey:NSStringFromSelector(@selector(synopsis))];
        if (imgURL) [manga setValue:imgURL forKey:NSStringFromSelector(@selector(coverURL))];
        [manga setValue:genres forKey:NSStringFromSelector(@selector(genre))];
        [manga setValue:chapters forKey:NSStringFromSelector(@selector(chapters))];
        
        if ([weakOperation isCancelled]) {
            return;
        }
        if (completion) {
            completion(manga);
        }
    }];
    
    [self.operationQueue addOperation:blockOperation];
    return blockOperation;
}

@end
