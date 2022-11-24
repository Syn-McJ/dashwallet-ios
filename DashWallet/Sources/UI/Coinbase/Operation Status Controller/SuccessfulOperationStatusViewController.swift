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

final class SuccessfulOperationStatusViewController: ActionButtonViewController, NavigationBarDisplayable {
    var isBackButtonHidden: Bool { return true }
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    var closeHandler: (() -> ())?
    
    var headerText: String! {
        didSet {
            titleLabel?.text = headerText
        }
    }
    
    var descriptionText: String! {
        didSet {
            descriptionLabel?.text = descriptionText
        }
    }
    
    override var actionButtonTitle: String? {
        return NSLocalizedString("Close", comment: "Action Button")
    }
    
    override func actionButtonAction(sender: UIView) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = headerText
        descriptionLabel.text = descriptionText
        actionButton?.isEnabled = true
        
        setupContentView(contentView)
    }
}
