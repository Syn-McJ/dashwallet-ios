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

// MARK: - CoinbaseRatesProvider

final class CoinbaseRatesProvider: RatesProvider {
    private let kRefreshTimeInterval: TimeInterval = 60

    var updateHandler: (([DSCurrencyPriceObject]) -> Void)?

    private var httpClient: CoinbaseAPI { CoinbaseAPI.shared }

    private var lastPriceSourceInfo: String!
    private var pricesByCode: [String: DSCurrencyPriceObject]!
    private var plainPricesByCode: [String: NSNumber]!

    func startExchangeRateFetching() {
        updateRates()
    }
}

extension CoinbaseRatesProvider {
    private func updateRates() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(kRefreshTimeInterval))) { [weak self] in
            self?.updateRates()
        }

        fetchPrices()
    }

    private func fetchPrices() {
        Task {
            let response: BaseDataResponse<CoinbaseExchangeRate> = try await httpClient.request(.exchangeRates(kDashCurrency))
            guard let rates = response.data.rates else { return }

            var pricesByCode: [String: DSCurrencyPriceObject] = [:]
            var plainPricesByCode: [String: NSNumber] = [:]

            for rate in rates {
                let key = rate.key
                let price = Decimal(string: rate.value)! as NSNumber
                pricesByCode[key] = .init(code: key, price: price)
                plainPricesByCode[key] = price
            }

            self.lastPriceSourceInfo = "Coinbase"
            self.pricesByCode = pricesByCode
            self.plainPricesByCode = plainPricesByCode

//            UserDefaults.standard.set(plainPricesByCode, forKey: self.kPriceByCodeKey)

            var array = pricesByCode
                .map { $0.value }
                .sorted(by: { $0.code < $1.code })

            let euroObj = pricesByCode["EUR"]!
            let usdObj = pricesByCode["USD"]!

            array.removeAll(where: { $0 == euroObj || $0 == usdObj })
            array.insert(euroObj, at: 0)
            array.insert(usdObj, at: 0)

            self.updateHandler?(array)
        }
    }
}
