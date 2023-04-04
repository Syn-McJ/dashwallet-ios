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

#import "DWHomeViewController+DWShortcuts.h"

#import <DashSync/DashSync.h>

#import "DWBackupInfoViewController.h"
#import "DWDashPaySetupFlowController.h"
#import "DWExploreTestnetViewController.h"
#import "DWGlobalOptions.h"
#import "DWHomeViewController+DWImportPrivateKeyDelegateImpl.h"
#import "DWHomeViewController+DWSecureWalletDelegateImpl.h"
#import "DWLocalCurrencyViewController.h"
#import "DWPayModelProtocol.h"
#import "DWPreviewSeedPhraseModel.h"
#import "DWSettingsMenuModel.h"
#import "DWUpholdViewController.h"
#import "dashwallet-Swift.h"
NS_ASSUME_NONNULL_BEGIN

@interface DWHomeViewController (DWShortcuts_Internal) <DWLocalCurrencyViewControllerDelegate, DWExploreTestnetViewControllerDelegate>

@end

@implementation DWHomeViewController (DWShortcuts)

- (void)performActionForShortcut:(DWShortcutAction *)action sender:(UIView *)sender {
    const DWShortcutActionType type = action.type;
    switch (type) {
        case DWShortcutActionTypeSecureWallet: {
            [self secureWalletAction];
            break;
        }
        case DWShortcutActionTypeScanToPay: {
            [self performScanQRCodeAction];
            break;
        }
        case DWShortcutActionTypePayToAddress: {
            [self payToAddressAction:sender];
            break;
        }
        case DWShortcutActionTypeBuySellDash: {
            [self buySellDashAction];
            break;
        }
        case DWShortcutActionTypeSyncNow: {
            [DWSettingsMenuModel rescanBlockchainActionFromController:self
                                                           sourceView:sender
                                                           sourceRect:sender.bounds
                                                           completion:nil];
            break;
        }
        case DWShortcutActionTypePayWithNFC: {
            [self performNFCReadingAction];
            break;
        }
        case DWShortcutActionTypeLocalCurrency: {
            [self showLocalCurrencyAction];
            break;
        }
        case DWShortcutActionTypeImportPrivateKey: {
            [self showImportPrivateKey];
            break;
        }
        case DWShortcutActionTypeSwitchToTestnet: {
            [DWSettingsMenuModel switchToTestnetWithCompletion:^(BOOL success){
                // NOP
            }];
            break;
        }
        case DWShortcutActionTypeSwitchToMainnet: {
            [DWSettingsMenuModel switchToMainnetWithCompletion:^(BOOL success){
                // NOP
            }];
            break;
        }
        case DWShortcutActionTypeReportAnIssue: {
            break;
        }
        case DWShortcutActionTypeCreateUsername: {
            [self showCreateUsername];
            break;
        }
        case DWShortcutActionTypeReceive: {
            [self.delegate showPaymentsControllerWithActivePage:DWPaymentsViewControllerIndex_Receive];
            break;
        }
        case DWShortcutActionTypeExplore: {
            [self showExploreDash];
            break;
        }
    }
}

#pragma mark - Private

- (void)secureWalletAction {
    [[DSAuthenticationManager sharedInstance]
              authenticateWithPrompt:nil
        usingBiometricAuthentication:NO
                      alertIfLockout:YES
                          completion:^(BOOL authenticated, BOOL usedBiometrics, BOOL cancelled) {
                              if (!authenticated) {
                                  return;
                              }

                              [self secureWalletActionAuthenticated];
                          }];
}

- (void)secureWalletActionAuthenticated {
    DWPreviewSeedPhraseModel *model = [[DWPreviewSeedPhraseModel alloc] init];
    [model getOrCreateNewWallet];

    DWBackupInfoViewController *controller =
        [DWBackupInfoViewController controllerWithModel:model];
    controller.delegate = self;
    [self presentControllerModallyInNavigationController:controller];
}

- (void)buySellDashAction {
    [[DSAuthenticationManager sharedInstance]
              authenticateWithPrompt:nil
        usingBiometricAuthentication:[DWGlobalOptions sharedInstance].biometricAuthEnabled
                      alertIfLockout:YES
                          completion:^(BOOL authenticated, BOOL usedBiometrics, BOOL cancelled) {
                              if (authenticated) {
                                  [self buySellDashActionAuthenticated];
                              }
                          }];
}

- (void)buySellDashActionAuthenticated {
    PortalViewController *controller = [PortalViewController controller];
    controller.showCloseButton = true;

    DWNavigationController *navigationController =
        [[DWNavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)showLocalCurrencyAction {
    DWLocalCurrencyViewController *controller =
        [[DWLocalCurrencyViewController alloc] initWithNavigationAppearance:DWNavigationAppearance_White
                                                               currencyCode:nil];
    controller.delegate = self;
    [self presentControllerModallyInNavigationController:controller];
}

- (void)showImportPrivateKey {
    DWImportWalletInfoViewController *controller = [DWImportWalletInfoViewController controller];
    controller.delegate = self;
    [self presentControllerModallyInNavigationController:controller];
}

- (void)payToAddressAction:(UIView *)sender {
    [self payToAddressAction];
}

- (void)showCreateUsername {
    DWDashPaySetupFlowController *controller = [[DWDashPaySetupFlowController alloc]
        initWithDashPayModel:self.model.dashPayModel];
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)showExploreDash {
    DWExploreTestnetViewController *controller = [[DWExploreTestnetViewController alloc] init];
    controller.delegate = self;
    DWNavigationController *nvc = [[DWNavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:nvc animated:YES completion:nil];
}

- (void)presentControllerModallyInNavigationController:(UIViewController *)controller {
    if (@available(iOS 13.0, *)) {
        [self presentControllerModallyInNavigationController:controller
                                      modalPresentationStyle:UIModalPresentationAutomatic];
    }
    else {
        // TODO: check on the iPad
        [self presentControllerModallyInNavigationController:controller
                                      modalPresentationStyle:UIModalPresentationFullScreen];
    }
}

- (void)presentControllerModallyInNavigationController:(UIViewController *)controller
                                modalPresentationStyle:(UIModalPresentationStyle)modalPresentationStyle {
    UIBarButtonItem *cancelButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(dismissModalControllerBarButtonAction:)];
    controller.navigationItem.leftBarButtonItem = cancelButton;

    DWNavigationController *navigationController =
        [[DWNavigationController alloc] initWithRootViewController:controller];
    navigationController.modalPresentationStyle = modalPresentationStyle;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)dismissModalControllerBarButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - DWLocalCurrencyViewControllerDelegate

- (void)localCurrencyViewController:(DWLocalCurrencyViewController *)controller
                  didSelectCurrency:(nonnull NSString *)currencyCode {
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)localCurrencyViewControllerDidCancel:(DWLocalCurrencyViewController *)controller {
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
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
