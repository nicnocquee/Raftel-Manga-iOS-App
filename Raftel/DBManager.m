//
//  DBManager.m
//  Raftel
//
//  Created by  on 12/7/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "DBManager.h"

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
