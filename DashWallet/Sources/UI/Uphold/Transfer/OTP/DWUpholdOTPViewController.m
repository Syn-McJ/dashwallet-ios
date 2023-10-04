//
//  Created by Andrew Podkovyrin
//  Copyright © 2018 Dash Core Group. All rights reserved.
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

#import "DWUpholdOTPViewController.h"

#import "DWUIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWUpholdOTPViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UITextField *textField;

@property (assign, nonatomic) NSInteger pasteboardChangeCount;

@property (nullable, copy, nonatomic) void (^completionBlock)(DWUpholdOTPViewController *controller, NSString *_Nullable otpToken);

@end

@implementation DWUpholdOTPViewController

@synthesize providedActions = _providedActions;

+ (instancetype)controllerWithCompletion:(void (^)(DWUpholdOTPViewController *controller, NSString *_Nullable otpToken))completion {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UpholdOTPStoryboard" bundle:nil];
    DWUpholdOTPViewController *controller = [storyboard instantiateInitialViewController];
    controller.completionBlock = completion;

    return controller;
}

- (NSArray<DWAlertAction *> *)providedActions {
    if (!_providedActions) {
        __weak typeof(self) weakSelf = self;
        DWAlertAction *cancelAction = [DWAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                               style:DWAlertActionStyleCancel
                                                             handler:^(DWAlertAction *_Nonnull action) {
                                                                 __strong typeof(weakSelf) strongSelf = weakSelf;
                                                                 if (!strongSelf) {
                                                                     return;
                                                                 }

                                                                 [strongSelf cancelButtonAction];
                                                             }];
        DWAlertAction *okAction = [DWAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                           style:DWAlertActionStyleDefault
                                                         handler:^(DWAlertAction *_Nonnull action) {
                                                             __strong typeof(weakSelf) strongSelf = weakSelf;
                                                             if (!strongSelf) {
                                                                 return;
                                                             }

                                                             [strongSelf okButtonAction];
                                                         }];
        _providedActions = @[ cancelAction, okAction ];
    }
    return _providedActions;
}

- (DWAlertAction *)preferredAction {
    return self.providedActions.lastObject;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.titleLabel.text = NSLocalizedString(@"Enter your 2FA code below", nil);
    self.titleLabel.font = [UIFont dw_fontForTextStyle:UIFontTextStyleTitle3];
    self.titleLabel.textColor = [UIColor dw_darkTitleColor];


    self.textField.textColor = [UIColor dw_darkTitleColor];
    self.textField.delegate = self;

    self.pasteboardChangeCount = [UIPasteboard generalPasteboard].changeCount;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActiveNotification:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(pasteboardChangedNotification:)
                               name:UIPasteboardChangedNotification
                             object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.textField becomeFirstResponder];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    self.textField.textColor = [UIColor dw_darkTitleColor];
}

#pragma mark - Actions

- (void)okButtonAction {
    [self confirmOTPToken:self.textField.text];
}

- (void)cancelButtonAction {
    if (self.completionBlock) {
        self.completionBlock(self, nil);
        self.completionBlock = nil;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (string.length == 0) {
        return YES;
    }
    
    NSString *resultText = [textField.text stringByAppendingString:string];
        
    if ([self isLooksLikeOTPToken:resultText]) {
        if (resultText.length == 6) {
            [self confirmOTPToken:resultText];
        }
        
        return YES;
    }
    
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self confirmOTPToken:self.textField.text];

    return YES;
}

#pragma mark - Notifications

- (void)applicationDidBecomeActiveNotification:(NSNotification *)sender {
    if (self.pasteboardChangeCount != [UIPasteboard generalPasteboard].changeCount) {
        [self pasteboardChangedNotification:sender];
    }
}

- (void)pasteboardChangedNotification:(NSNotification *)sender {
    self.pasteboardChangeCount = [UIPasteboard generalPasteboard].changeCount;
    [self displayTextFieldMenuIfNeeded];
}

#pragma mark - Private

- (void)confirmOTPToken:(NSString *)code {
    if (code.length < 1) {
        [self.textField dw_shakeView];

        return;
    }

    [self.textField resignFirstResponder];

    if (self.completionBlock) {
        self.completionBlock(self, code);
        self.completionBlock = nil;
    }
}

- (BOOL)isLooksLikeOTPToken:(NSString *)inputString {
    if (inputString.length == 0) {
        return NO;
    }
    NSCharacterSet *decimalNumbersSet = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *inputStringSet = [NSCharacterSet characterSetWithCharactersInString:inputString];
    BOOL stringIsValid = [decimalNumbersSet isSupersetOfSet:inputStringSet];

    return stringIsValid;
}

- (void)displayTextFieldMenuIfNeeded {
    if (![UIPasteboard generalPasteboard].hasStrings) {
        return;
    }

    NSString *string = [UIPasteboard generalPasteboard].string;
    if (![self isLooksLikeOTPToken:string]) {
        return;
    }

    [self.textField becomeFirstResponder];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIMenuController *menu = [UIMenuController sharedMenuController];
        [menu showMenuFromView:self.textField rect:self.textField.bounds];
    });
}

@end

NS_ASSUME_NONNULL_END
