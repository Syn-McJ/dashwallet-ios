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

import XCTest
@testable import dashwallet

final class String_DashWallet: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testCurrencySymbolExtraction() {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.locale = .init(identifier: "en_US")
        
        var symbol = "$134".extractCurrencySymbol(using: nf)
        XCTAssertEqual("$", symbol, "Invalid symbol")
        
        nf.locale = .init(identifier: "ru_RU")
        symbol = "134$".extractCurrencySymbol(using: nf)
        XCTAssertEqual("$", symbol, "Invalid symbol")
    }
    
    func testFormattedAmountFromInputString() {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.locale = .init(identifier: "en_US")
        
        var txt = "$0".formattedAmount(with: "0.", numberFormatter: nf)
        XCTAssertEqual("$0.", txt, "Invalid")
        
        txt = "$0".formattedAmount(with: "0.0", numberFormatter: nf)
        XCTAssertEqual("$0.0", txt, "Invalid")
        
        txt = "$0.1234".formattedAmount(with: "0.1234", numberFormatter: nf)
        XCTAssertEqual("$0.1234", txt, "Invalid")
        
        nf.locale = .init(identifier: "ru_RU")
        txt = "0,1234$".formattedAmount(with: "0.1234", numberFormatter: nf, locale: .init(identifier: "ru_RU"))
        XCTAssertEqual("0.1234$", txt, "Invalid")
        
        txt = "1,1$".formattedAmount(with: "0.10", numberFormatter: nf, locale: .init(identifier: "ru_RU"))
        XCTAssertEqual("0.10$", txt, "Invalid")
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
