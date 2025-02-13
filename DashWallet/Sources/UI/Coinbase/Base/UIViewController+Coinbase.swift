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

import UIKit

extension BaseViewController {
    public func showSuccessTransactionStatus(text: String) {
        let vc = SuccessfulOperationStatusViewController.initiate(from: sb("OperationStatus"))
        vc.closeHandler = { [weak self] in
            guard let wSelf = self else { return }
            guard let rootController = wSelf.navigationController?.controller(by: IntegrationViewController.self) else {
                wSelf.navigationController?.popToRootViewController(animated: true)
                return
            }

            wSelf.navigationController?.popToViewController(rootController, animated: true)
        }
        vc.headerText = NSLocalizedString("Transfer successful", comment: "Coinbase")
        vc.descriptionText = text

        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    public func showFailedTransactionStatus(text: String) {
        let vc = FailedOperationStatusViewController.initiate(from: sb("OperationStatus"))
        vc.headerText = NSLocalizedString("Transfer Failed", comment: "Coinbase")
        vc.descriptionText = text
        vc.supportButtonText = NSLocalizedString("Contact Coinbase Support", comment: "Coinbase")
        vc.retryHandler = { [weak self] in
            guard let wSelf = self else { return }
            wSelf.navigationController?.popToViewController(wSelf, animated: true)
        }
        vc.cancelHandler = { [weak self] in
            guard let wSelf = self else { return }
            wSelf.navigationController?.popToViewController(wSelf.previousControllerOnNavigationStack!, animated: true)
        }
        vc.supportHandler = { UIApplication.shared.open(kCoinbaseContactURL) }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - CoinbaseCodeConfirmationPreviewing

protocol CoinbaseCodeConfirmationPreviewing: ActivityIndicatorPreviewing {
    var codeConfirmationController: TwoFactorAuthViewController? { set get }
    var isCancelingToFail: Bool { get }
    func codeConfirmationControllerDidContinue(with code: String, for idem: UUID)
    func codeConfirmationControllerDidCancel()
}

extension CoinbaseCodeConfirmationPreviewing where Self: BaseViewController {
    var isCancelingToFail: Bool { false }

    func showCodeConfirmationController(idem: UUID) {
        let vc = TwoFactorAuthViewController.controller(idem: idem)
        vc.isCancelingToFail = isCancelingToFail
        vc.verifyHandler = { [weak self] (code: String, idem: UUID) in
            self?.codeConfirmationControllerDidContinue(with: code, for: idem)
        }
        vc.cancelHandler = { [weak self] in
            self?.codeConfirmationControllerDidCancel()
        }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)

        codeConfirmationController = vc
    }

    func showInvalidCodeState() {
        codeConfirmationController?.showInvalidCodeState()
    }
}

// MARK: - CoinbaseTransactionHandling

protocol CoinbaseTransactionHandling: CoinbaseCodeConfirmationPreviewing, CoinbaseTransactionDelegate, ErrorPresentable { }

extension CoinbaseTransactionHandling where Self: BaseViewController {
    func transferFromCoinbaseToWalletDidFail(with error: Error) {
        if case Coinbase.Error.transactionFailed(let r) = error {
            switch r {
            case .twoFactorRequired(let idem):
                showCodeConfirmationController(idem: idem)
            case .invalidVerificationCode:
                showInvalidCodeState()
            case .invalidAmount, .enteredAmountTooLow, .limitExceded, .notEnoughFunds:
                hideActivityIndicator()
                present(error: error)
            case .message(let msg):
                showFailedTransactionStatus(text: msg)
            default:
                showFailedTransactionStatus(text: r.localizedDescription)
            }
        } else {
            hideActivityIndicator()
            present(error: error)
        }
    }

    private func handleTransferFailure(with reason: Coinbase.Error.TransactionFailureReason) { }

    func transferFromCoinbaseToWalletDidCancel() {
        hideActivityIndicator()
    }

    func transferFromCoinbaseToWalletDidSucceed() {
        codeConfirmationController = nil
        showSuccessTransactionStatus(text: NSLocalizedString("It could take up to 10 minutes to transfer Dash from Coinbase to Dash Wallet on this device", comment: "Coinbase"))
    }
}
