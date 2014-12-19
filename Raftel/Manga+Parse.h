//
//  Manga+Parse.h
//  Raftel
//
//  Created by  on 12/19/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "Manga.h"
#import <Parse/Parse.h>

static NSString *const readingCountKey = @"readingCount";
static NSString *parseCommentStringKey = @"parseCommentStringKey";
static NSString *parseCommentMangaKey = @"parseCommentMangaKey";
static NSString *parseCommentUsernameKey = @"parseCommentUsernameKey";
static NSString *parseCommentAvatarKey = @"parseCommentAvatarKey";

@interface Manga (Parse)

- (void)refreshPFObjectWithCompletionBlock:(void(^)(PFObject *mangaPFObject))completionBlock;
- (void)queryReadingCountWithCompletionBlock:(void(^)(int count))completionBlock;
- (void)createMangaIfNeededWithCompletionBlock:(void(^)(PFObject *mangaPFObject))completionBlock;
- (void)incrementReadingCountWithCompletionBlock:(void(^)(int readingCount))completionBlock;
- (void)setParseObject:(PFObject *)parseObjectId;
- (PFObject *)parseObject;
- (void)setReadingCount:(int)readingCount;
- (int)readingCount;
- (int)commentsCount;
- (void)fetchCommentsWithCompletionBlock:(void(^)(NSArray *comments))completionBlock;
- (void)addComment:(NSString *)comment completionBlock:(void(^)())completionBlock;
- (void)countCommentsWithCompletionBlock:(void(^)(int count))completionBlock;

@end
