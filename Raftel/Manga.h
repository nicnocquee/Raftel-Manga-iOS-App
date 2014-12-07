//
//  Manga.h
//  Raftel
//
//  Created by  on 12/6/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <MTLModel.h>

@interface Manga : MTLModel

@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, copy, readonly) NSString *source;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *alternateName;
@property (nonatomic, copy, readonly) NSString *year;
@property (nonatomic, copy, readonly) NSNumber *ongoing;
@property (nonatomic, copy, readonly) NSString *author;
@property (nonatomic, copy, readonly) NSString *artist;
@property (nonatomic, copy, readonly) NSArray *genre;
@property (nonatomic, copy, readonly) NSArray *chapters;
@property (nonatomic, copy, readonly) NSString *synopsis;
@property (nonatomic, copy, readonly) NSURL *coverURL;

@end
