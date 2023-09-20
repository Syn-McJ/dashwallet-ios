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

import AuthenticationServices
import SwiftUI
import UIKit

// MARK: - PortalViewController

@objc
final class PortalViewController: UIViewController {
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var networkStatusView: UIView!
    @IBOutlet var closeButton: UIBarButtonItem!

    private var dataSource: UICollectionViewDiffableDataSource<PortalModel.Section, ServiceItem>!
    private var currentSnapshot: NSDiffableDataSourceSnapshot<PortalModel.Section, ServiceItem>!

    private var model = PortalModel()
    private var hasNetwork: Bool { model.networkStatus == .online }

    @objc var showCloseButton = false

    @IBAction
    func closeAction() {
        dismiss(animated: true)
    }

    @objc
    func upholdAction() {
        let vc = DWUpholdViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc
    func coinbaseAction() {
        if Coinbase.shared.isAuthorized {
            let vc = IntegrationViewController.controller(model: CoinbaseEntryPointModel())
            vc.userSignedOutBlock = { [weak self] isNeedToShowSignOutError in
                guard let self else { return }

                self.navigationController!.popToViewController(self, animated: true)

                if isNeedToShowSignOutError {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now().advanced(by: .milliseconds(500))) {
                        self.showAlert(with: NSLocalizedString("Error", comment: ""),
                                       message: Coinbase.Error.userSessionRevoked.localizedDescription,
                                       presentingViewController: self)
                    }
                }
            }
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = ServiceOverviewViewController.controller()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc
    func topperAction() {
        let urlString = TopperViewModel.shared.topperBuyUrl(walletName: Bundle.main.infoDictionary!["CFBundleDisplayName"] as! String)
        if let url = URL(string: urlString) {
            let safariViewController = SFSafariViewController.dw_controller(with: url)
            present(safariViewController, animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.refreshData()
    }

    private func configureModel() {
        model.delegate = self
        model.networkStatusDidChange = { [weak self] status in
            self?.networkStatusView.isHidden = status == .online
            self?.collectionView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.dw_secondaryBackground()

        configureModel()
        configureHierarchy()

        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.topItem?.backButtonDisplayMode = .minimal
    }

    @objc
    class func controller() -> PortalViewController {
        vc(PortalViewController.self, from: sb("BuySellPortal"))
    }
}

// MARK: PortalModelDelegate

extension PortalViewController: PortalModelDelegate {
    func serviceItemsDidChange() {
        collectionView.reloadSections([0])
    }
}

extension PortalViewController {
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(64))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1.0))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(10)

        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }

    private func configureHierarchy() {
        if !showCloseButton {
            navigationItem.rightBarButtonItems = []
        }

        title = NSLocalizedString("Select a service", comment: "Buy Sell Dash")

        networkStatusView.isHidden = hasNetwork

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = createLayout()
    }
}

// MARK: UICollectionViewDelegate, UICollectionViewDataSource

extension PortalViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        model.items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = model.items[indexPath.item]

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as! PortalServiceItemCell
        cell.update(with: item, isEnabled: hasNetwork)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = model.items[indexPath.item]
        item.service.increaseUsageCount()

        switch item.service {
        case .uphold:
            upholdAction()
        case .coinbase:
            coinbaseAction()
        case .topper:
            topperAction()
        }
    }
}

