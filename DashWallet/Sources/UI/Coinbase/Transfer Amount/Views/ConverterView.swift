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

enum ConverterViewDirection {
    case toWallet
    case toCoinbase
    
    fileprivate var fromSource: Source {
        return self == .toCoinbase ? .dash : .coinbase
    }
    
    fileprivate var toSource: Source {
        return self == .toCoinbase ? .coinbase : .dash
    }
    
    var next: Self {
        return self == .toCoinbase ? .toWallet : .toCoinbase
    }
}

protocol ConverterViewDataSource: AnyObject {
    var coinbaseBalance: String { get }
    var walletBalance: String { get }
}

class ConverterView: UIView {
    public weak var dataSource: ConverterViewDataSource? {
        didSet {
            updateView()
        }
    }
    
    private var fromView: SourceView!
    private var toView: SourceView!
    private var swapImageView: UIImageView!
    
    private var hairlineView: UIView!
    private var direction: ConverterViewDirection = .toCoinbase
    
    init(direction: ConverterViewDirection) {
        self.direction = direction
        
        super.init(frame: .zero)
        configureHierarchy()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureHierarchy()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func swapAction() {
        direction = direction.next
        updateView()
        
        UIView.animate(withDuration: 0.2) {
            self.swapImageView.transform = .init(rotationAngle: 0.9999 * CGFloat.pi)
        } completion: { completed in
            self.swapImageView.transform = .identity
        }
    }
}

extension ConverterView {
    private var balance: String {
        let balance = direction == .toCoinbase ? dataSource?.walletBalance : dataSource?.coinbaseBalance
        return balance ?? "0"
    }
    
    private func updateView() {
        fromView.update(with: direction.fromSource, balance: balance)
        toView.update(with: direction.toSource, balance: nil)
    }
    
    private func configureHierarchy() {
        backgroundColor = .dw_background()
        layer.cornerRadius = 10
        
        configureLeftSide()
        configureRightSide()
        updateView()
    }
    
    private func configureLeftSide() {
        let leftContainer = UIStackView()
        leftContainer.axis = .vertical
        leftContainer.distribution = .equalSpacing
        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        leftContainer.alignment = .center
        leftContainer.spacing = 22
        addSubview(leftContainer)
        
        let fromLabel = UILabel()
        fromLabel.font = .dw_regularFont(ofSize: 11)
        fromLabel.textColor = .secondaryLabel
        fromLabel.text = NSLocalizedString("FROM", comment: "Coinbase: transfer dash to/from")
        fromLabel.textAlignment = .center
        leftContainer.addArrangedSubview(fromLabel)
        
        swapImageView = UIImageView(image: UIImage(named: "coinbase.converter.switch"))
        swapImageView.isUserInteractionEnabled = true
        swapImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(swapAction)))
        leftContainer.addArrangedSubview(swapImageView)
        
        let toLabel = UILabel()
        toLabel.font = .dw_regularFont(ofSize: 11)
        toLabel.textColor = .secondaryLabel
        toLabel.text = NSLocalizedString("TO", comment: "Coinbase: transfer dash to/from")
        toLabel.textAlignment = .center
        leftContainer.addArrangedSubview(toLabel)
        
        NSLayoutConstraint.activate([
            leftContainer.topAnchor.constraint(equalTo: topAnchor, constant: 19),
            leftContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftContainer.widthAnchor.constraint(equalToConstant: 60),
            leftContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -19),
            
            fromLabel.heightAnchor.constraint(equalToConstant: 16),
            toLabel.heightAnchor.constraint(equalToConstant: 16),
        ])
    }
    
    private func configureRightSide() {
        let rightContainer = UIStackView()
        rightContainer.axis = .vertical
        rightContainer.spacing = 8
        rightContainer.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.backgroundColor = .clear
        addSubview(rightContainer)
        
        fromView = .init(frame: .zero)
        fromView.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.addArrangedSubview(fromView)
        
        let hairlineView = HairlineView()
        hairlineView.translatesAutoresizingMaskIntoConstraints = false
        hairlineView.alpha = 0.2
        rightContainer.addArrangedSubview(hairlineView)
        
        toView = .init(frame: .zero)
        toView.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.addArrangedSubview(toView)
        
        NSLayoutConstraint.activate([
            rightContainer.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            rightContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 62),
            rightContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            rightContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }
}

private enum Source {
    case dash
    case coinbase
    
    var imageName: String {
        switch self {
        case .dash: return "image.explore.dash.wts.dash"
        case .coinbase: return "Coinbase"
        }
    }
    
    var title: String {
        switch self {
        case .dash: return "Dash Wallet"
        case .coinbase: return "Coinbase"
        }
    }
}

private class SourceView: UIView {
    private var imageView: UIImageView!
    private var titleLabel: UILabel!
    private var walletBallanceLabel: UILabel!
    private var walletBalanceStackView: UIStackView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureHierarchy()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update(with source: Source, balance: String?) {
        imageView.image = UIImage(named: source.imageName)
        titleLabel.text = source.title
        
        if let balance = balance {
            walletBalanceStackView.isHidden = false
            
            let dashStr = "\(balance) DASH"
            let fiatStr = " ≈ \(balance)"
            let fullStr = "\(dashStr)\(fiatStr)"
            let string = NSMutableAttributedString(string: fullStr)
            string.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel], range: NSMakeRange(dashStr.count, fiatStr.count))
            string.addAttribute(.font, value: UIFont.dw_font(forTextStyle: .footnote), range: NSMakeRange(0, fullStr.count - 1))
            
            walletBallanceLabel.attributedText = string
        }else{
            walletBalanceStackView.isHidden = true
        }
    }
    
    private func configureHierarchy() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .top
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(imageView)
    
        let rightStackView = UIStackView()
        rightStackView.axis = .vertical
        rightStackView.spacing = 6
        rightStackView.alignment = .leading
        rightStackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(rightStackView)
        
        titleLabel = UILabel()
        titleLabel.font = .dw_font(forTextStyle: .body)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        rightStackView.addArrangedSubview(titleLabel)
        
        walletBalanceStackView = UIStackView()
        walletBalanceStackView.axis = .horizontal
        walletBalanceStackView.spacing = 8
        walletBalanceStackView.alignment = .center
        walletBalanceStackView.translatesAutoresizingMaskIntoConstraints = false
        rightStackView.addArrangedSubview(walletBalanceStackView)
        
        let walletImageView = UIImageView()
        walletImageView.translatesAutoresizingMaskIntoConstraints = false
        walletImageView.image = UIImage(named: "icon.wallet")
        walletBalanceStackView.addArrangedSubview(walletImageView)
        
        walletBallanceLabel = UILabel()
        walletBallanceLabel.font = .dw_font(forTextStyle: .footnote)
        walletBallanceLabel.translatesAutoresizingMaskIntoConstraints = false
        walletBalanceStackView.addArrangedSubview(walletBallanceLabel)
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 30),
            imageView.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}
