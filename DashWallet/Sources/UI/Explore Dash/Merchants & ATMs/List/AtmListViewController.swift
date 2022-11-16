//  
//  Created by Pavel Tikhonenko
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

import Foundation

enum AtmListSegmnets: Int {
    case all = 0
    case buy
    case sell
    case buyAndSell
    
    static func ==(lhs: PointOfUseListSegment, rhs: AtmListSegmnets) -> Bool {
        return lhs.tag == rhs.rawValue
    }
    
    var pointOfUseListSegment: PointOfUseListSegment {
        return .init(tag: self.rawValue, title: title, showMap: true, showLocationServiceSettings: false, showReversedLocation: true, dataProvider: dataProvider, filterGroups: filterGroups, territoriesDataSource: territories)
    }
}

extension AtmListSegmnets {
    var title: String {
        switch self {
        case .all:
            return NSLocalizedString("All", comment: "all")
        case .buy:
            return NSLocalizedString("Buy", comment: "buy")
        case .sell:
            return NSLocalizedString("Sell", comment: "Sell")
        case .buyAndSell:
            return NSLocalizedString("Buy/Sell", comment: "Buy/Sell")
        }
    }
    
    var dataProvider: PointOfUseDataProvider {
        switch self {
        case .all:
            return AllAtmsDataProvider()
        case .buy:
            return BuyAtmsDataProvider()
        case .sell:
            return BuyAndSellAtmsDataProvider()
        case .buyAndSell:
            return BuyAndSellAtmsDataProvider()
        }
    }
    
    var filterGroups: [PointOfUseListFiltersGroup] {
        return [.sortByName, .territory, .radius, .locationService]
    }
    
    var territories: TerritoryDataSource {
        return ExploreDash.shared.fetchTerritoriesForAtms
    }
}

@objc class AtmListViewController: ExplorePointOfUseListViewController {
    override func subtitleForFilterCell() -> String? {
        if DWLocationManager.shared.isAuthorized && currentSegment.showMap {
            if Locale.current.usesMetricSystem {
                return String(format: NSLocalizedString("%d ATM(s) in %@", comment: "#bc-ignore!"),  items.count, ExploreDash.distanceFormatter.string(from: Measurement(value: model.currentRadius, unit: UnitLength.meters)))
            }else{
                return String(format: NSLocalizedString("%d ATM(s) in %@", comment: "#bc-ignore!"),  items.count, ExploreDash.distanceFormatter.string(from: Measurement(value: model.currentRadiusMiles, unit: UnitLength.miles)))
            }
        }else{
            return super.subtitleForFilterCell()
        }
    }
    
    override func configureModel() {
        model = PointOfUseListModel(segments: [AtmListSegmnets.all.pointOfUseListSegment, AtmListSegmnets.buy.pointOfUseListSegment, AtmListSegmnets.sell.pointOfUseListSegment, AtmListSegmnets.buyAndSell.pointOfUseListSegment])
    }
    
    override func configureHierarchy() {
        self.title = NSLocalizedString("ATMs", comment: "");
        
        super.configureHierarchy()
        tableView.register(AtmItemCell.self, forCellReuseIdentifier: AtmItemCell.dw_reuseIdentifier)
    }

}
