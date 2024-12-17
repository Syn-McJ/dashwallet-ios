//  
//  Created by Andrei Ashikhmin
//  Copyright © 2024 Dash Core Group. All rights reserved.
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

struct ValidationCheck: View {
    let validationResult: UsernameValidationRuleResult
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            if validationResult == .loading {
                SwiftUI.ProgressView()
                    .frame(width: 18, height: 18)
                    .progressViewStyle(.circular)
            } else {
                Icon(name: getIconName())
                    .frame(width: 18, height: 18)
                    .foregroundColor(.systemYellow)
            }
            Text(text)
                .foregroundColor(.primaryText)
                .font(.body2)
        }
    }
    
    func getIconName() -> IconName {
        switch validationResult {
        case .empty, .hidden, .loading:
            .custom("username.requirement.empty")
        case .valid:
            .custom("username.requirement.accepted")
        case .invalid, .invalidCritical, .error:
            .custom( "username.requirement.rejected")
        case .warning:
            .system("exclamationmark.triangle.fill")
        }
    }
}
