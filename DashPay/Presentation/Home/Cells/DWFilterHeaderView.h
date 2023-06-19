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
#import "BaseCollectionReusableView.h"

NS_ASSUME_NONNULL_BEGIN

@class DWFilterHeaderView;

@protocol DWFilterHeaderViewDelegate <NSObject>

- (void)filterHeaderView:(DWFilterHeaderView *)view filterButtonAction:(UIView *)sender;
- (void)filterHeaderView:(DWFilterHeaderView *)view infoButtonAction:(UIView *)sender;

@end

@interface DWFilterHeaderView : BaseCollectionReusableView

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIButton *filterButton;

@property (assign, nonatomic) CGFloat padding;

@property (nullable, nonatomic, weak) id<DWFilterHeaderViewDelegate> delegate;

@property (strong, nonatomic) IBOutlet UIButton *infoButton;

@end

NS_ASSUME_NONNULL_END
