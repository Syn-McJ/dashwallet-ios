//
//  Created by tkhp
//  Copyright © 2023 Dash Core Group. All rights reserved.
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

// MARK: - UpholdRequestTransferModelState

enum UpholdRequestTransferModelState {
    case none
    case loading
    case success
    case fail
    case failInsufficientFunds
    case otp
}

// MARK: - UpholdAmountModel

final class UpholdAmountModel: BaseAmountModel {
    public let card: DWUpholdCardObject
    public var transaction: DWUpholdTransactionObject?
    public var state: UpholdRequestTransferModelState = .none {
        didSet {
            if oldValue != state {
                stateHandler?(state)
            }
        }
    }

    public var stateHandler: ((UpholdRequestTransferModelState) -> Void)?

    override var isAllowedToContinue: Bool {
        isAmountValidForProceeding &&
            card.available.plainDashAmount >= amount.plainAmount
    }

    private var createTransactionCancellationToken: DWUpholdCancellationToken?

    init(card: DWUpholdCardObject) {
        self.card = card
    }

    func selectAllFunds() {
        let allAvailableFunds = card.available.plainDashAmount

        if allAvailableFunds > 0 {
            let maxAmount = AmountObject(plainAmount: allAvailableFunds,
                                         fiatCurrencyCode: supplementaryCurrencyCode,
                                         localFormatter: supplementaryNumberFormatter,
                                         currencyExchanger: currencyExchanger)
            updateCurrentAmountObject(with: maxAmount)
        }
    }

    func createTransaction(with otpToken: String?) {
        assert(stateHandler != nil, "StateHandler must be initialized")

        let amount = String(describing: amount.plainAmount.dashAmount)
        createTransaction(for: amount, feeWasDeductedFromAmount: false, otpToken: otpToken)
    }

    override func checkAmountForErrors() {
        guard card.available.plainDashAmount >= amount.plainAmount else {
            error = SendAmountError.insufficientFunds
            return
        }

        error = nil
    }

    private func createTransaction(for amount: String, feeWasDeductedFromAmount: Bool, otpToken: String?) {
        guard let receiveAddress = DWEnvironment.sharedInstance().currentAccount.receiveAddress else {
            fatalError("Address should exist")
        }

        state = .loading
        createTransactionCancellationToken?.cancel()

        let client = DWUpholdClient.sharedInstance()

        createTransactionCancellationToken = client.createTransaction(forDashCard: card,
                                                                      amount: amount,
                                                                      address: receiveAddress,
                                                                      otpToken: otpToken) { [weak self] tx, otpRequired in
            guard let self else { return }

            self.createTransactionCancellationToken = nil
            self.transaction = tx

            if otpRequired {
                Taxes.shared.mark(address: receiveAddress, with: .transferIn)
                self.state = .otp
            } else if let tx {
                Taxes.shared.mark(address: receiveAddress, with: .transferIn)

                let card = self.card;

                let notSufficientFunds = tx.total.compare(card.available) == .orderedDescending
                guard !notSufficientFunds else {
                    let amountNumber = Decimal(string: amount)!
                    let correctedAmountNumber = amountNumber - tx.fee.decimalValue
                    let correctedAmount = String(describing: correctedAmountNumber)

                    if correctedAmountNumber.isLessThanOrEqualTo(.zero) {
                        self.state = .failInsufficientFunds
                    } else {
                        self.createTransaction(for: correctedAmount, feeWasDeductedFromAmount: true, otpToken: nil)
                    }

                    return
                }

                tx.feeWasDeductedFromAmount = feeWasDeductedFromAmount

                self.state = .success
            } else {
                self.state = .fail
            }
        }
    }

    func resetCreateTransactionState() {
        transaction = nil
        state = .none
    }
}

// MARK: ConverterViewDataSource

extension UpholdAmountModel: ConverterViewDataSource {
    var fromItem: SourceViewDataProvider? {
        ConverterViewSourceItem(image: .asset("uphold_logo"),
                                title: "Uphold",
                                balanceFormatted: card.formattedDashAmount,
                                fiatBalanceFormatted: card.fiatBalanceFormatted)
    }

    var toItem: SourceViewDataProvider? {
        ConverterViewSourceItem.dash()
    }
}

extension DWUpholdCardObject {
    var formattedDashAmount: String {
        available.formattedDashAmount
    }

    var fiatBalanceFormatted: String {
        let amount = available.decimalValue
        guard let fiatAmount = try? CurrencyExchanger.shared.convertDash(amount: amount, to: App.fiatCurrency) else {
            return NSLocalizedString("Updating Price", comment: "Exchange")
        }

        let nf = NumberFormatter.fiatFormatter(currencyCode: App.fiatCurrency)
        return nf.string(from: fiatAmount as NSNumber)!
    }
}
