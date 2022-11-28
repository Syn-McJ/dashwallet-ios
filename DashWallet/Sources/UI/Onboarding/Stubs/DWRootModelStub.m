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

#import "DWRootModelStub.h"

#import "DWHomeModelStub.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWRootModelStub ()

@property (nonatomic, strong) id<DWHomeProtocol> homeModel;

@end

@implementation DWRootModelStub

@synthesize currentNetworkDidChangeBlock;

- (instancetype)init {
    self = [super init];
    if (self) {
        _homeModel = [[DWHomeModelStub alloc] init];
    }
    return self;
}

- (BOOL)hasAWallet {
    return YES;
}

- (BOOL)walletOperationAllowed {
    return YES;
}

- (void)applicationDidEnterBackground {
}

- (void)applicationWillResignActiveNotification {
}

- (BOOL)shouldShowLockScreen {
    return NO;
}

- (void)setupDidFinish {
}

- (void)wipeWallet {
}

@end

NS_ASSUME_NONNULL_END
