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

#import "DWMainMenuItem.h"

#if DASHPAY
#import "DWCurrentUserProfileModel.h"
#import "DWDashPayReadyProtocol.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class DWMainMenuModel;
@class DWMainMenuContentView;

@protocol DWMainMenuContentViewDelegate <NSObject>

- (void)mainMenuContentView:(DWMainMenuContentView *)view didSelectMenuItem:(id<DWMainMenuItem>)item;

#if DASHPAY
- (void)mainMenuContentView:(DWMainMenuContentView *)view joinDashPayAction:(UIButton *)sender;
- (void)mainMenuContentView:(DWMainMenuContentView *)view showQRAction:(UIButton *)sender;
- (void)mainMenuContentView:(DWMainMenuContentView *)view editProfileAction:(UIButton *)sender;
#endif

@end

@interface DWMainMenuContentView : UIView

@property (nonatomic, strong) DWMainMenuModel *model;
@property (nullable, nonatomic, weak) id<DWMainMenuContentViewDelegate> delegate;

- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

#if DASHPAY
@property (nonatomic, strong) DWCurrentUserProfileModel *userModel;
@property (nonatomic, strong) id<DWDashPayReadyProtocol> dashPayReady;
- (void)updateUserHeader;
#endif

@end

NS_ASSUME_NONNULL_END
