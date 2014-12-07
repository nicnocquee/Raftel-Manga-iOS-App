//
//  MangaPage.h
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <MTLModel.h>

@interface MangaPage : MTLModel

@property (nonatomic, copy, readonly) NSString *source;
@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, copy, readonly) NSURL *imageURL;

- (NSURL *)imageURLWithContentURLString:(NSString *)contentURLString;
- (void)loadImageURLWithCompletion:(void(^)(NSURL *imageURL, NSError *error))completion;

@end
