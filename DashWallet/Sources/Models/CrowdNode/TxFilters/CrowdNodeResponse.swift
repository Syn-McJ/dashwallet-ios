//
//  Created by Andrei Ashikhmin
//  Copyright © 2022 Dash Core Group. All rights reserved.
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

public final class CrowdNodeResponse: CoinsToAddressTxFilter {
    let responseCode: ApiCode

    init(responseCode: ApiCode, accountAddress: String?) {
        self.responseCode = responseCode
        let accountAddress = accountAddress
        let responseAmount = CrowdNode.apiOffset + responseCode.rawValue

        super.init(coins: responseAmount, address: accountAddress)
    }

    override func matches(tx: DSTransaction) -> Bool {
        super.matches(tx: tx) && fromAddresses.first == CrowdNode.crowdNodeAddress && toAddress != CrowdNode.crowdNodeAddress
    }
}
