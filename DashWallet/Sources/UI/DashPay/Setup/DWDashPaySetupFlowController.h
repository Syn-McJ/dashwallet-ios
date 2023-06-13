//
//  Created by Andrew Podkovyrin
//  Copyright © 2020 Dash Core Group. All rights reserved.
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

#import <UIKit/UIKit.h>

#import "DWDashPayProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class DWDashPaySetupFlowController;

@protocol DWDashPaySetupFlowControllerDelegate <NSObject>

- (void)dashPaySetupFlowController:(DWDashPaySetupFlowController *)controller
                didConfirmUsername:(NSString *)username;

@end

@interface DWDashPaySetupFlowController : UIViewController

- (instancetype)initWithDashPayModel:(id<DWDashPayProtocol>)dashPayModel
                          invitation:(nullable NSURL *)invitationURL
                     definedUsername:(nullable NSString *)definedUsername;

- (instancetype)initWithConfirmationDelegate:(id<DWDashPaySetupFlowControllerDelegate>)delegate;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
