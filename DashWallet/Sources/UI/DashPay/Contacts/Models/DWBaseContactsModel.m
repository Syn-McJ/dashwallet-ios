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

#import "DWBaseContactsModel+DWProtected.h"

#import "DWBaseContactsDataSourceObject.h"
#import "DWDashPayContactsActions.h"
#import "DWDashPayContactsUpdater.h"
#import "DWEnvironment.h"

@implementation DWBaseContactsModel

@synthesize sortMode;

- (BOOL)isEmpty {
    return self.aggregateDataSource.isEmpty;
}

- (BOOL)isSearching {
    return self.aggregateDataSource.isSearching;
}

- (id<DWContactsDataSource>)dataSource {
    return self.aggregateDataSource;
}

- (BOOL)hasBlockchainIdentity {
    DSWallet *wallet = [DWEnvironment sharedInstance].currentWallet;
    DSBlockchainIdentity *myBlockchainIdentity = wallet.defaultBlockchainIdentity;
    return myBlockchainIdentity != nil;
}

- (void)rebuildDataSources {
}

- (void)start {
    [[DWDashPayContactsUpdater sharedInstance] fetch];

    [self activateFRCs];
}

- (void)stop {
    [self resetFRCs];
}

- (void)acceptContactRequest:(id<DWDPBasicItem>)item {
    [DWDashPayContactsActions acceptContactRequest:item completion:nil];
}

- (void)declineContactRequest:(id<DWDPBasicItem>)item {
    [DWDashPayContactsActions declineContactRequest:item completion:nil];
}

- (void)searchWithQuery:(NSString *)searchQuery {
    [self.dataSource searchWithQuery:searchQuery];

    [self.delegate contactsModelDidUpdate:self];
}

#pragma mark - DWFetchedResultsDataSourceDelegate

- (void)fetchedResultsDataSourceDidUpdate:(DWFetchedResultsDataSource *)fetchedResultsDataSource {
    NSAssert([NSThread isMainThread], @"Main thread is assumed here");

    if (fetchedResultsDataSource == self.firstSectionDataSource) {
        [self.aggregateDataSource reloadFirstFRC:fetchedResultsDataSource.fetchedResultsController];
    }
    else {
        [self.aggregateDataSource reloadSecondFRC:fetchedResultsDataSource.fetchedResultsController];
    }

    [self.delegate contactsModelDidUpdate:self];
}

#pragma mark - Private

- (void)activateFRCs {
    if (!self.firstSectionDataSource) {
        [self rebuildDataSources];
    }

    [self.firstSectionDataSource start];
    [self.secondSectionDataSource start];

    [self.aggregateDataSource beginReloading];
    [self.aggregateDataSource reloadFirstFRC:self.firstSectionDataSource.fetchedResultsController];
    [self.aggregateDataSource reloadSecondFRC:self.secondSectionDataSource.fetchedResultsController];
    [self.aggregateDataSource endReloading];

    [self.delegate contactsModelDidUpdate:self];
}

- (void)resetFRCs {
    [self.firstSectionDataSource stop];
    [self.secondSectionDataSource stop];
}

@end
