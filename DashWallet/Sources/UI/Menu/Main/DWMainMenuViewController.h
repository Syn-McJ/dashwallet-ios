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

#import <UIKit/UIKit.h>

#import "DWWipeDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class DWMainMenuViewController;
@protocol DWMainMenuViewControllerDelegate;
@protocol DWReceiveModelProtocol;
@class DWCurrentUserProfileModel;
@protocol DWDashPayReadyProtocol;
@protocol DWDashPayProtocol;

@interface DWMainMenuViewController : UIViewController

@property (nullable, nonatomic, weak) id<DWWipeDelegate, DWMainMenuViewControllerDelegate> delegate;

#if DASHPAY
- (instancetype)initWithDashPayModel:(id<DWDashPayProtocol>)dashPayModel
                        receiveModel:(id<DWReceiveModelProtocol>)receiveModel
                        dashPayReady:(id<DWDashPayReadyProtocol>)dashPayReady
                    userProfileModel:(DWCurrentUserProfileModel *)userProfileModel;
#endif

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
