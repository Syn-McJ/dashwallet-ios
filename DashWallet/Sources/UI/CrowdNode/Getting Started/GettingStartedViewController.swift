//
//  Created by Andrei Ashikhmin
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

import Combine

final class GettingStartedViewController: UIViewController {
    
    private let viewModel = CrowdNodeModel.shared
    private var cancellableBag = Set<AnyCancellable>()
    
    @IBOutlet var logoWrapper: UIView!
    @IBOutlet var newAccountButton: UIControl!
    @IBOutlet var newAccountTitle: UILabel!
    @IBOutlet var newAccountIcon: UIImageView!
    @IBOutlet var balanceHint: UIView!
    @IBOutlet var passphraseHint: UIView!
    @IBOutlet var linkAccountButton: UIControl!
    @IBOutlet var minimumBalanceLable: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureObservers()
    }
    
    @IBAction func newAccountAction() {
        if viewModel.canSignUp {
            self.navigationController?.pushViewController(NewAccountViewController.controller(), animated: true)
        }
    }
    
    @IBAction func linkAccountAction() {
        print("CrowdNode: linkAccountAction")
    }
    
    @IBAction func backupPassphraseAction() {
        let alert = UIAlertController(
            title: NSLocalizedString("Backup your passphrase to create a CrowdNode account", comment: ""),
            message: NSLocalizedString("If you lose your passphrase for this wallet and lose this device or uninstall Dash Wallet, you will lose access to your funds on CrowdNode and the funds within this wallet.", comment: ""),
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("Backup Passphrase", comment: ""), style: UIAlertAction.Style.default, handler: { [weak self] _ in
            self?.backupPassphrase()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: UIAlertAction.Style.cancel, handler: nil))
        self.navigationController?.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func buyDashAction() {
        let minimumDash = DSPriceManager.sharedInstance().string(forDashAmount: Int64(CrowdNodeConstants.minimumRequiredDash))!
        let alert = UIAlertController(
            title: NSLocalizedString("You have insufficient funds to proceed", comment: ""),
            message: NSLocalizedString("You should have at least \(minimumDash) to proceed with the CrowdNode verification.", comment: ""),
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("Buy Dash", comment: ""), style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: UIAlertAction.Style.cancel, handler: nil))
        self.navigationController?.present(alert, animated: true, completion: nil)
    }
    
    @objc static func controller() -> GettingStartedViewController {
        let storyboard = UIStoryboard(name: "CrowdNode", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "GettingStartedViewController") as! GettingStartedViewController
        return vc
    }
}

extension GettingStartedViewController {
    private func configureHierarchy() {
        logoWrapper.layer.dw_applyShadow(with: .dw_shadow(), alpha: 0.05, x: 0, y: 0, blur: 10)
        newAccountButton.layer.dw_applyShadow(with: .dw_shadow(), alpha: 0.1, x: 0, y: 0, blur: 10)
        linkAccountButton.layer.dw_applyShadow(with: .dw_shadow(), alpha: 0.1, x: 0, y: 0, blur: 10)
        
        let minimumDash = DSPriceManager.sharedInstance().string(forDashAmount: Int64(CrowdNodeConstants.minimumRequiredDash))!
        minimumBalanceLable.text = NSLocalizedString("You need at least \(minimumDash) on your Dash Wallet", comment: "")
        
        self.refreshCreateAccountButton()
    }
    
    private func configureObservers() {
        viewModel.$hasEnoughBalance
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                guard let wSelf = self else { return }
                wSelf.refreshCreateAccountButton()
            })
            .store(in: &cancellableBag)
    }
    
    private func refreshCreateAccountButton() {
        self.newAccountTitle.alpha = viewModel.canSignUp ? 1.0 : 0.2
        self.newAccountIcon.alpha = viewModel.canSignUp ? 1.0 : 0.2
        
        self.passphraseHint.isHidden = !viewModel.needsBackup
        let passhraseHintHeight = CGFloat(viewModel.needsBackup ? 45 : 0)
        self.passphraseHint.heightAnchor.constraint(equalToConstant: passhraseHintHeight).isActive = true
        
        self.balanceHint.isHidden = viewModel.hasEnoughBalance
        let balanceHintHeight = CGFloat(viewModel.hasEnoughBalance ? 0 : 45)
        self.balanceHint.heightAnchor.constraint(equalToConstant: balanceHintHeight).isActive = true
    }
}

extension GettingStartedViewController: DWSecureWalletDelegate {
    private func backupPassphrase() {
        Task {
            let result = await DSAuthenticationManager.sharedInstance().authenticate(withPrompt: nil, usingBiometricAuthentication: false, alertIfLockout: true)
            
            if result.0 {
                backupPassphraseAuthenticated()
            }
        }
    }
    
    private func backupPassphraseAuthenticated() {
        let model = DWPreviewSeedPhraseModel()
        model.getOrCreateNewWallet()
        let controller = DWBackupInfoViewController(model: model)
        controller.delegate = self
        let navigationController = DWNavigationController.init(rootViewController: controller)
        let cancelButton = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(self.dismissModalControllerBarButtonAction))
        controller.navigationItem.leftBarButtonItem = cancelButton
        self.navigationController?.present(navigationController, animated: true)
    }
    
    @objc private func dismissModalControllerBarButtonAction() {
        self.dismiss(animated: true)
    }
    
    internal func secureWalletRoutineDidCanceled(_ controller: UIViewController) { }
    
    internal func secureWalletRoutineDidVerify(_ controller: DWVerifiedSuccessfullyViewController) {
        dismissModalControllerBarButtonAction() // TODO check
        refreshCreateAccountButton()
    }
}
