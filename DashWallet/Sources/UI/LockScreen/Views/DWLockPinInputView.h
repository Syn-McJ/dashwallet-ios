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

NS_ASSUME_NONNULL_BEGIN

@class DWLockPinInputView;
@class NumberKeyboard;

@protocol DWLockPinInputViewDelegate <NSObject>

- (void)lockPinInputView:(DWLockPinInputView *)view didFinishInputWithText:(NSString *)text;

@end

@interface DWLockPinInputView : UIView

@property (nullable, nonatomic, weak) id<DWLockPinInputViewDelegate> delegate;

- (void)configureWithKeyboard:(NumberKeyboard *)keyboard;
- (void)activatePinField;
- (void)clearAndShakePinField;
- (void)setTitleText:(nullable NSString *)title;
- (void)setAttemptsText:(nullable NSString *)attemptsText errorText:(nullable NSString *)errorText;

@end

NS_ASSUME_NONNULL_END
