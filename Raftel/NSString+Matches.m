//
//  NSString+Matches.m
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "NSString+Matches.h"

@implementation NSString (Matches)

- (NSString *)matchInWithPattern:(NSString *)pattern {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        return nil;
    }
    NSArray *matches = [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    NSTextCheckingResult *result = [matches firstObject];
    NSRange range = result.range;
    return [self substringWithRange:range];
}

- (NSArray *)matchesWithPattern:(NSString *)pattern {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        return nil;
    }
    NSArray *matches = [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:matches.count];
    for (NSTextCheckingResult *result in matches) {
        [results addObject:[self substringWithRange:result.range]];
    }
    return results;
}

@end
