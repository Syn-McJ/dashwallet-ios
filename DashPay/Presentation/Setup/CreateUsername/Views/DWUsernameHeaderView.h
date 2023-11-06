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

NS_ASSUME_NONNULL_BEGIN

typedef NSAttributedString *_Nonnull (^DWTitleStringBuilder)(void);

@interface DWUsernameHeaderView : UIView

@property (readonly, nonatomic, strong) UIButton *cancelButton;
@property (nullable, nonatomic, copy) DWTitleStringBuilder titleBuilder;
@property (nonatomic, assign) BOOL landscapeMode;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)configurePlanetsViewWithUsername:(NSString *)username;

- (void)showInitialAnimation;

@end

NS_ASSUME_NONNULL_END
