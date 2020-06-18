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

#import "DWBaseContactsDataSourceObject.h"

#import "DWContactsSearchDataSource.h"
#import "DWDPBasicCell.h"
#import "DWDPContactsItemsFactory.h"
#import "DWUIKit.h"
#import "UITableView+DWDPItemDequeue.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWBaseContactsDataSourceObject () <NSFetchedResultsControllerDelegate>

@property (nullable, nonatomic, weak) UITableView *tableView;
@property (nullable, nonatomic, weak) id<DWDPNewIncomingRequestItemDelegate> itemsDelegate;

@property (nonatomic, assign) BOOL batchReloading;
@property (readonly, nonatomic, strong) DWDPContactsItemsFactory *itemsFactory;
@property (nullable, nonatomic, strong) NSFetchedResultsController *firstFRC;
@property (nullable, nonatomic, strong) NSFetchedResultsController *secondFRC;

@property (nullable, nonatomic, copy) NSString *trimmedQuery;
@property (null_resettable, nonatomic, strong) DWContactsSearchDataSource *searchDataSource;

@end

NS_ASSUME_NONNULL_END

@implementation DWBaseContactsDataSourceObject

- (instancetype)init {
    self = [super init];
    if (self) {
        _itemsFactory = [[DWDPContactsItemsFactory alloc] init];
    }
    return self;
}

- (void)beginReloading {
    self.batchReloading = YES;
}

- (void)endReloading {
    self.batchReloading = NO;
    [self.tableView reloadData];
    [self updateSearchIfNeeded];
}

- (void)reloadFirstFRC:(NSFetchedResultsController *)frc {
    self.firstFRC = frc;
    self.firstFRC.delegate = self;

    if (!self.batchReloading) {
        [self.tableView reloadData];
        [self updateSearchIfNeeded];
    }
}

- (void)reloadSecondFRC:(NSFetchedResultsController *)frc {
    self.secondFRC = frc;
    self.secondFRC.delegate = self;

    if (!self.batchReloading) {
        [self.tableView reloadData];
        [self updateSearchIfNeeded];
    }
}

#pragma mark - DWContactsDataSource

- (NSUInteger)maxVisibleContactRequestsCount {
    return NSUIntegerMax;
}

- (NSUInteger)contactRequestsCount {
    return self.firstFRC.sections.firstObject.numberOfObjects;
}

- (void)setupWithTableView:(UITableView *)tableView itemsDelegate:(id<DWDPNewIncomingRequestItemDelegate>)itemsDelegate {
    self.tableView = tableView;
    self.itemsDelegate = itemsDelegate;
}

- (BOOL)isEmpty {
    if (self.firstFRC == nil && self.secondFRC == nil) {
        return YES;
    }

    if (self.searching) {
        const NSUInteger count = self.searchDataSource.filteredFirstSection.count +
                                 self.searchDataSource.filteredSecondSection.count;
        return count == 0;
    }
    else {
        const NSInteger count = self.firstFRC.sections.firstObject.numberOfObjects +
                                self.secondFRC.sections.firstObject.numberOfObjects;
        return count == 0;
    }
}

- (BOOL)isSearching {
    return self.trimmedQuery.length > 0;
}

- (id<DWDPBasicItem>)itemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (self.searching) {
            return self.searchDataSource.filteredFirstSection[indexPath.row];
        }
        else {
            NSManagedObject *entity = [self.firstFRC objectAtIndexPath:indexPath];
            id<DWDPBasicItem> item = [self.itemsFactory itemForEntity:entity];
            return item;
        }
    }
    else {
        if (self.searching) {
            return self.searchDataSource.filteredSecondSection[indexPath.row];
        }
        else {
            NSIndexPath *transformedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
            NSManagedObject *entity = [self.secondFRC objectAtIndexPath:transformedIndexPath];
            id<DWDPBasicItem> item = [self.itemsFactory itemForEntity:entity];
            return item;
        }
    }
}

- (void)searchWithQuery:(NSString *)searchQuery {
    NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
    NSString *trimmedQuery = [searchQuery stringByTrimmingCharactersInSet:whitespaces] ?: @"";
    if ([self.trimmedQuery isEqualToString:trimmedQuery]) {
        return;
    }

    self.trimmedQuery = trimmedQuery;

    if (self.searching) {
        [self.searchDataSource filterWithTrimmedQuery:trimmedQuery];
    }

    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.secondFRC ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (self.searching) {
            return self.searchDataSource.filteredFirstSection.count;
        }
        else {
            return MIN(self.firstFRC.sections.firstObject.numberOfObjects,
                       self.maxVisibleContactRequestsCount);
        }
    }
    else {
        if (self.searching) {
            return self.searchDataSource.filteredSecondSection.count;
        }
        else {
            return self.secondFRC.sections.firstObject.numberOfObjects;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<DWDPBasicItem> item = [self itemAtIndexPath:indexPath];
    DWDPBasicCell *cell = [tableView dw_dequeueReusableCellForItem:item atIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath withItem:item];
    return cell;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    NSAssert([NSThread isMainThread], @"Main thread is assumed here");

    if (self.isSearching) {
        return;
    }

    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
    didChangeObject:(id)anObject
        atIndexPath:(nullable NSIndexPath *)indexPath
      forChangeType:(NSFetchedResultsChangeType)type
       newIndexPath:(nullable NSIndexPath *)newIndexPath {
    NSAssert([NSThread isMainThread], @"Main thread is assumed here");

    if (self.isSearching) {
        return;
    }

    UITableView *tableView = self.tableView;

    switch (type) {
        case NSFetchedResultsChangeInsert: {
            NSIndexPath *transformedNewIndexPath = [self transformIndexPath:newIndexPath controller:controller];
            [tableView insertRowsAtIndexPaths:@[ transformedNewIndexPath ]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            NSIndexPath *transformedIndexPath = [self transformIndexPath:indexPath controller:controller];
            [tableView deleteRowsAtIndexPaths:@[ transformedIndexPath ]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeMove: {
            NSIndexPath *transformedIndexPath = [self transformIndexPath:indexPath controller:controller];
            NSIndexPath *transformedNewIndexPath = [self transformIndexPath:newIndexPath controller:controller];
            [tableView moveRowAtIndexPath:transformedIndexPath
                              toIndexPath:transformedNewIndexPath];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            NSIndexPath *transformedIndexPath = [self transformIndexPath:indexPath controller:controller];
            id<DWDPBasicItem> item = [self itemAtIndexPath:transformedIndexPath];
            [self configureCell:[tableView cellForRowAtIndexPath:transformedIndexPath]
                    atIndexPath:indexPath
                       withItem:item];
            break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    NSAssert([NSThread isMainThread], @"Main thread is assumed here");

    if (self.isSearching) {
        [self updateSearchIfNeeded];
    }
    else {
        [self.tableView endUpdates];
    }
}

#pragma mark - Private

- (void)updateSearchIfNeeded {
    self.searchDataSource = nil;

    if (self.searching) {
        [self.searchDataSource filterWithTrimmedQuery:self.trimmedQuery];
        [self.tableView reloadData];
    }
}

- (NSIndexPath *)transformIndexPath:(NSIndexPath *)indexPath controller:(NSFetchedResultsController *)controller {
    if (controller == self.firstFRC) {
        return indexPath;
    }
    else {
        return [NSIndexPath indexPathForRow:indexPath.row inSection:1];
    }
}

- (void)configureCell:(DWDPBasicCell *)cell atIndexPath:(NSIndexPath *)indexPath withItem:(id<DWDPBasicItem>)item {
    cell.displayItemBackgroundView = indexPath.section == 0;
    cell.delegate = self.itemsDelegate;
    [cell setItem:item highlightedText:self.trimmedQuery];
}

- (DWContactsSearchDataSource *)searchDataSource {
    if (_searchDataSource == nil) {
        _searchDataSource = [[DWContactsSearchDataSource alloc] initWithFactory:self.itemsFactory
                                                                       firstFRC:self.firstFRC
                                                                      secondFRC:self.secondFRC];
    }
    return _searchDataSource;
}

@end
