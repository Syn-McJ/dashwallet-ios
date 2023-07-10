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

#import "BaseCollectionReusableView.h"

NS_ASSUME_NONNULL_BEGIN

@class DWTitleActionHeaderView;

@protocol DWTitleActionHeaderViewDelegate <NSObject>

- (void)titleActionHeaderView:(DWTitleActionHeaderView *)view buttonAction:(UIView *)sender;

@end

@interface DWTitleActionHeaderView : BaseCollectionReusableView

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIButton *actionButton;

@property (nullable, nonatomic, weak) id<DWTitleActionHeaderViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
