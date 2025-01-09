//
//  Created by tkhp
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

import Foundation

// MARK: - CoinbaseTransactionDelegate

protocol CoinbaseTransactionDelegate: AnyObject {
    func transferFromCoinbaseToWalletDidSucceed()
    func transferFromCoinbaseToWalletDidFail(with error: Error)
    func transferFromCoinbaseToWalletDidCancel()
}

// MARK: - CoinbaseTransactionSendable

protocol CoinbaseTransactionSendable {
    /// Amount to transfer in Dash
    var amountToTransfer: UInt64 { get }
    var transactionDelegate: CoinbaseTransactionDelegate? { set get }

    func transferFromCoinbase()
    func continueTransferFromCoinbase(with verificationCode: String, idem: UUID)
}

extension CoinbaseTransactionSendable {
    func cancelTransferOperation() {
        transactionDelegate?.transferFromCoinbaseToWalletDidCancel()
    }

    func transferFromCoinbase() {
        let amount = amountToTransfer

        Task {
            try await transferFromCoinbase(amount: amount, with: nil)
        }
    }

    func continueTransferFromCoinbase(with verificationCode: String, idem: UUID) {
        let amount = amountToTransfer

        Task {
            try await transferFromCoinbase(amount: amount, with: verificationCode, for: idem)
        }
    }

    func transferFromCoinbase(amount: UInt64, with verificationCode: String?, for idem: UUID? = nil) async throws {
        do {
            _ = try await Coinbase.shared.transferFromCoinbaseToDashWallet(amount: amount, verificationCode: verificationCode, idem: idem)
            await MainActor.run {
                self.transactionDelegate?.transferFromCoinbaseToWalletDidSucceed()
            }
        } catch {
            await MainActor.run {
                self.transactionDelegate?.transferFromCoinbaseToWalletDidFail(with: error as! Coinbase.Error)
            }
        }
    }
}


