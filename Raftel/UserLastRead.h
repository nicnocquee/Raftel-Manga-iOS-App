//
//  UserLastRead.h
//  Raftel
//
//  Created by  on 12/8/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "MTLModel.h"

@interface UserLastRead : MTLModel

@property (nonatomic, copy, readonly) NSURL *mangaURL;
@property (nonatomic, copy, readonly) NSURL *chapterURL;
@property (nonatomic, copy, readonly) NSDate *date;

@end
