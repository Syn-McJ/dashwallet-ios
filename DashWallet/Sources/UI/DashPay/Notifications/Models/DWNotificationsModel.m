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

#import "DWNotificationsModel.h"

#import "DWDashPayContactsActions.h"
#import "DWEnvironment.h"
#import "DWGlobalOptions.h"
#import "DWNotificationsProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWNotificationsModel ()

@property (nullable, nonatomic, copy) DWNotificationsData *data;
@property (nullable, nonatomic, strong) NSDate *mostRecentViewedNotificationDate;

@end

NS_ASSUME_NONNULL_END

@implementation DWNotificationsModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _data = [[DWNotificationsData alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(notificationsDidUpdate)
                                                     name:DWNotificationsProviderDidUpdateNotification
                                                   object:nil];
        [self notificationsDidUpdate]; // initial update (when notification was missed)
    }
    return self;
}

- (void)dealloc {
    [[DWNotificationsProvider sharedInstance] forceUpdate];
}

- (void)acceptContactRequest:(id<DWDPBasicUserItem>)item {
    [DWDashPayContactsActions acceptContactRequest:item context:self.context completion:nil];
}

- (void)declineContactRequest:(id<DWDPBasicUserItem>)item {
    [DWDashPayContactsActions declineContactRequest:item context:self.context completion:nil];
}

- (void)markNotificationAsRead:(id<DWDPNotificationItem>)item {
    if (self.mostRecentViewedNotificationDate == nil ||
        [item.date compare:self.mostRecentViewedNotificationDate] == NSOrderedDescending) {
        self.mostRecentViewedNotificationDate = item.date;
    }
}

- (void)saveMostRecentViewedNotificationDate {
    if (self.mostRecentViewedNotificationDate == nil) {
        return;
    }

    DWGlobalOptions *options = [DWGlobalOptions sharedInstance];
    if (options.mostRecentViewedNotificationDate == nil ||
        [self.mostRecentViewedNotificationDate compare:options.mostRecentViewedNotificationDate] == NSOrderedDescending) {
        options.mostRecentViewedNotificationDate = self.mostRecentViewedNotificationDate;
    }
}

#pragma mark - Private

- (void)notificationsDidUpdate {
    DWNotificationsProvider *provider = [DWNotificationsProvider sharedInstance];
    self.data = provider.data;

    [self.delegate notificationsModelDidUpdate:self];
}

@end
