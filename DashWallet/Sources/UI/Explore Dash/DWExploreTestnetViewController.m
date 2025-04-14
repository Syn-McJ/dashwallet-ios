//
//  Created by Andrew Podkovyrin
//  Copyright © 2021 Dash Core Group. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "DWExploreTestnetViewController.h"

#import "DWEnvironment.h"
#import "DWExploreHeaderView.h"
#import "DWExploreTestnetContentsView.h"
#import "DWUIKit.h"
#import "dashwallet-Swift.h"
#import <objc/runtime.h>

@implementation DWExploreTestnetViewController

- (BOOL)requiresNoNavigationBar {
    return YES;
}

- (void)showAtms {
    DWExploreTestnetViewController *__weak weakSelf = self;

    AtmListViewController *vc = [[AtmListViewController alloc] init];
    vc.payWithDashHandler = ^{
        [weakSelf.delegate exploreTestnetViewControllerShowReceivePayment:weakSelf];
    };
    vc.sellDashHandler = ^{
        [weakSelf.delegate exploreTestnetViewControllerShowSendPayment:weakSelf];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showStakingIfSynced {
    if (SyncingActivityMonitor.shared.state == SyncingActivityMonitorStateSyncDone) {
        UIViewController *vc = [CrowdNodeModelObjcWrapper getRootVC];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else {
        [self notifyChainSyncing];
    }
}

- (void)notifyChainSyncing {
    NSString *title = NSLocalizedString(@"The chain is syncing…", nil);
    NSString *message = NSLocalizedString(@"Wait until the chain is fully synced, so we can review your transaction history. Visit CrowdNode website to log in or sign up.", nil);
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title
                         message:message
                  preferredStyle:UIAlertControllerStyleAlert];
    {
        UIAlertAction *action = [UIAlertAction
            actionWithTitle:NSLocalizedString(@"Go to CrowdNode website", nil)
                      style:UIAlertActionStyleDefault
                    handler:^(UIAlertAction *_Nonnull action) {
                        [[UIApplication sharedApplication] openURL:[CrowdNodeObjcWrapper crowdNodeWebsiteUrl]
                                                           options:@{}
                                                 completionHandler:^(BOOL success){
                                                 }];
                    }];
        [alert addAction:action];
    }

    {
        UIAlertAction *action = [UIAlertAction
            actionWithTitle:NSLocalizedString(@"Close", nil)
                      style:UIAlertActionStyleCancel
                    handler:nil];
        [alert addAction:action];
    }

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor dw_darkBlueColor];

    // Contents
    DWExploreHeaderView *headerView = [[DWExploreHeaderView alloc] init];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    headerView.image = [UIImage imageNamed:@"image.explore.dash.wallet"];
    headerView.title = NSLocalizedString(@"Explore Dash", nil);
    headerView.subtitle = NSLocalizedString(@"Find merchants that accept Dash, where to buy it and how to earn income with it.", nil);
    [headerView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];

    DWExploreTestnetViewController *__weak weakSelf = self;

    DWExploreTestnetContentsView *contentsView = [[DWExploreTestnetContentsView alloc] init];
    contentsView.translatesAutoresizingMaskIntoConstraints = NO;
    [headerView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    contentsView.whereToSpendHandler = ^{
        [weakSelf showWhereToSpendViewController];
    };
    contentsView.atmHandler = ^{
        [weakSelf showAtms];
    };
    contentsView.stakingHandler = ^{
        [weakSelf showStakingIfSynced];
    };

    UIStackView *parentView = [[UIStackView alloc] init];
    parentView.translatesAutoresizingMaskIntoConstraints = NO;
    parentView.distribution = UIStackViewDistributionEqualSpacing;
    parentView.axis = UILayoutConstraintAxisVertical;
    parentView.spacing = 34;

    [parentView addArrangedSubview:headerView];
    [parentView addArrangedSubview:contentsView];
    [self.view addSubview:parentView];

    [NSLayoutConstraint activateConstraints:@[
        [headerView.heightAnchor constraintLessThanOrEqualToConstant:kExploreHeaderViewHeight],
        [parentView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor
                                             constant:10],
        [parentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [parentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [parentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)buttonAction {
    DSAccount *account = [DWEnvironment sharedInstance].currentAccount;
    NSString *paymentAddress = account.receiveAddress;
    if (paymentAddress == nil) {
        return;
    }

    [UIPasteboard generalPasteboard].string = paymentAddress;
    NSURL *url = [NSURL URLWithString:@"https://testnet-faucet.dash.org/"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

@end
