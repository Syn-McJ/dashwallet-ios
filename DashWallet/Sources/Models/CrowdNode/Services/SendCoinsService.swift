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

import Combine

public class SendCoinsService {
    private let transactionManager: DSTransactionManager = DWEnvironment.sharedInstance().currentChainManager.transactionManager
    
    func sendCoins(address: String, amount: UInt64, inputSelector: SingleInputAddressSelector? = nil) async throws -> DSTransaction {
        let amount = UInt64(amount)
        let chain = DWEnvironment.sharedInstance().currentChain
        let account = DWEnvironment.sharedInstance().currentAccount
        let transaction = DSTransaction.init(on: chain)
        
        if (inputSelector == nil) {
            // Forming transaction normally
            let script = NSData.scriptPubKey(forAddress: address, for: chain)
            account.update(transaction, forAmounts: [amount], toOutputScripts: [script], withFee: true)
        } else {
            // Selecting proper inputs
            let balance = inputSelector!.selectFor(tx: transaction)
            transaction.addOutputAddress(address, amount: amount)

            let feeAmount = chain.fee(forTxSize: UInt(transaction.size) + UInt(TX_OUTPUT_SIZE))
            let change = balance - (amount + feeAmount)
            let changeAddress = inputSelector!.address
            transaction.addOutputAddress(changeAddress, amount: change)
            transaction.sortOutputsAccordingToBIP69()
        }
        
        await account.sign(transaction, withPrompt: nil)
        account.register(transaction, saveImmediately: false)
        let error = await transactionManager.publishTransaction(transaction)
        
        if (error != nil) {
            throw error
        }
        
        return transaction
    }
}
