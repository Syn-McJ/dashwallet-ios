//
//  CoinbaseService.swift
//  Coinbase
//
//  Created by hadia on 28/05/2022.
//

import Combine
import Foundation
import Moya

// MARK: - CoinbaseService

class CoinbaseService {
    private var httpClient: CoinbaseAPI {
        CoinbaseAPI.shared
    }
}

extension CoinbaseService { }

extension CoinbaseService {
    func getCoinbaseExchangeRates(currency: String) async throws -> CoinbaseExchangeRate {
        let result: BaseDataResponse<CoinbaseExchangeRate> = try await httpClient.request(.exchangeRates(currency))
        return result.data
    }

    func getCoinbaseBaseIDForCurrency(baseCurrency: String) async throws -> BaseDataCollectionResponse<CoinbaseBaseIDForCurrency> {
        try await httpClient.request(.getBaseIdForUSDModel(baseCurrency))
    }

    func swapTradeCoinbase(dto: CoinbaseSwapeTradeRequest) async throws -> BaseDataCollectionResponse<CoinbaseSwapeTrade> {
        try await httpClient.request(.swapTrade(dto))
    }

    func swapTradeCommitCoinbase(tradeId: String) async throws -> BaseDataCollectionResponse<CoinbaseSwapeTrade> {
        try await httpClient.request(.swapTradeCommit(tradeId))
    }

    func createCoinbaseAccountAddress(accountId: String) async throws -> String {
        do {
            let result: BaseDataResponse<CoinbaseAccountAddress> = try await httpClient.request(.createCoinbaseAccountAddress(accountId))
            return result.data.address
        } catch HTTPClientError.statusCode(let r) where r.statusCode == 401 {
            throw Coinbase.Error.userSessionExpired
        } catch {
            throw Coinbase.Error.transactionFailed(.failedToObtainNewAddress)
        }
    }
}
