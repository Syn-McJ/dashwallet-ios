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

typealias PaymentControllerPresentationAnchor = UIViewController

protocol AmountViewController where Self: BaseAmountViewController {
}

protocol PaymentControllerDelegate: AnyObject {
    func paymentControllerDidFinishTransaction(_ controller: PaymentController)
    func paymentControllerDidCancelTransaction(_ controller: PaymentController)
}

protocol PaymentControllerPresentationContextProviding: AnyObject {
    func presentationAnchorForPaymentController(_ controller: PaymentController) -> PaymentControllerPresentationAnchor
}

final class PaymentController: NSObject {
    weak var delegate: PaymentControllerDelegate?
    weak var presentationContextProvider: PaymentControllerPresentationContextProviding?
    
    private var paymentProcessor: DWPaymentProcessor
    private weak var confirmViewController: DWConfirmSendPaymentViewController?
    
    override init() {
        paymentProcessor = DWPaymentProcessor()
        
        super.init()
        
        paymentProcessor.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func performPayment(with input: DWPaymentInput) {
        paymentProcessor.reset()
        paymentProcessor.processPaymentInput(input)
    }
    
    public func performPayment(with file: Data) {
        paymentProcessor.reset()
        paymentProcessor.processFile(file)
    }
}

extension PaymentController {
    var presentationAnchor: PaymentControllerPresentationAnchor? { presentationContextProvider?.presentationAnchorForPaymentController(self)
    }
        
    fileprivate func showAlert(with title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel)
        alert.addAction(okAction)
        show(modalController: alert)
    }
    
    fileprivate func show(modalController: UIViewController) {
        precondition(presentationAnchor != nil)
        presentationAnchor!.present(modalController, animated: true)
    }
}

//MARK: DWConfirmPaymentViewControllerDelegate
extension PaymentController: DWConfirmPaymentViewControllerDelegate {
    func confirmPaymentViewControllerDidConfirm(_ controller: DWConfirmPaymentViewController) {
        if let vc = controller as? DWConfirmSendPaymentViewController, let output = vc.paymentOutput
        {
            self.paymentProcessor.confirmPaymentOutput(output)
        }
    }
}

//MARK: DWPaymentProcessorDelegate
extension PaymentController: DWPaymentProcessorDelegate{
    func paymentProcessor(_ processor: DWPaymentProcessor, didSweepRequest protocolRequest: DSPaymentRequest, transaction: DSTransaction) {
//        [self.navigationController.view dw_showInfoHUDWithText:NSLocalizedString(@"Swept!", nil)];
//
//        if ([self.navigationController.topViewController isKindOfClass:DWSendAmountViewController.class]) {
//            [self.navigationController popViewControllerAnimated:YES];
//        }
    }
    
    func paymentProcessor(_ processor: DWPaymentProcessor, requestAmountWithDestination sendingDestination: String, details: DSPaymentProtocolDetails?, contactItem: DWDPBasicUserItem) {
//        DWSendAmountViewController *controller =
//        [[DWSendAmountViewController alloc] initWithDestination:sendingDestination
//                                                 paymentDetails:nil
//                                                    contactItem:contactItem ?: [self contactItem]];
//        controller.delegate = self;
//        controller.demoMode = self.demoMode;
//        [self.navigationController pushViewController:controller animated:YES];
//        self.amountViewController = controller;
    }
    
    func paymentProcessor(_ processor: DWPaymentProcessor, requestUserActionTitle title: String?, message: String?, actionTitle: String, cancel cancelBlock: (() -> Void)?, actionBlock: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
            cancelBlock?()
            
            //            assert(!self.confirmViewController || self.confirmViewController.sendingEnabled, "paymentProcessorDidCancelTransactionSigning: should be called")
        }
        
        alert.addAction(cancelAction)
        
        let actionAction = UIAlertAction(title: actionTitle, style: .cancel) { _ in
            actionBlock?()
            
            self.confirmViewController?.sendingEnabled = true
        }
        
        alert.addAction(actionAction)
        self.show(modalController: alert)
    }
    
    func paymentProcessor(_ processor: DWPaymentProcessor, confirmPaymentOutput paymentOutput: DWPaymentOutput) {
        if let vc = confirmViewController {
            vc.paymentOutput = paymentOutput
        }else{
            let vc = DWConfirmSendPaymentViewController()
            vc.paymentOutput = paymentOutput
            vc.delegate = self
            
            //TODO: demo mode
            
            presentationAnchor?.present(vc, animated: true)
            confirmViewController = vc
        }
    }
    
    func paymentProcessorDidCancelTransactionSigning(_ processor: DWPaymentProcessor) {
        confirmViewController?.sendingEnabled = true
    }
    
    func paymentProcessor(_ processor: DWPaymentProcessor, didFailWithError error: Error?, title: String?, message: String?) {
        guard let error = error as? NSError else {
            return
        }
        
        if error.domain == DSErrorDomain &&
            (error.code == DSErrorInsufficientFunds || error.code == DSErrorInsufficientFundsForNetworkFee) {
            //show insufficient amount
        }
        
        presentationContextProvider?.presentationAnchorForPaymentController(self).view.dw_hideProgressHUD()
        self.showAlert(with: title, message: message)
        
        self.confirmViewController?.sendingEnabled = true
    }
    
    func paymentProcessor(_ processor: DWPaymentProcessor, didSend protocolRequest: DSPaymentProtocolRequest, transaction: DSTransaction, contactItem: DWDPBasicUserItem?) {
        presentationContextProvider?.presentationAnchorForPaymentController(self).view.dw_hideProgressHUD()
        
        if let vc = confirmViewController {
            presentationAnchor?.dismiss(animated: true)
        }else{
            
        }
        
        delegate?.paymentControllerDidFinishTransaction(self)
        
//        let vc = SuccessTxDetailViewController()
//        vc.modalPresentationStyle = .fullScreen
//        vc.model = TxDetailModel(transaction: transaction, dataProvider: DWTransactionListDataProvider())
//        vc.contactItem = contactItem
//        //vc.delegate = self
//        presentationAnchor?.present(vc, animated: true)
    }
    
    func paymentProcessorDidFinishProcessingFile(_ processor: DWPaymentProcessor) {
        
    }
    
    func paymentInputProcessorHideProgressHUD(_ processor: DWPaymentProcessor) {
        presentationAnchor?.view.dw_hideProgressHUD()
    }
    
    func paymentProcessor(_ processor: DWPaymentProcessor, displayFileProcessResult message: String) {
        showAlert(with: message, message: nil)
    }
    
    func paymentProcessor(_ processor: DWPaymentProcessor, showProgressHUDWithMessage message: String?) {
        presentationAnchor?.view.dw_showProgressHUD(withMessage: message)
    }
}

