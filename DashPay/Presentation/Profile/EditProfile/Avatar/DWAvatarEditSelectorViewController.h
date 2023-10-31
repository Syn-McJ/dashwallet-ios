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

@class DWAvatarEditSelectorViewController;

@protocol DWAvatarEditSelectorViewControllerDelegate <NSObject>

- (void)avatarEditSelectorViewController:(DWAvatarEditSelectorViewController *)controller photoButtonAction:(UIButton *)sender;
- (void)avatarEditSelectorViewController:(DWAvatarEditSelectorViewController *)controller galleryButtonAction:(UIButton *)sender;
- (void)avatarEditSelectorViewController:(DWAvatarEditSelectorViewController *)controller gravatarButtonAction:(UIButton *)sender;
- (void)avatarEditSelectorViewController:(DWAvatarEditSelectorViewController *)controller urlButtonAction:(UIButton *)sender;

@end

@interface DWAvatarEditSelectorViewController : UIViewController

@property (nullable, nonatomic, weak) id<DWAvatarEditSelectorViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
