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

import SwiftUI
import UIKit

// MARK: - TransferAmountView

struct TransferAmountView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TransferAmountViewController {
        TransferAmountViewController()
    }

    func updateUIViewController(_ viewController: TransferAmountViewController, context: Context) { }
}

// MARK: - TransferAmountViewController

final class TransferAmountViewController: SendAmountViewController {
    private var converterView: ConverterView!
    private var transferModel: TransferAmountModel { model as! TransferAmountModel }
    private var paymentController: PaymentController!

    private var networkUnavailableView: UIView!

    override var amountInputStyle: AmountInputControl.Style { .basic }

    private weak var codeConfirmationController: TwoFactorAuthViewController?

    override var actionButtonTitle: String? {
        NSLocalizedString("Transfer", comment: "Coinbase")
    }

    override func actionButtonAction(sender: UIView) {
        showActivityIndicator()
        transferModel.initializeTransfer()
    }

    override func initializeModel() {
        model = TransferAmountModel()
    }

    override func configureModel() {
        super.configureModel()

        transferModel.networkStatusDidChange = { [weak self] _ in
            self?.reloadView()
        }
        transferModel.delegate = self
    }

    override func configureHierarchy() {
        super.configureHierarchy()

        converterView = ConverterView(direction: .toCoinbase)
        converterView.delegate = self
        converterView.dataSource = model
        converterView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(converterView)

        networkUnavailableView = NetworkUnavailableView(frame: .zero)
        networkUnavailableView.translatesAutoresizingMaskIntoConstraints = false
        networkUnavailableView.isHidden = true
        contentView.addSubview(networkUnavailableView)

        NSLayoutConstraint.activate([
            converterView.topAnchor.constraint(equalTo: amountView.bottomAnchor, constant: 20),
            converterView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            converterView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            converterView.heightAnchor.constraint(equalToConstant: 128),

            networkUnavailableView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            networkUnavailableView.centerYAnchor.constraint(equalTo: numberKeyboard.centerYAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .dw_background()

        navigationItem.title = NSLocalizedString("Transfer Dash", comment: "Coinbase")
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.largeTitleDisplayMode = .never
    }
}

// MARK: TransferAmountModelDelegate

extension TransferAmountViewController: TransferAmountModelDelegate {
    func transferFromCoinbaseToWalletDidFail(with error: Error) {
        showAlert(with: "Error", message: error.localizedDescription)
    }

    func transferFromCoinbaseToWalletDidCancel() {
        hideActivityIndicator()
    }

    func initiatePayment(with input: DWPaymentInput) {
        paymentController = PaymentController()
        paymentController.delegate = self
        paymentController.presentationContextProvider = self
        paymentController.performPayment(with: input)
    }

    func transferFromCoinbaseToWalletDidSucceed() {
        codeConfirmationController?.dismiss(animated: true)
        codeConfirmationController = nil

        showSuccessTransactionStatus()
    }

    func transferFromCoinbaseToWalletDidFail(with reason: TransferFromCoinbaseFailureReason) {
        switch reason {
        case .twoFactorRequired:
            initiateTwoFactorAuth()
        case .invalidVerificationCode:
            codeConfirmationController?.showInvalidCodeState()
        case .unknown:
            hideActivityIndicator()
            showFailedTransactionStatus()
        }
    }

    private func initiateTwoFactorAuth() {
        let vc = TwoFactorAuthViewController.controller()
        vc.verifyHandler = { [weak self] code in
            self?.transferModel.continueTransferFromCoinbase(with: code)
        }
        vc.cancelHandler = { [weak self] in
            self?.transferModel.cancelTransferOperation()
        }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)

        codeConfirmationController = vc
    }
}

// MARK: ConverterViewDelegate

extension TransferAmountViewController: ConverterViewDelegate {
    func didChangeDirection(_ direction: ConverterViewDirection) {
        transferModel.direction = direction == .toCoinbase ? .toCoinbase : .toWallet
    }
}

// MARK: - BaseAmountModel + ConverterViewDataSource

extension BaseAmountModel: ConverterViewDataSource {
    var coinbaseBalanceFormatted: String {
        guard let balance = Coinbase.shared.lastKnownBalance else {
            return NSLocalizedString("Unknown Balance", comment: "Coinbase")
        }

        return balance.formattedDashAmount
    }

}

extension TransferAmountViewController {
    private func reloadView() {
        let isOnline = transferModel.networkStatus == .online
        networkUnavailableView.isHidden = isOnline
        numberKeyboard.isHidden = !isOnline
        actionButton?.isHidden = !isOnline
        converterView.hasNetwork = isOnline
    }

    private func showSuccessTransactionStatus() {
        let vc = SuccessfulOperationStatusViewController.initiate(from: sb("Coinbase"))
        vc.closeHandler = { [weak self] in
            guard let wSelf = self else { return }
            wSelf.navigationController?.popToViewController(wSelf.previousControllerOnNavigationStack!, animated: true)
        }
        vc.headerText = NSLocalizedString("Transfer successful", comment: "Coinbase")
        vc
            .descriptionText =
            NSLocalizedString("It could take up to 10 minutes to transfer Dash from Coinbase to Dash Wallet on this device",
                              comment: "Coinbase")
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showFailedTransactionStatus() {
        let vc = FailedOperationStatusViewController.initiate(from: sb("Coinbase"))
        vc.headerText = NSLocalizedString("Transfer Failed", comment: "Coinbase")
        vc.descriptionText = NSLocalizedString("There was a problem transferring it to Dash Wallet on this device",
                                               comment: "Coinbase")
        vc.retryHandler = { [weak self] in
            guard let wSelf = self else { return }
            wSelf.navigationController?.popToViewController(wSelf, animated: true)
        }
        vc.cancelHandler = { [weak self] in
            guard let wSelf = self else { return }
            wSelf.navigationController?.popToViewController(wSelf.previousControllerOnNavigationStack!, animated: true)
        }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - TransferAmountViewController + PaymentControllerDelegate

extension TransferAmountViewController: PaymentControllerDelegate {
    func paymentControllerDidFinishTransaction(_ controller: PaymentController, transaction: DSTransaction) {
        hideActivityIndicator()
        showSuccessTransactionStatus()
    }

    func paymentControllerDidCancelTransaction(_ controller: PaymentController) {
        hideActivityIndicator()
    }
}

// MARK: - TransferAmountViewController + PaymentControllerPresentationContextProviding

extension TransferAmountViewController: PaymentControllerPresentationContextProviding {
    func presentationAnchorForPaymentController(_ controller: PaymentController) -> PaymentControllerPresentationAnchor {
        self
    }
}
