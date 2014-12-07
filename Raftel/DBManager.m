//
//  DBManager.m
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "DBManager.h"
#import "Manga.h"
#import <YapDatabaseView.h>

NSString *const kSearchResultCollection = @"searchResults";
NSString *const kMangaCollection = @"mangas";
NSString *const kMangaChapterCollection = @"chapters";
NSString *const kMangaPageCollection = @"pages";
NSString *const kUserFavoriteView = @"user-favorite";
NSString *const kFavoritedDateKey = @"favorited-day";

@interface DBManager ()

@property (nonatomic, strong) YapDatabase *database;
@property (nonatomic, strong) YapDatabaseConnection *readConnection;
@property (nonatomic, strong) YapDatabaseConnection *writeConnection;

@end

@implementation DBManager

+ (instancetype)sharedManager {
    static DBManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[DBManager alloc] init];
    });
    
    return _sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _database = [[YapDatabase alloc] initWithPath:[self databasePath]];
        self.writeConnection = [self.database newConnection];
        self.readConnection = [self.database newConnection];
        
        self.readConnection.objectCacheLimit = 500; // increase object cache size
        self.readConnection.metadataCacheEnabled = NO; // not using metadata on this connection
        
        self.writeConnection.objectCacheEnabled = NO; // don't need cache for write-only connection
        self.writeConnection.metadataCacheEnabled = NO;
        
        YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withRowBlock:^NSString *(NSString *collection, NSString *key, Manga *object, NSDictionary *metadata) {
            if ([collection isEqualToString:kMangaCollection]) {
                if ([metadata objectForKey:kFavoritedDateKey]) {
                    return @"";
                }
            }
            return nil;
        }];
        
        YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withMetadataBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, NSDictionary *metadata, NSString *collection2, NSString *key2, NSDictionary *metadata2) {
            NSDate *favDate1 = [metadata objectForKey:kFavoritedDateKey];
            NSDate *favDate2 = [metadata2 objectForKey:kFavoritedDateKey];
            return [favDate2 compare:favDate1];
        }];
        
        YapDatabaseView *view = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:@"1.0"];
        [_database registerExtension:view withName:kUserFavoriteView];
    }
    return self;
}

- (NSString *)databasePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    
    NSString *databaseName = @"database.sqlite";
    
    return [baseDir stringByAppendingPathComponent:databaseName];
}

@end
