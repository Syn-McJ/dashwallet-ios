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

import UIKit

// MARK: - TPActionTrampoline

//  Thanks Mike Ash
//  https://www.mikeash.com/pyblog/friday-qa-2015-12-25-swifty-targetaction.html
internal class TPActionTrampoline<T>: NSObject {
    var action: (T) -> Void

    init(action: @escaping (T) -> Void) {
        self.action = action
    }

    @objc
    func action(_ sender: NSObject) {
        action(sender as! T)
    }
}

let UIControlActionFunctionProtocolAssociatedObjectKey = UnsafeMutablePointer<Int8>.allocate(capacity: 1)

// MARK: - UIControlActionFunctionProtocol

public protocol UIControlActionFunctionProtocol { }

// MARK: - UIControl + UIControlActionFunctionProtocol

extension UIControl: UIControlActionFunctionProtocol { }

extension UIControlActionFunctionProtocol where Self: UIControl {
    public func addAction(_ events: UIControl.Event, _ action: @escaping (Self) -> Void) {
        let trampoline = TPActionTrampoline(action: action)
        addTarget(trampoline, action: #selector(TPActionTrampoline<Self>.action(_:)), for: events)
        objc_setAssociatedObject(self, UIControlActionFunctionProtocolAssociatedObjectKey, trampoline, .OBJC_ASSOCIATION_RETAIN)
    }
}
