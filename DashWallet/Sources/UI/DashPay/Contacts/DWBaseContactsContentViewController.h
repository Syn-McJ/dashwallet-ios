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

#import "DWContactsDataSource.h"
#import "DWDPBasicUserItem.h"
#import "DWDPNewIncomingRequestItem.h"
#import "DWPayModelProtocol.h"
#import "DWTransactionListDataProviderProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class DWBaseContactsContentViewController;

@protocol DWBaseContactsContentViewControllerDelegate <NSObject>

- (void)baseContactsContentViewController:(DWBaseContactsContentViewController *)controller
                                didSelect:(id<DWDPBasicUserItem>)item
                                indexPath:(NSIndexPath *)indexPath;

@end

@interface DWBaseContactsContentViewController : UIViewController

@property (readonly, null_resettable, nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, assign, getter=isContactsScreen) BOOL contactsScreen;
@property (readonly, nonatomic, assign) NSUInteger maxVisibleContactRequestsCount;

@property (nullable, nonatomic, weak) id<DWBaseContactsContentViewControllerDelegate> delegate;
@property (nullable, nonatomic, weak) id<DWDPNewIncomingRequestItemDelegate> itemsDelegate;
@property (nonatomic, strong) id<DWContactsDataSource> dataSource;

@property (nullable, nonatomic, copy) NSArray<id<DWDPBasicUserItem>> *matchedItems;
@property (nonatomic, assign) BOOL matchFailed;

- (instancetype)initWithPayModel:(id<DWPayModelProtocol>)payModel
                    dataProvider:(id<DWTransactionListDataProviderProtocol>)dataProvider NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
