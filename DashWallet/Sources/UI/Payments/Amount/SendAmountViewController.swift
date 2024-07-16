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

// MARK: - SendAmountViewController

class SendAmountViewController: BaseAmountViewController {
    override var isMaxButtonHidden: Bool { false }

    override var actionButtonTitle: String? { NSLocalizedString("Send", comment: "Send Dash") }

    internal var sendAmountModel: SendAmountModel {
        model as! SendAmountModel
    }

    init() {
        super.init(model: SendAmountModel())
    }

    override init(model: BaseAmountModel) {
        super.init(model: model)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func maxButtonAction() {
        sendAmountModel.selectAllFunds()
    }

    internal func checkLeftoverBalance(isCrowdNodeTransfer: Bool = false, completion: @escaping ((Bool) -> Void)) {
        if CrowdNodeDefaults.shared.lastKnownBalance <= 0 && !isCrowdNodeTransfer {
            // If CrowdNode balance is 0, then there is no need to check the leftover balance
            completion(true)
            return
        }

        // If CrowdNode balance isn't empty and the user sends DASH somewhere,
        // or if the user is making a CrowdNode deposit, then we need to check the leftover balance

        let account = DWEnvironment.sharedInstance().currentAccount
        let allAvailableFunds = account.maxOutputAmount

        if model.amount.plainAmount + CrowdNode.minimumLeftoverBalance > allAvailableFunds {
            let title = NSLocalizedString("Looks like you are emptying your Dash Wallet", comment: "Leftover balance warning")
            let message = String
                .localizedStringWithFormat(NSLocalizedString("Please note, you will not be able to withdraw your funds from CowdNode to this wallet until you increase your balance to %@ Dash.",
                                                             comment: "Leftover balance warning"),
                                           CrowdNode.minimumLeftoverBalance.formattedDashAmountWithoutCurrencySymbol)
            
            showModalDialog(icon: .system("info"), heading: title, textBlock1: message, positiveButtonText: NSLocalizedString("Continue", comment: "Leftover balance warning"), positiveButtonAction: {
                completion(true)
            }, negativeButtonText: NSLocalizedString("Cancel", comment: "Leftover balance warning")) {
                completion(false)
            }
        } else {
            completion(true)
        }
    }
}
