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
import Combine

// MARK: - AmountType

enum AmountType {
    case main
    case supplementary
}

// MARK: - AmountInputItem

struct AmountInputItem: Equatable {
    let currencyName: String
    let currencyCode: String

    var isMain: Bool { currencyCode == kDashCurrency }

    static let dash = AmountInputItem(currencyName: kDashCurrency, currencyCode: kDashCurrency)
    static var app: AmountInputItem {
        .init(currencyName: App.fiatCurrency, currencyCode: App.fiatCurrency)
    }

    static func custom(currencyName: String, currencyCode: String) -> AmountInputItem {
        .init(currencyName: currencyName, currencyCode: currencyCode)
    }
}

// MARK: - BaseAmountModel

class BaseAmountModel: ObservableObject {
    var cancellableBag = Set<AnyCancellable>()
    var activeAmountType: AmountType { currentInputItem.isMain ? .main : .supplementary }

    var mainAmount: AmountObject!
    var supplementaryAmount: AmountObject!
    @Published var amount: AmountObject!
    @Published var walletBalance: UInt64 = 0
    
    var localCurrency: String {
        let locale = Locale.current as NSLocale
        return locale.displayName(forKey: .currencySymbol, value: localCurrencyCode)!
    }

    var error: Error? {
        didSet {
            if let error {
                errorHandler?(error)
            }
        }
    }

    var currentInputItem: AmountInputItem {
        didSet {
            inputsSwappedHandler?(activeAmountType)
        }
    }

    var inputItems: [AmountInputItem] = [] {
        didSet {
            amountInputItemsChangeHandler?()
        }
    }

    public var errorHandler: ((Error) -> Void)?
    public var presentCurrencyPickerHandler: (() -> Void)?
    public var inputsSwappedHandler: ((AmountType) -> Void)?
    public var amountInputItemsChangeHandler: (() -> Void)?

    public var isAllowedToContinue: Bool {
        isAmountValidForProceeding
    }

    var isAmountValidForProceeding: Bool {
        amount.plainAmount > 0
    }

    public var isEnteredAmountLessThenMinimumOutputAmount: Bool {
        let chain = DWEnvironment.sharedInstance().currentChain
        let amount = amount.plainAmount

        return amount < chain.minOutputAmount
    }

    public var minimumOutputAmountFormattedString: String {
        let chain = DWEnvironment.sharedInstance().currentChain
        return chain.minOutputAmount.formattedDashAmount
    }

    internal var mainAmountValidator: DWAmountInputValidator!
    internal var supplementaryAmountValidator: DWAmountInputValidator!

    internal var localFormatter: NumberFormatter
    var localCurrencyCode: String

    internal var supplementaryCurrencyCode: String {
        localCurrencyCode
    }

    internal var supplementaryNumberFormatter: NumberFormatter {
        localFormatter
    }

    internal var currencyExchanger: CurrencyExchanger {
        CurrencyExchanger.shared
    }

    init() {
        localCurrencyCode = App.fiatCurrency
        localFormatter = NumberFormatter.fiatFormatter(currencyCode: localCurrencyCode)

        currentInputItem = .dash
        inputItems = [
            .custom(currencyName: localCurrencyCode, currencyCode: localCurrencyCode),
            .dash,
        ]

        mainAmountValidator = DWAmountInputValidator(type: .dash)
        supplementaryAmountValidator = DWAmountInputValidator(type: .localCurrency)

        updateAmountObjects(with: "0")
        
        NotificationCenter.default.publisher(for: NSNotification.Name.DSWalletBalanceDidChange)
            .sink { [weak self] _ in self?.refreshBalance() }
            .store(in: &cancellableBag)
        
        refreshBalance()
    }

    func select(inputItem: AmountInputItem) {
        let currentAmount = amount!

        currentInputItem = inputItem

        if activeAmountType == .supplementary {
            if supplementaryAmount == nil && currentAmount.fiatCurrencyCode == supplementaryCurrencyCode {
                supplementaryAmount = mainAmount.localAmount
            } else if currentAmount.fiatCurrencyCode != supplementaryCurrencyCode {
                let mainAmount = AmountObject(plainAmount: currentAmount.plainAmount,
                                              fiatCurrencyCode: supplementaryCurrencyCode,
                                              localFormatter: supplementaryNumberFormatter,
                                              currencyExchanger: currencyExchanger)
                supplementaryAmount = mainAmount.localAmount
            }
        } else {
            if mainAmount == nil || mainAmount.fiatCurrencyCode != currentAmount.fiatCurrencyCode {
                mainAmount = supplementaryAmount.dashAmount
            }
        }

        amountDidChange()
    }

    func selectInputItem(at index: Int) {
        select(inputItem: inputItems[index])
    }

    func setupCurrencyCode(_ code: String) {
        guard let price = try? CurrencyExchanger.shared.rate(for: code) else { return }

        localFormatter = NumberFormatter.fiatFormatter(currencyCode: code)
        localCurrencyCode = code

        let newInputItem = AmountInputItem.custom(currencyName: localCurrencyCode, currencyCode: localCurrencyCode)
        currentInputItem = currentInputItem.isMain ? .dash : newInputItem
        inputItems = [
            newInputItem,
            .dash,
        ]

        let max = NSDecimalNumber(value: MAX_MONEY/DUFFS)
        localFormatter.maximum = NSDecimalNumber(decimal: price).multiplying(by: max)

        rebuildAmounts()
    }

    func updateAmountObjects(with inputString: String) {
        if activeAmountType == .main {
            mainAmount = AmountObject(dashAmountString: inputString,
                                      fiatCurrencyCode: supplementaryCurrencyCode,
                                      localFormatter: supplementaryNumberFormatter,
                                      currencyExchanger: currencyExchanger)
            supplementaryAmount = nil
        } else if let amount = AmountObject(localAmountString: inputString,
                                            fiatCurrencyCode: supplementaryCurrencyCode,
                                            localFormatter: supplementaryNumberFormatter,
                                            currencyExchanger: currencyExchanger) {
            supplementaryAmount = amount
            mainAmount = nil
        }

        amountDidChange()
    }

    internal func updateCurrentAmountObject(with amount: UInt64) {
        let amountObject = AmountObject(plainAmount: amount,
                                        fiatCurrencyCode: supplementaryCurrencyCode,
                                        localFormatter: supplementaryNumberFormatter,
                                        currencyExchanger: currencyExchanger)
        updateCurrentAmountObject(with: amountObject)
    }

    internal func updateCurrentAmountObject(with dashAmount: AmountObject) {
        if activeAmountType == .main {
            mainAmount = dashAmount
            supplementaryAmount = nil
        } else {
            mainAmount = nil
            supplementaryAmount = dashAmount.localAmount
        }

        amountDidChange()
    }

    internal func rebuildAmounts() {
        let amount = amount.amountInternalRepresentation
        updateAmountObjects(with: amount)
    }

    internal final func amountDidChange() {
        amount = activeAmountType == .main ? mainAmount : supplementaryAmount
        error = nil
        checkAmountForErrors()
    }

    internal func checkAmountForErrors() { }
    internal func selectAllFunds() { }
    
    private func refreshBalance() {
        walletBalance = DWEnvironment.sharedInstance().currentWallet.balance
    }
}

extension BaseAmountModel {
    var isLocalCurrencySelected: Bool {
        activeAmountType == .supplementary
    }

    var isSwapToLocalCurrencyAllowed: Bool {
        CurrencyExchanger.shared.hasRate(for: localCurrencyCode)
    }

    var fiatWalletBalanceFormatted: String {
        guard let fiatAmount = try? Coinbase.shared.currencyExchanger.convertDash(amount: walletBalance.dashAmount, to: App.fiatCurrency) else {
            return "Invalid"
        }

        let nf = supplementaryNumberFormatter
        return nf.string(from: fiatAmount as NSNumber)!
    }

    var walletBalanceFormatted: String {
        walletBalance.formattedDashAmount
    }
}

// MARK: AmountInputControlDataSource

extension BaseAmountModel: AmountInputControlDataSource {
    var currentInputString: String {
        amount.amountInternalRepresentation
    }

    var mainAmountString: String {
        amount.mainFormatted
    }

    var supplementaryAmountString: String {
        amount.supplementaryFormatted
    }
}

extension BaseAmountModel {
    @objc var isCurrencySelectorHidden: Bool {
        false
    }

    func updateInputField(with replacementText: String, in range: NSRange) {
        let lastInputString = amount.amountInternalRepresentation

        let validator: DWInputValidator
        let numberFormatter: NumberFormatter

        if activeAmountType == .main {
            validator = mainAmountValidator
            numberFormatter = NumberFormatter.dashFormatter
        } else {
            validator = supplementaryAmountValidator
            numberFormatter = supplementaryNumberFormatter
        }

        let validatedString = validator.validatedString(fromLastInputString: lastInputString,
                                                        range: range,
                                                        replacementString: replacementText,
                                                        numberFormatter: numberFormatter)
        guard let validatedString else {
            return
        }

        updateAmountObjects(with: validatedString)
    }

    func amountInputControlDidSwapInputs() {
        assert(inputItems.count == 2, "Swap only if we have two input types")

        let inputItem = inputItems[0] == currentInputItem ? inputItems[1] : inputItems[0]
        select(inputItem: inputItem)
    }

    func pasteFromClipboard() {
        guard let string = UIPasteboard.general.string else { return }

        let originalFormatter = currentInputItem.isMain
            ? NumberFormatter.dashFormatter
            : localFormatter
        let formatter = originalFormatter.copy() as! NumberFormatter
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = originalFormatter.maximumFractionDigits

        guard let number = formatter.number(from: string) else { return }

        formatter.numberStyle = .none
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = originalFormatter.maximumFractionDigits

        guard let string = formatter.string(from: number) else { return }

        updateAmountObjects(with: string)
    }
}
