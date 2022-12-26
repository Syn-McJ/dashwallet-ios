//
//  CoinBasePlaceBuyOrderResponse.swift
//  Coinbase
//
//  Created by hadia on 31/05/2022.
//

import Foundation

// MARK: - CoinbasePlaceBuyOrder

struct CoinbasePlaceBuyOrder: Codable {
    let id: String? // TODO: Use just String and handle error
    let status: String?
    let userReference, transaction, createdAt, updatedAt: String?
    let resource: String?
    let resourcePath: String?
    let paymentMethod: PaymentMethod?
    let holdUntil: String?
    let holdDays: Int?
    let isFirstBuy: Bool?
    let fee: Amount
    let amount: Amount
    let total: Amount
    let subtotal: Amount
    let unitPrice: UnitPrice?
    let requiresCompletionStep: Bool?
    let committed: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case fee
        case status
        case userReference = "user_reference"
        case transaction
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case resource
        case resourcePath = "resource_path"
        case paymentMethod = "payment_method"
        case holdUntil = "hold_until"
        case holdDays = "hold_days"
        case isFirstBuy = "is_first_buy"
        case amount, total, subtotal
        case unitPrice = "unit_price"
        case requiresCompletionStep = "requires_completion_step"
        case committed
    }
}

// MARK: - PaymentMethod

struct PaymentMethod: Codable {
    let id, resource, resourcePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case resource
        case resourcePath = "resource_path"
    }
}

// MARK: - UnitPrice

struct UnitPrice: Codable {
    let amount, currency: String?
    let scale: Int?
}