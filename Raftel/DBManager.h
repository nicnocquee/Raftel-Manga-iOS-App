//
//  DBManager.h
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YapDatabase.h>
#import <YapDatabaseConnection.h>
#import <YapDatabaseView.h>

extern NSString *const kSearchResultCollection;
extern NSString *const kMangaCollection;
extern NSString *const kMangaChapterCollection;
extern NSString *const kMangaPageCollection;
extern NSString *const kUserFavoriteView;
extern NSString *const kFavoritedDateKey;

@interface DBManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong, readonly) YapDatabase *database;
@property (nonatomic, strong, readonly) YapDatabaseConnection *readConnection;
@property (nonatomic, strong, readonly) YapDatabaseConnection *writeConnection;

- (YapDatabaseView *)favoritedView;

@end
