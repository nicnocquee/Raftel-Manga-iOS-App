//
//  Comment.h
//  Raftel
//
//  Created by  on 12/19/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "MTLModel.h"

@interface Comment : MTLModel

@property (nonatomic, copy, readonly) NSString *string;
@property (nonatomic, copy, readonly) NSString *userId;
@property (nonatomic, copy, readonly) NSString *username;
@property (nonatomic, copy, readonly) NSString *avatar;
@property (nonatomic, copy, readonly) NSDate *createdAt;
@property (nonatomic, copy, readonly) NSString *mangaURL;

@end
