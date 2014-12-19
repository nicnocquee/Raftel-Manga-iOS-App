//
//  LoginViewController.m
//  Raftel
//
//  Created by  on 12/19/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIColor *darkColor = [UIColor colorWithRed:0.118 green:0.125 blue:0.157 alpha:1.000];
    self.view.backgroundColor = darkColor;
    
    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Raftel"]];
    [logoView setContentMode:UIViewContentModeScaleAspectFill];
    self.logInView.logo = logoView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - <PFSignUpViewControllerDelegate>

- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    if (user) {
        [signUpController dismissViewControllerAnimated:YES completion:^{
            [self.delegate logInViewController:self didLogInUser:user];
        }];
    }
}

- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    [signUpController dismissViewControllerAnimated:YES completion:nil];
}

@end
