//
//  Created by tkhp
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

// MARK: - AppObjcWrapper

@objc(DWApp)
class AppObjcWrapper: NSObject {
    @objc
    static var dashFormatter: NumberFormatter {
        NumberFormatter.dashFormatter
    }

    @objc static var localCurrencyCode: String {
        get {
            App.fiatCurrency
        }
        set {
            App.shared.fiatCurrency = newValue
        }
    }

    @objc
    class func cleanUp() {
        App.shared.cleanUp()
    }
}

// MARK: - App

class App {
    static func initialize() { }

    static let shared = App()

    func cleanUp() {
        TxUserInfoDAOImpl.shared.deleteAll()
        AddressUserInfoDAOImpl.shared.deleteAll()
    }
}
