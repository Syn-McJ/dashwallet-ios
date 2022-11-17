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

#import "DWBasePayViewController.h"

#import <DashSync/DashSync.h>

#import "DWConfirmSendPaymentViewController.h"
#import "DWHomeViewController.h"
#import "DWPayModelProtocol.h"
#import "DWPaymentInputBuilder.h"
#import "DWPaymentProcessor.h"
#import "DWQRScanModel.h"
#import "DWQRScanViewController.h"
#import "DWSendAmountViewController.h"
#import "DWUIKit.h"
#import "UIView+DWHUD.h"
#import "UIViewController+DWEmbedding.h"
#import "dashwallet-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWBasePayViewController () <DWPaymentProcessorDelegate,
                                       DWSendAmountViewControllerDelegate,
                                       DWQRScanModelDelegate,
                                       DWConfirmPaymentViewControllerDelegate,
                                       SuccessTxDetailViewControllerDelegate>

@property (nullable, nonatomic, weak) DWSendAmountViewController *amountViewController;
@property (nullable, nonatomic, weak) DWConfirmSendPaymentViewController *confirmViewController;

@end

@implementation DWBasePayViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(self.payModel);
}

- (DWPaymentProcessor *)paymentProcessor {
    if (_paymentProcessor == nil) {
        _paymentProcessor = [[DWPaymentProcessor alloc] initWithDelegate:self];
    }

    return _paymentProcessor;
}

- (void)performScanQRCodeAction {
    if ([self.presentedViewController isKindOfClass:DWQRScanViewController.class]) {
        return;
    }

    NSAssert(self.presentedViewController == nil, @"Attempt to present on VC which is already presenting %@",
             self.presentedViewController);

    DWQRScanViewController *controller = [[DWQRScanViewController alloc] init];
    controller.model.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)payToAddressAction {
    id<DWPayModelProtocol> payModel = self.payModel;
    __weak typeof(self) weakSelf = self;
    [payModel payToAddressFromPasteboardAvailable:^(BOOL success) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        if (success) {
            [strongSelf performPayToPasteboardAction];
        }
        else {
            NSString *message = NSLocalizedString(@"Clipboard doesn't contain a valid Dash address", nil);
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
            [alert addAction:okAction];

            [strongSelf presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)performPayToPasteboardAction {
    DWPaymentInput *paymentInput = self.payModel.pasteboardPaymentInput;
    NSParameterAssert(paymentInput);
    if (!paymentInput) {
        return;
    }

    self.paymentProcessor = nil;
    [self.paymentProcessor processPaymentInput:paymentInput];
}

- (void)performNFCReadingAction {
    __weak typeof(self) weakSelf = self;
    [self.payModel performNFCReadingWithCompletion:^(DWPaymentInput *_Nonnull paymentInput) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        strongSelf.paymentProcessor = nil;
        [strongSelf.paymentProcessor processPaymentInput:paymentInput];
    }];
}

- (void)performPayToURL:(NSURL *)url {
    DWPaymentInput *paymentInput = [self.payModel paymentInputWithURL:url];

    self.paymentProcessor = nil;
    [self.paymentProcessor processPaymentInput:paymentInput];
}

- (void)performPayToUser:(id<DWDPBasicUserItem>)userItem {
    DWPaymentInput *paymentInput = [self.payModel paymentInputWithUser:userItem];

    self.paymentProcessor = nil;
    [self.paymentProcessor processPaymentInput:paymentInput];
}

- (void)handleFile:(NSData *)file {
    self.paymentProcessor = nil;
    [self.paymentProcessor processFile:file];
}

- (void)payViewControllerDidHidePaymentResultToContact:(nullable id<DWDPBasicUserItem>)contact {
    // to be overriden
}

- (id<DWDPBasicUserItem>)contactItem {
    return nil; // to be overriden
}

#pragma mark - DWPaymentProcessorDelegate

// User Actions

- (void)paymentProcessor:(DWPaymentProcessor *)processor
    requestAmountWithDestination:(NSString *)sendingDestination
                         details:(nullable DSPaymentProtocolDetails *)details
                     contactItem:(id<DWDPBasicUserItem>)contactItem {
    DWSendAmountViewController *controller =
        [[DWSendAmountViewController alloc] initWithDestination:sendingDestination
                                                 paymentDetails:nil
                                                    contactItem:contactItem ?: [self contactItem]];
    controller.delegate = self;
    controller.demoMode = self.demoMode;
    [self.navigationController pushViewController:controller animated:YES];
    self.amountViewController = controller;
}

- (void)paymentProcessor:(DWPaymentProcessor *)processor
    requestUserActionTitle:(nullable NSString *)title
                   message:(nullable NSString *)message
               actionTitle:(NSString *)actionTitle
               cancelBlock:(nullable void (^)(void))cancelBlock
               actionBlock:(nullable void (^)(void))actionBlock {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title
                         message:message
                  preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction
        actionWithTitle:NSLocalizedString(@"Cancel", nil)
                  style:UIAlertActionStyleCancel
                handler:^(UIAlertAction *action) {
                    NSParameterAssert(cancelBlock);
                    if (cancelBlock) {
                        cancelBlock();
                    }

                    NSAssert(!self.confirmViewController || self.confirmViewController.sendingEnabled,
                             @"paymentProcessorDidCancelTransactionSigning: should be called");
                }];
    [alert addAction:cancelAction];

    UIAlertAction *actionAction = [UIAlertAction
        actionWithTitle:actionTitle
                  style:UIAlertActionStyleDefault
                handler:^(UIAlertAction *action) {
                    NSParameterAssert(actionBlock);
                    if (actionBlock) {
                        actionBlock();
                    }

                    self.confirmViewController.sendingEnabled = YES;
                }];
    [alert addAction:actionAction];

    [self showModalController:alert];
}

// Confirmation

- (void)paymentProcessor:(DWPaymentProcessor *)processor
    confirmPaymentOutput:(DWPaymentOutput *)paymentOutput {
    if (self.confirmViewController) {
        self.confirmViewController.paymentOutput = paymentOutput;
    }
    else {
        DWConfirmSendPaymentViewController *controller = [[DWConfirmSendPaymentViewController alloc] init];
        controller.paymentOutput = paymentOutput;
        controller.delegate = self;

        if (self.demoMode) {
            controller.transitioningDelegate = nil;
            controller.modalPresentationStyle = UIModalPresentationPageSheet;

            [self.demoDelegate presentModalController:controller sender:self];
        }
        else {
            [self presentViewController:controller animated:YES completion:nil];
        }

        self.confirmViewController = controller;
    }
}

- (void)paymentProcessorDidCancelTransactionSigning:(DWPaymentProcessor *)processor {
    self.confirmViewController.sendingEnabled = YES;
}

// Result

- (void)paymentProcessor:(DWPaymentProcessor *)processor
        didFailWithError:(nullable NSError *)error
                   title:(nullable NSString *)title
                 message:(nullable NSString *)message {
    if ([error.domain isEqual:DSErrorDomain] &&
        (error.code == DSErrorInsufficientFunds || error.code == DSErrorInsufficientFundsForNetworkFee)) {
        [self.amountViewController insufficientFundsErrorWasShown];
    }

    [self.navigationController.view dw_hideProgressHUD];
    [self showAlertWithTitle:title message:message];
    if (self.confirmViewController) {
        self.confirmViewController.sendingEnabled = YES;
    }
}

- (void)paymentProcessor:(DWPaymentProcessor *)processor
          didSendRequest:(DSPaymentProtocolRequest *)protocolRequest
             transaction:(DSTransaction *)transaction
             contactItem:(nullable id<DWDPBasicUserItem>)contactItem {
    [self.navigationController.view dw_hideProgressHUD];

    if (self.confirmViewController) {
        [self dismissViewControllerAnimated:YES
                                 completion:^{
                                     if ([self.navigationController.topViewController isKindOfClass:DWSendAmountViewController.class]) {
                                         [self.navigationController popViewControllerAnimated:YES];
                                     }
                                 }];
    }
    else {
        if ([self.navigationController.topViewController isKindOfClass:DWSendAmountViewController.class]) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }

    SuccessTxDetailViewController *controller = [SuccessTxDetailViewController controller];
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    controller.model = [[TxDetailModel alloc] initWithTransaction:transaction dataProvider:self.dataProvider];
    controller.contactItem = contactItem;
    controller.delegate = self;
    [self presentViewController:controller
                       animated:YES
                     completion:nil];
}

- (void)paymentProcessor:(nonnull DWPaymentProcessor *)processor
         didSweepRequest:(nonnull DSPaymentRequest *)protocolRequest
             transaction:(nonnull DSTransaction *)transaction {
    [self.navigationController.view dw_showInfoHUDWithText:NSLocalizedString(@"Swept!", nil)];

    if ([self.navigationController.topViewController isKindOfClass:DWSendAmountViewController.class]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

// Handle File

- (void)paymentProcessor:(DWPaymentProcessor *)processor displayFileProcessResult:(NSString *)result {
    [self showAlertWithTitle:result message:nil];
}

- (void)paymentProcessorDidFinishProcessingFile:(DWPaymentProcessor *)processor {
    // NOP
}

// Progress HUD

- (void)paymentProcessor:(DWPaymentProcessor *)processor
    showProgressHUDWithMessage:(nullable NSString *)message {
    NSAssert(self.confirmViewController == nil, @"Consider showing HUD on confirmViewController?");
    [self.navigationController.view dw_showProgressHUDWithMessage:message];
}

- (void)paymentInputProcessorHideProgressHUD:(DWPaymentProcessor *)processor {
    NSAssert(self.confirmViewController == nil, @"Consider hiding HUD from confirmViewController?");
    [self.navigationController.view dw_hideProgressHUD];
}

#pragma mark - DWSendAmountViewControllerDelegate

- (void)sendAmountViewController:(DWSendAmountViewController *)controller
                  didInputAmount:(uint64_t)amount {
    NSParameterAssert(self.paymentProcessor);
    [self.paymentProcessor provideAmount:amount];
}

#pragma mark - DWConfirmPaymentViewControllerDelegate

- (void)confirmPaymentViewControllerDidConfirm:(DWConfirmSendPaymentViewController *)controller {
    [self.paymentProcessor confirmPaymentOutput:controller.paymentOutput];
}

#pragma mark - DWTxDetailFullscreenViewControllerDelegate

- (void)txDetailViewControllerDidFinishWithController:(SuccessTxDetailViewController *)controller {
    id<DWDPBasicUserItem> contact = [self contactItem] == nil ? controller.contactItem : nil;
    [self payViewControllerDidHidePaymentResultToContact:contact];
}

#pragma mark -  DWQRScanModelDelegate

- (void)qrScanModel:(DWQRScanModel *)viewModel didScanPaymentInput:(DWPaymentInput *)paymentInput {
    self.view.userInteractionEnabled = NO;
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 self.paymentProcessor = nil;
                                 [self.paymentProcessor processPaymentInput:paymentInput];

                                 self.view.userInteractionEnabled = YES;
                             }];
}

- (void)qrScanModelDidCancel:(DWQRScanModel *)viewModel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void)showAlertWithTitle:(NSString *_Nullable)title message:(NSString *_Nullable)message {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title
                         message:message
                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction
        actionWithTitle:NSLocalizedString(@"OK", nil)
                  style:UIAlertActionStyleCancel
                handler:nil];
    [alert addAction:okAction];
    [self showModalController:alert];
}

- (void)showModalController:(UIViewController *)controller {
    UIViewController *presentingViewController = self.confirmViewController ?: self.navigationController;
    [presentingViewController presentViewController:controller animated:YES completion:nil];
}

@end

NS_ASSUME_NONNULL_END
