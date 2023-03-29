//  
//  Created by PT
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

@objc(DWShortcutsModelDataSource)
protocol ShortcutsModelDataSource: AnyObject {
    func shouldShowCreateUserNameButton() -> Bool
}

@objc(DWShortcutsModelDelegate)
protocol ShortcutsModelDelegate: AnyObject {
    func shortcutItemsDidChange()
}

let MAX_SHORTCUTS_COUNT = 4

@objc(DWShortcutsModel)
class ShortcutsModel: NSObject {
    private var mutableItems: [ShortcutAction] = []
    
    weak var dataSource: ShortcutsModelDataSource?
    weak var delegate: ShortcutsModelDelegate?
    
    @objc
    init(dataSource: ShortcutsModelDataSource) {
        super.init()
        
        self.dataSource = dataSource
        
        reloadShortcuts()
    }

    var items: [ShortcutAction] {
        return mutableItems
    }

    @objc
    func reloadShortcuts() {
        mutableItems = Self.userShortcuts()
        delegate?.shortcutItemsDidChange()
    }

    static func userShortcuts() -> [ShortcutAction] {
        let options = DWGlobalOptions.sharedInstance()
        let walletNeedsBackup = options.walletNeedsBackup
        let userHasBalance = options.userHasBalance
        
        var mutableItems = [ShortcutAction]()
        mutableItems.reserveCapacity(3)
        
        if walletNeedsBackup {
            mutableItems.append(ShortcutAction(type: .secureWallet))
            
            if userHasBalance {
                mutableItems.append(ShortcutAction(type: .receive))
                mutableItems.append(ShortcutAction(type: .payToAddress))
                mutableItems.append(ShortcutAction(type: .scanToPay))
            } else {
                mutableItems.append(ShortcutAction(type: .explore))
                mutableItems.append(ShortcutAction(type: .receive))
                mutableItems.append(ShortcutAction(type: .buySellDash))
            }
        } else {
            if userHasBalance {
                mutableItems.append(ShortcutAction(type: .explore))
                mutableItems.append(ShortcutAction(type: .receive))
                mutableItems.append(ShortcutAction(type: .payToAddress))
                mutableItems.append(ShortcutAction(type: .scanToPay))
            } else {
                mutableItems.append(ShortcutAction(type: .explore))
                mutableItems.append(ShortcutAction(type: .receive))
                mutableItems.append(ShortcutAction(type: .buySellDash))
            }
        }
        
        return mutableItems
    }
}
