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

import Moya

public enum MessageType: Int {
    case registerEmail = 1
    case withdrawal = 4
}

// MARK: - CrowdNodeEndpoint

public enum CrowdNodeEndpoint {
    case getTransactions(String)
    case getBalance(String)
    case getWithdrawalLimits(String)
    case isAddressInUse(String)
    case addressStatus(String)
    case hasDefaultEmail(String)
    case sendSignedMessage(address: String, message: String, signature: String, messagetype: MessageType)
    case getMessages(String)
    case getFees(String)
}

// MARK: TargetType

extension CrowdNodeEndpoint: TargetType {

    public var baseURL: URL {
        URL(string: CrowdNode.baseUrl)!
    }

    public var path: String {
        switch self {
        case .getTransactions(let address): return "odata/apifundings/GetFunds(address='\(address)')"
        case .getBalance(let address): return "odata/apifundings/GetBalance(address='\(address)')"
        case .getWithdrawalLimits(let address): return "odata/apifundings/GetWithdrawalLimits(address='\(address)')"
        case .isAddressInUse(let address): return "odata/apiaddresses/IsApiAddressInUse(address='\(address)')"
        case .addressStatus(let address): return "odata/apiaddresses/AddressStatus(address='\(address)')"
        case .hasDefaultEmail(let address): return "odata/apiaddresses/UsingDefaultApiEmail(address='\(address)')"
        case .sendSignedMessage(let address, let message, let signature, let messagetype): return "odata/apimessages/SendMessage(address='\(address)',message='\(message)',signature='\(signature)',messagetype=\(messagetype.rawValue))"
        case .getMessages(let address): return "odata/apimessages/GetMessages(address='\(address)')"
        case .getFees(let address): return "odata/apifundings/GetFeeJson(address='\(address)')"
        }
    }
    
    public var method: Moya.Method {
        .get
    }

    public var task: Moya.Task {
        .requestPlain
    }

    public var headers: [String : String]? {
        [:]
    }
}

final class CrowdNodeAPI: HTTPClient<CrowdNodeEndpoint> {
    static let shared = CrowdNodeAPI()
}
