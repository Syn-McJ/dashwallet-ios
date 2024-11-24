//  
//  Created by Andrei Ashikhmin
//  Copyright © 2024 Dash Core Group. All rights reserved.
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

//final class CoinJoinMixingTxSet: TransactionWrapper {
//    private var matchedFilters: [CoinJoinTxFilter] = []
//
//    var transactions: [Data: DSTransaction] = [:]
//
//    @discardableResult
//    func tryInclude(tx: DSTransaction) -> Bool {
//        if tx.timestamp < januaryFirst2022 {
//            return false
//        }
//
//        let txHashData = tx.txHashData
//
//        if transactions[txHashData] != nil {
//            // Already included, return true
//            return true
//        }
//
//        var crowdNodeTxFilters = [
//            CrowdNodeRequest(requestCode: ApiCode.signUp),
//            CrowdNodeResponse(responseCode: ApiCode.welcomeToApi, accountAddress: nil),
//            CrowdNodeRequest(requestCode: ApiCode.acceptTerms),
//            CrowdNodeResponse(responseCode: ApiCode.pleaseAcceptTerms, accountAddress: nil),
//        ]
//
//        if let accountAddress = savedAccountAddress {
//            crowdNodeTxFilters.append(CrowdNodeTopUpTx(address: accountAddress))
//        }
//
//        if let matchedFilter = crowdNodeTxFilters.first(where: { $0.matches(tx: tx) }) {
//            transactions[txHashData] = tx
//            matchedFilters.append(matchedFilter)
//
//            return true
//        }
//
//        return false
//    }
//}
