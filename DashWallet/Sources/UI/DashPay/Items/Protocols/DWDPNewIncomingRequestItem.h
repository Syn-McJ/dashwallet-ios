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

#import "DWDPIncomingRequestItem.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DWDPNewIncomingRequestItemDelegate <DWDPItemCellDelegate>

- (void)acceptIncomingRequest:(id<DWDPBasicUserItem>)item;
- (void)declineIncomingRequest:(id<DWDPBasicUserItem>)item;

@end

typedef NS_ENUM(NSUInteger, DWDPNewIncomingRequestItemState) {
    DWDPNewIncomingRequestItemState_Ready,
    DWDPNewIncomingRequestItemState_Processing,
    DWDPNewIncomingRequestItemState_Accepted, // succeeded
    DWDPNewIncomingRequestItemState_Declined, // succeeded
    DWDPNewIncomingRequestItemState_Failed,
};

@protocol DWDPNewIncomingRequestItem <DWDPIncomingRequestItem>

@property (nonatomic, assign) DWDPNewIncomingRequestItemState requestState;

@end

NS_ASSUME_NONNULL_END
