//
//  Created by Andrew Podkovyrin
//  Copyright © 2019 Dash Core Group. All rights reserved.
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

#import "DWMainMenuViewController.h"

#import <DashSync/DashSync.h>

#import "DWAboutModel.h"
#import "DWExploreTestnetViewController.h"
#import "DWGlobalOptions.h"
#import "DWMainMenuContentView.h"
#import "DWMainMenuModel.h"
#import "DWSecurityMenuViewController.h"
#import "DWSettingsMenuViewController.h"
#import "DWToolsMenuViewController.h"
#import "DWUpholdViewController.h"
#import "SFSafariViewController+DashWallet.h"
#import "dashwallet-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWMainMenuViewController () <DWMainMenuContentViewDelegate,
                                        DWToolsMenuViewControllerDelegate,
                                        DWSettingsMenuViewControllerDelegate,
                                        DWExploreTestnetViewControllerDelegate>

@property (nonatomic, strong) DWMainMenuContentView *view;

@end

@implementation DWMainMenuViewController

@dynamic view;

- (instancetype)init {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.title = NSLocalizedString(@"More", nil);
    }
    return self;
}

- (void)loadView {
    const CGRect frame = [UIScreen mainScreen].bounds;
    self.view = [[DWMainMenuContentView alloc] initWithFrame:frame];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.view.model = [[DWMainMenuModel alloc] init];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    //    self.navigationController.navigationBar.prefersLargeTitles = NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - DWMainMenuContentViewDelegate

- (void)mainMenuContentView:(DWMainMenuContentView *)view didSelectMenuItem:(id<DWMainMenuItem>)item {
    switch (item.type) {
        case DWMainMenuItemType_BuySellDash: {
            [[DSAuthenticationManager sharedInstance]
                      authenticateWithPrompt:nil
                usingBiometricAuthentication:[DWGlobalOptions sharedInstance].biometricAuthEnabled
                              alertIfLockout:YES
                                  completion:^(BOOL authenticated, BOOL usedBiometrics, BOOL cancelled) {
                                      if (authenticated) {
                                          PortalViewController *controller = [PortalViewController controller];
                                          controller.hidesBottomBarWhenPushed = true;
                                          [self.navigationController pushViewController:controller animated:YES];
                                      }
                                  }];

            break;
        }
        case DWMainMenuItemType_Explore: {
            DWExploreTestnetViewController *controller = [[DWExploreTestnetViewController alloc] init];
            controller.delegate = self;
            DWNavigationController *nvc = [[DWNavigationController alloc] initWithRootViewController:controller];
            [self presentViewController:nvc animated:YES completion:nil];

            break;
        }
        case DWMainMenuItemType_Security: {
            DWSecurityMenuViewController *controller = [[DWSecurityMenuViewController alloc] init];
            controller.delegate = self.delegate;
            [self.navigationController pushViewController:controller animated:YES];

            break;
        }
        case DWMainMenuItemType_Settings: {
            DWSettingsMenuViewController *controller = [[DWSettingsMenuViewController alloc] init];
            controller.delegate = self;
            [self.navigationController pushViewController:controller animated:YES];

            break;
        }
        case DWMainMenuItemType_Tools: {
            DWToolsMenuViewController *controller = [[DWToolsMenuViewController alloc] init];
            controller.delegate = self;
            [self.navigationController pushViewController:controller animated:YES];

            break;
        }
        case DWMainMenuItemType_Support: {
            NSURL *url = [DWAboutModel supportURL];
            NSParameterAssert(url);
            if (!url) {
                return;
            }

            SFSafariViewController *safariViewController = [SFSafariViewController dw_controllerWithURL:url];
            [self presentViewController:safariViewController animated:YES completion:nil];
            break;
        }
    }
}

#pragma mark - DWToolsMenuViewControllerDelegate

- (void)toolsMenuViewControllerImportPrivateKey:(DWToolsMenuViewController *)controller {
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self.delegate mainMenuViewControllerImportPrivateKey:self];
}

#pragma mark - DWSettingsMenuViewControllerDelegate

- (void)settingsMenuViewControllerDidRescanBlockchain:(DWSettingsMenuViewController *)controller {
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self.delegate mainMenuViewControllerOpenHomeScreen:self];
}

#pragma mark - DWExploreTestnetViewControllerDelegate
- (void)exploreTestnetViewControllerShowSendPayment:(DWExploreTestnetViewController *)controller {
    [self.delegate showPaymentsControllerWithActivePage:DWPaymentsViewControllerIndex_Pay];
}

- (void)exploreTestnetViewControllerShowReceivePayment:(DWExploreTestnetViewController *)controller {
    [self.delegate showPaymentsControllerWithActivePage:DWPaymentsViewControllerIndex_Receive];
}

@end


NS_ASSUME_NONNULL_END
