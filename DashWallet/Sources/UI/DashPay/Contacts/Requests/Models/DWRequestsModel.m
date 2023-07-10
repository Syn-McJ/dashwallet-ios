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

#import "DWRequestsModel.h"

#import "DWBaseContactsModel+DWProtected.h"

@implementation DWRequestsModel

@synthesize requestsDataSource = _requestsDataSource;

- (instancetype)initWithRequestsDataSource:(DWFetchedResultsDataSource *)requestsDataSource {
    self = [super init];
    if (self) {
        _requestsDataSource = requestsDataSource;
    }
    return self;
}

- (DWFetchedResultsDataSource *)contactsDataSource {
    // Ignored requests are not implemented
    return nil;
}

- (BOOL)shouldFetchData {
    return NO;
}

@end
