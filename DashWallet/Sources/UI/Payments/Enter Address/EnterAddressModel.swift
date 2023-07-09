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

final class EnterAddressModel: DWPayModel {
    var hasContentInPasteboard: Bool {
        UIPasteboard.general.hasStrings || UIPasteboard.general.hasImages || UIPasteboard.general.hasURLs
    }

    public func validate(address: String) -> Bool {
        let chain = DWEnvironment.sharedInstance().currentChain
        return address.isValidDashAddress(on: chain)
    }

    public func extraxtPasteboardStrings() -> String? {
        guard let strings = UIPasteboard.general.strings else {
            return nil
        }

        return strings.joined(separator: "\n")
    }
}
