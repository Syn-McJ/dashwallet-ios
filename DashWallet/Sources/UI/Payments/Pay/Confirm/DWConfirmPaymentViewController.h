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

#import "DWBaseModalViewController.h"

#import "DWConfirmPaymentViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class DWConfirmPaymentViewController;

@protocol DWConfirmPaymentViewControllerDelegate <NSObject>

- (void)confirmPaymentViewControllerDidConfirm:(DWConfirmPaymentViewController *)controller;
- (void)confirmPaymentViewControllerDidCancel:(DWConfirmPaymentViewController *)controller;

@end

@interface DWConfirmPaymentViewController : DWBaseModalViewController

@property (nullable, nonatomic, weak) id<DWConfirmPaymentViewControllerDelegate> delegate;
@property (nullable, nonatomic, strong) id<DWConfirmPaymentViewProtocol> model;
@property (nonatomic, assign) BOOL sendingEnabled;

@end

NS_ASSUME_NONNULL_END
