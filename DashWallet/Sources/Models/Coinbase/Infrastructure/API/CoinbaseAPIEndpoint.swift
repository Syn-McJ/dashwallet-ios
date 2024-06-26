//
//  CoinbaseAPIEndpoint.swift
//  Coinbase
//
//  Created by hadia on 28/05/2022.
//

import Foundation
import Moya

/// BaseUrl API Endpoint
private let kBaseURL = URL(string: "https://api.coinbase.com")!

let authBaseURL = URL(string: "https://coinbase.com")

// MARK: - CoinbaseAPIError

struct CoinbaseAPIError: Decodable {
    struct Error: Swift.Error, LocalizedError, Decodable {
        let id: ClientErrorID!

        /// Human readable message.
        let message: String

        /// Link to the documentation.
        let url: URL?

        var errorDescription: String? {
            message
        }

        /// List of available error codes.
        enum ClientErrorID: String, Decodable {
            /// When sending money over 2fa limit.
            ///
            /// Status Code: `402`.
            case twoFactorRequired = "two_factor_required"

            /// Missing parameter.
            ///
            /// Status Code: `400`.
            case paramRequired = "param_required"

            /// Unable to validate POST/PUT.
            ///
            /// Status Code: `400`.
            case validationError = "validation_error"

            /// Invalid request.
            ///
            /// Status Code: `400`.
            case invalidRequest = "invalid_request"

            /// User’s personal detail required to complete this request.
            ///
            /// Status Code: `400`.
            case personalDetailsRequired = "personal_details_required"

            /// Identity verification is required to complete this request.
            ///
            /// Status Code: `400`.
            case identityVerificationRequired = "identity_verification_required"

            /// Document verification is required to complete this request.
            ///
            /// Status Code: `400`.
            case jumioVerificationRequired = "jumio_verification_required"

            /// Document verification including face match is required to complete this request.
            ///
            /// Status Code: `400`.
            case jumioFaceMatchVerificationRequired = "jumio_face_match_verification_required"

            /// User has not verified their email.
            ///
            /// Status Code: `400`.
            case unverifiedEmail = "unverified_email"

            /// Invalid auth (generic).
            ///
            /// Status Code: `401`.
            case authenticationError = "authentication_error"

            /// Invalid Oauth token.
            ///
            /// Status Code: `401`.
            case invalidToken = "invalid_token"

            /// Revoked Oauth token.
            ///
            /// Status Code: `401`.
            case revokedToken = "revoked_token"

            /// Expired Oauth token.
            ///
            /// Status Code: `401`.
            case expiredToken = "expired_token"

            /// User hasn’t authenticated necessary scope.
            ///
            /// Status Code: `403`.
            case invalidScope = "invalid_scope"

            /// The provided authorization grant is invalid, expired, revoked
            ///
            /// Status Code: `401`.
            case invalidGrant = "invalid_grant"

            /// Resource not found.
            ///
            /// Status Code: `404`.
            case notFound = "not_found"

            /// Rate limit exceeded.
            ///
            /// Status Code: `429`.
            case rateLimitExceeded = "rate_limit_exceeded"

            /// Internal server error.
            ///
            /// Status Code: `500`.
            case internalServerError = "internal_server_error"
        }


    }

    var errors: [Error]
}

// MARK: - CoinbaseEndpoint

public enum CoinbaseEndpoint {
    case account(String)
    case accounts
    case deposit(accountId: String, dto: CoinbaseDepositRequest)
    case userAuthInformation
    case exchangeRates(String)
    case activePaymentMethods
    case placeBuyOrder(CoinbasePlaceBuyOrderRequest)
    case sendCoinsToWallet(accountId: String, verificationCode: String?, dto: CoinbaseTransactionsRequest)
    case getBaseIdForUSDModel(String)
    case swapTrade(CoinbaseSwapeTradeRequest)
    case swapTradeCommit(String)
    case accountAddress(String)
    case createCoinbaseAccountAddress(String)
    case getToken(String)
    case revokeToken(token: String)
    case refreshToken(refreshToken: String)
    case signIn
    case path(String)
}

// MARK: TargetType, AccessTokenAuthorizable

extension CoinbaseEndpoint: TargetType, AccessTokenAuthorizable {
    public var authorizationType: Moya.AuthorizationType? {
        switch self {
        case .signIn, .getToken, .refreshToken, .exchangeRates:
            return nil
        default:
            return .bearer
        }
    }

    public var baseURL: URL {
        guard case .path(let string) = self else {
            return kBaseURL
        }

        let path = string.removingPercentEncoding ?? string
        let url = URL(string: "https://api.coinbase.com" + path)!
        return url
    }

    public var path: String {
        switch self {
        case .account(let name): return "/v2/accounts/\(name)"
        case .accounts: return "/v2/accounts"
        case .deposit(let accountId, _): return "v2/accounts/\(accountId)/deposits"
        case .userAuthInformation: return "/v2/user/auth"
        case .exchangeRates: return "/v2/exchange-rates"
        case .activePaymentMethods: return "api/v3/brokerage/payment_methods"
        case .placeBuyOrder: return "api/v3/brokerage/orders"
        case .sendCoinsToWallet(let accountId, _, _): return "/v2/accounts/\(accountId)/transactions"
        case .getBaseIdForUSDModel: return "/v2/assets/prices"
        case .swapTrade: return "/v2/trades"
        case .swapTradeCommit(let tradeId): return "/v2/trades/\(tradeId)/commit"
        case .accountAddress(let accountId): return "/v2/accounts/\(accountId)/addresses"
        case .createCoinbaseAccountAddress(let accountId): return "/v2/accounts/\(accountId)/addresses"
        case .getToken, .refreshToken: return "/oauth/token"
        case .revokeToken: return "/oauth/revoke"
        case .signIn: return "/oauth/authorize"
        default:
            return ""
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getToken, .placeBuyOrder, .sendCoinsToWallet, .swapTrade, .swapTradeCommit, .createCoinbaseAccountAddress, .refreshToken, .revokeToken, .deposit:
            return .post
        default:
            return .get
        }
    }

    public var task: Moya.Task {
        switch self {
        case .getToken(let code):
            var queryItems: [String: Any] = [
                "redirect_uri": Coinbase.redirectUri,
                "code": code,
                "grant_type": Coinbase.grantType,
                "account": Coinbase.account,
            ]

            queryItems["client_id"] = Coinbase.clientID
            queryItems["client_secret"] = Coinbase.clientSecret
            
            return .requestParameters(parameters: queryItems, encoding: JSONEncoding.default)
        case .refreshToken(let refreshToken):
            var queryItems: [String: Any] = [
                "refresh_token": refreshToken,
                "grant_type": "refresh_token",
            ]

            queryItems["client_id"] = Coinbase.clientID
            queryItems["client_secret"] = Coinbase.clientSecret
            
            return .requestParameters(parameters: queryItems, encoding: JSONEncoding.default)
        case .revokeToken(let token):
            return .requestParameters(parameters: ["token": token], encoding: JSONEncoding.default)
        case .sendCoinsToWallet(_, _, let dto):
            return .requestJSONEncodable(dto)
        case .swapTrade(let dto):
            return .requestJSONEncodable(dto)
        case .placeBuyOrder(let dto):
            return .requestJSONEncodable(dto)
        case .deposit(_, let dto):
            return .requestJSONEncodable(dto)
        case .accounts:
            return .requestParameters(parameters: ["limit": 300, "order": "asc"], encoding: URLEncoding.default)
        case .getBaseIdForUSDModel(let base):
            return .requestParameters(parameters: [base: base, "filter": "holdable", "resolution": "latest"], encoding: URLEncoding.default)
        case .exchangeRates(let currency):
            return .requestParameters(parameters: ["currency": currency], encoding: URLEncoding.default)
        default:
            return .requestPlain
        }
    }

    public var headers: [String : String]? {
        var headers = ["CB-VERSION": "2021-09-07"]

        switch self {
        case .sendCoinsToWallet(_, let verificationCode, _):
            headers["CB-2FA-TOKEN"] = verificationCode
        default:
            break
        }

        // NOTE: Coinbase supports localizations (https://docs.cloud.coinbase.com/sign-in-with-coinbase/docs/localization)
        if #available(iOS 16, *), let lang = Locale.current.language.languageCode?.identifier(.alpha2) {
            headers["Accept-Language"] = lang
        } else if let lang = Locale.current.languageCode {
            headers["Accept-Language"] = lang
        }

        return headers
    }
}

extension Moya.Response {
    var error: CoinbaseAPIError? {
        let jsonDecoder = JSONDecoder()

        do {
            let result = try jsonDecoder.decode(CoinbaseAPIError.self, from: data)
            return result
        } catch {
            return nil
        }
    }

    var errorDescription: String? {
        guard let error else { return nil }

        return String(describing: error.errors)
    }
}
