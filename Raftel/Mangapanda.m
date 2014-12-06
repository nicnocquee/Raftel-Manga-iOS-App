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
    NSString *host = self.configuration[@"host"];
    
    NSString *mangaName = [[self matchInString:contentURLString pattern:mangaNameRegexPattern] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *alternateName = [[self matchInString:contentURLString pattern:mangaAlternateNameRegexPattern] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *yearString = [self matchInString:contentURLString pattern:yearRegexPattern];
    NSString *ongoingString = [self matchInString:contentURLString pattern:ongoingRegexPattern];
    BOOL ongoing = [[ongoingString lowercaseString] isEqualToString:@"ongoing"];
    NSString *author = [self matchInString:contentURLString pattern:authorRegexPattern];
    NSString *artist = [self matchInString:contentURLString pattern:artistRegexPattern];
    NSString *synopsis = [self matchInString:contentURLString pattern:synopsisRegexPattern];
    NSString *cleanedSynopsis = [self matchInString:synopsis pattern:synopsisParagraphRegexPattern];
    NSString *imgDiv = [self matchInString:contentURLString pattern:coverRegexPattern];
    NSString *imgString = [self matchInString:imgDiv pattern:imgRegexPattern];
    NSURL *imgURL = [NSURL URLWithString:imgString];
    NSString *genreList = [self matchInString:contentURLString pattern:genreListRegexPattern];
    NSArray *genresStrings = [self matchesInString:genreList pattern:genreItemRegexPattern];
    NSMutableArray *genres = [NSMutableArray arrayWithCapacity:genresStrings.count];
    for (NSString *genreString in genresStrings) {
        NSString *genreLinkString = [self matchInString:genreString pattern:genreLinkRegexPattern];
        NSString *genreName = [self matchInString:genreString pattern:genreNameRegexPattern];
        NSURL *genreURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", host, genreLinkString]];
        
        MangaGenre *genre = [[MangaGenre alloc] init];
        [genre setValue:genreURL forKey:NSStringFromSelector(@selector(URL))];
        [genre setValue:genreName forKey:NSStringFromSelector(@selector(name))];
        
        [genres addObject:genre];
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
    
    return manga;
}

- (NSString *)matchInString:(NSString *)string pattern:(NSString *)pattern {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        return nil;
    }
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    NSTextCheckingResult *result = [matches firstObject];
    NSRange range = result.range;
    return [string substringWithRange:range];
}

- (NSArray *)matchesInString:(NSString *)string pattern:(NSString *)pattern {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        return nil;
    }
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:matches.count];
    for (NSTextCheckingResult *result in matches) {
        [results addObject:[string substringWithRange:result.range]];
    }
    return results;
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
