//
//  CommentEntryViewController.h
//  Raftel
//
//  Created by  on 12/19/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Manga.h"

@class CommentEntryViewController;

@protocol CommentEntryViewControllerDelegate <NSObject>

@optional
- (void)commentEntry:(CommentEntryViewController *)commentEntry didSendComment:(NSString *)comment;
- (void)commentEntryDidCancel:(CommentEntryViewController *)commentEntry;

@end

@interface CommentEntryViewController : UIViewController

@property (nonatomic, strong) Manga *manga;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, weak) id<CommentEntryViewControllerDelegate>delegate;

@end
