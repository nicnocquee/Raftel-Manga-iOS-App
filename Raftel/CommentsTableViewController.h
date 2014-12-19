//
//  CommentsTableViewController.h
//  Raftel
//
//  Created by  on 12/19/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Manga.h"
#import "Manga+Parse.h"

@interface CommentsTableViewController : UITableViewController

@property (nonatomic, strong) Manga *manga;

@end
