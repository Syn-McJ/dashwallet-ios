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

extension UInt64 {
    // TODO: Find a better name, or just replace it with function toDecimal()
    var dashAmount: Decimal {
        Decimal(self)/Decimal(DUFFS)
    }

    /// Converts `UInt64` to formatted dash string. 123456780 -> "DASH 1"
    ///
    /// - Returns: Formatted dash amount
    ///
    var formattedDashAmount: String {
        dashAmount.formattedDashAmount
    }

    /// Converts `UInt64` to formatted dash string. 12345678 ->  "1.2345678"
    ///
    /// - Returns: Formatted dash amount without dash symbol
    ///
    var formattedDashAmountWithoutCurrencySymbol: String {
        dashAmount.formattedDashAmountWithoutCurrencySymbol
    }

    func formattedCryptoAmount(exponent: Int = 8) -> String {
        let plainNumber = Decimal(self)
        let number = plainNumber/pow(10, exponent)
        return number.string
    }
}

extension Int64 {
    var dashAmount: Decimal {
        Decimal(self)/Decimal(DUFFS)
    }

    var formattedDashAmount: String {
        dashAmount.formattedDashAmount
    }
}

extension Decimal {
    static var duffs: Decimal { Decimal(DUFFS) }

    var whole: Decimal {
        rounded(sign == .minus ? .up : .down)
    }

    var fractionDigits: Int {
        max(-exponent, 0)
    }

    /// Converts `Decimal` to plain dash amount in duffs
    ///
    /// - Returns: Plain dash amount in duffs
    ///
    var plainDashAmount: UInt64 {
        let plainAmount = self * .duffs
        return NSDecimalNumber(decimal: plainAmount.whole).uint64Value
    }

    /// Converts `Decimal` to formatted amount string for currently selected currency
    ///
    /// - Returns: Formatted fiat amount
    ///
    var formattedFiatAmount: String {
        NumberFormatter.fiatFormatter.string(from: self as NSNumber)!
    }

    /// Converts `Decimal` to formatted amount string for provided currency
    ///
    /// - Parameters:
    ///   - currency: Currency you want to use with NumberFormatter
    ///
    /// - Returns: Formatted fiat amount
    ///
    func formattedFiatAmount(_ currency: String) -> String {
        NumberFormatter.fiatFormatter(currencyCode: currency).string(from: self as NSNumber)!
    }

    /// Converts `Decimal` to formatted dash string. 123456780 -> "DASH 1"
    ///
    /// - Returns: Formatted dash amount
    ///
    var formattedDashAmount: String {
        NumberFormatter.dashFormatter.string(from: self as NSNumber)!
    }

    var formattedDashAmountWithoutCurrencySymbol: String {
        let formatter = NumberFormatter.dashDecimalFormatter
        return formatter.string(from: self as NSNumber)!
    }

    func rounded(_ mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var result = Decimal()
        var number = self
        NSDecimalRound(&result, &number, 0, mode)
        return result
    }

    var string: String {
        if #available(iOS 15.0, *) {
            return formatted(.number)
        } else {
            return "\(self)"
        }
    }
    
    /// Rounds the Decimal to a specified number of significant digits.
    ///
    /// - Parameters:
    ///   - significantDigits: The number of significant digits to round to.
    ///   - roundingMode: The rounding mode to use.
    /// - Returns: The rounded Decimal.
    func rounded(toSignificantDigits significantDigits: Int, roundingMode: NSDecimalNumber.RoundingMode) -> Decimal {
        let nsDecimal = NSDecimalNumber(decimal: self)
        guard nsDecimal != NSDecimalNumber.zero else { return self }
            
        let exponent = max(floor(log10(abs(nsDecimal.doubleValue))), 0)
        let scale = significantDigits - Int(exponent) - 1
            
        var result = Decimal()
        var selfCopy = self
        NSDecimalRound(&result, &selfCopy, scale, roundingMode)

        return result
    }
}

extension NSDecimalNumber {

    /// Converts `Decimal` to plain dash amount in duffs
    ///
    /// - Returns: Plain dash amount in duffs
    ///
    var plainDashAmount: UInt64 {
        let duffs = NSDecimalNumber(value: DUFFS)
        let amount = multiplying(by: duffs)
        return amount.uint64Value
    }

    var formattedDashAmount: String {
        decimalValue.formattedDashAmount
    }
}
