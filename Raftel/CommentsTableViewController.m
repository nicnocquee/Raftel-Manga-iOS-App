//
//  CommentsTableViewController.m
//  Raftel
//
//  Created by  on 12/19/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "CommentsTableViewController.h"
#import "Comment.h"
#import "CommentCell.h"

static NSString *const cellIdentifier = @"comment";

@interface CommentsTableViewController ()

@property (nonatomic, strong) NSArray *comments;

@end

@implementation CommentsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CommentCell class]) bundle:nil] forCellReuseIdentifier:cellIdentifier];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(didTapDoneButton:)];
    [self.navigationItem setRightBarButtonItem:doneButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons

- (void)didTapDoneButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CommentCell *cell = (CommentCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    Comment *comment = [self.comments objectAtIndex:indexPath.row];
    NSString *username = comment.username;
    NSString *commentString = comment.string;
    NSString *text = [NSString stringWithFormat:@"%@ %@", username, commentString];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text];
    [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:14] range:[text rangeOfString:username]];
    [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:[text rangeOfString:commentString]];
    [attr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.163 green:0.339 blue:0.538 alpha:1.000] range:[text rangeOfString:username]];
    [attr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.274 alpha:1.000] range:[text rangeOfString:commentString]];
    [cell.commentLabel setAttributedText:attr];
    [cell setNeedsLayout];
    return cell;
}

@end
