//
//  Mangapanda.h
//  Raftel
//
//  Created by  on 12/6/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Manga;

@interface Mangapanda : NSObject

@property (nonatomic, strong) NSDictionary *configuration;

- (Manga *)mangaWithContentURLString:(NSString *)contentURLString;
+ (NSArray *)popularMangas;
+ (NSArray *)list;
+ (void)mangaWithURL:(NSURL *)URL completion:(void(^)(Manga *manga, NSError *error))completion;

@end
