//
//  NSString+Matches.h
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Matches)

- (NSString *)matchInWithPattern:(NSString *)pattern;
- (NSArray *)matchesWithPattern:(NSString *)pattern;

@end
