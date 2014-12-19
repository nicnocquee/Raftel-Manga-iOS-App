//
//  CommentsTableViewController.m
//  Raftel
//
//  Created by  on 12/19/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "CommentsTableViewController.h"
#import "MangaComment.h"
#import "LoginViewController.h"
#import "CommentCell.h"
#import "CommentEntryViewController.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <MBProgressHUD.h>

static NSString *const cellIdentifier = @"comment";

@interface CommentsTableViewController () <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, CommentEntryViewControllerDelegate>

@property (nonatomic, strong) NSArray *comments;

@end

@implementation CommentsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CommentCell class]) bundle:nil] forCellReuseIdentifier:cellIdentifier];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(didTapDoneButton:)];
    UIBarButtonItem *addComment = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(didTapComposeButton:)];
    [self.navigationItem setRightBarButtonItem:addComment];
    [self.navigationItem setLeftBarButtonItem:doneButton];
    
    [self fetchComments];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchComments {
    __weak typeof (self) selfie = self;
    [self.tableView setScrollEnabled:NO];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    [self.manga fetchCommentsWithCompletionBlock:^(NSArray *comments, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:selfie.tableView animated:YES];
                [selfie.tableView setScrollEnabled:YES];
                [selfie.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
                selfie.comments = comments;
                [selfie.tableView reloadData];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:selfie.tableView animated:YES];
                [selfie.tableView setScrollEnabled:YES];
                [selfie.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:error.description preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *dismiss = [UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:dismiss];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showCommentEntry"]) {
        CommentEntryViewController *entry = (CommentEntryViewController *)[((UINavigationController *)segue.destinationViewController).viewControllers firstObject];
        [entry setManga:self.manga];
        [entry setDelegate:self];
    }
}

#pragma mark - Buttons

- (void)didTapDoneButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didTapComposeButton:(id)sender {
    if (![PFUser currentUser]) {
        LoginViewController *logInController = [[LoginViewController alloc] init];
        logInController.delegate = self;
        SignUpViewController *signupController = [[SignUpViewController alloc] init];
        [signupController setDelegate:logInController];
        signupController.fields = (PFSignUpFieldsUsernameAndPassword
                                   | PFSignUpFieldsSignUpButton
                                   | PFSignUpFieldsDismissButton);
        logInController.signUpController = signupController;
        [self presentViewController:logInController animated:YES completion:nil];
    } else {
        [self openCommentEntry];
    }
}

- (void)openCommentEntry {
    [self performSegueWithIdentifier:@"showCommentEntry" sender:nil];
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
    MangaComment *comment = [self.comments objectAtIndex:indexPath.row];
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

#pragma mark - <PFLogInViewControllerDelegate>

- (void)logInViewController:(PFLogInViewController *)controller
               didLogInUser:(PFUser *)user {
    if (user) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self openCommentEntry];
        }];
    }
}

- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - <CommentEntryViewControllerDelegate>

- (void)commentEntry:(CommentEntryViewController *)commentEntry didSendComment:(NSString *)comment {
    [commentEntry dismissViewControllerAnimated:YES completion:^{
        [self fetchComments];
    }];
}

- (void)commentEntryDidCancel:(CommentEntryViewController *)commentEntry {
    [commentEntry dismissViewControllerAnimated:YES completion:^{
        [self fetchComments];
    }];
}

@end
