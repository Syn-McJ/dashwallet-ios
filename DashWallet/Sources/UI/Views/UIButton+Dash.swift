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

extension UIButton.Configuration {
    public static func image(asset: UIImage) -> UIButton.Configuration {
        var style = UIButton.Configuration.plain()

        var background = style.background
        background.image = asset

        style.background = background
        return style
    }

    public static func dashPlain() -> UIButton.Configuration {
        var configuration = configuration(from: .plain())
        configuration.baseForegroundColor = .dw_dashBlue()
        return configuration
    }

    public static func dashGray() -> UIButton.Configuration {
        var configuration = configuration(from: .gray())
        configuration.baseForegroundColor = .dw_darkTitle()
        configuration.baseBackgroundColor = .dw_grayButton()
        return configuration
    }

    public static var tinted: UIButton.Configuration {
        var configuration = configuration(from: .tinted())
        configuration.baseBackgroundColor = .dw_dashBlue().withAlphaComponent(0.08)
        configuration.baseForegroundColor = .dw_dashBlue()

        var background = configuration.background
        background.backgroundColor = UIColor.dw_dashBlue().withAlphaComponent(0.08)
        configuration.background = background

        var attributedTitle = configuration.attributedTitle
        attributedTitle?.foregroundColor = configuration.baseForegroundColor
        configuration.attributedTitle = attributedTitle

        return configuration
    }

    public static func action() -> UIButton.Configuration {
        var configuration = configuration(from: .filled())

        var background = configuration.background
        background.cornerRadius = 8

        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = .dw_dashBlue()
        configuration.background = background
        return configuration
    }

    public static func configuration(from configuration: UIButton.Configuration, with title: String? = nil, and font: UIFont? = nil) -> UIButton.Configuration {
        var style = configuration
        style.imagePadding = 10

        var background = style.background
        background.cornerRadius = 6

        style.background = background

        if let font {
            var attributes = AttributeContainer()
            attributes.foregroundColor = style.baseForegroundColor
            attributes.font = font

            let attributedString = AttributedString(title ?? "", attributes: attributes)

            style.attributedTitle = attributedString
        } else if let title {
            style.title = title
        }

        return style
    }

    var font: UIFont {
        set {
            var attributes = AttributeContainer()
            attributes.foregroundColor = baseForegroundColor
            attributes.font = newValue

            let attributedString = AttributedString(title ?? "", attributes: attributes)
            attributedTitle = attributedString
        }

        get {
            attributedTitle?.font ?? .dw_font(forTextStyle: .body)
        }
    }

    public func settingFont(_ font: UIFont) -> UIButton.Configuration {
        var configuration = self

        var attributes = AttributeContainer()
        attributes.foregroundColor = configuration.baseForegroundColor
        attributes.font = font

        let attributedString = AttributedString(configuration.title ?? "", attributes: attributes)
        configuration.attributedTitle = attributedString

        return configuration
    }
}

// MARK: - TintedButton

class TintedButton: ActivityIndicatorButton {
    init() {
        super.init(configuration: .tinted)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func updateConfiguration() {
        guard let configuration else {
            return
        }

        var updatedConfiguration = configuration

        var background = configuration.background

        let accentColor: UIColor = (accentColor ?? configuration.baseForegroundColor) ?? .dw_dashBlue()

        var foregroundColor: UIColor?
        var backgroundColor: UIColor?

        switch state {
        case .normal:
            backgroundColor = accentColor.withAlphaComponent(0.08)
            foregroundColor = accentColor
        case .highlighted:
            backgroundColor = accentColor.withAlphaComponent(0.06)
            foregroundColor = accentColor.withAlphaComponent(0.9)
        case .disabled:
            backgroundColor = .dw_disabledButton()
            foregroundColor = .dw_disabledButtonText()
        default:
            backgroundColor = accentColor.withAlphaComponent(0.08)
            foregroundColor = accentColor
        }

        background.backgroundColorTransformer = UIConfigurationColorTransformer { _ in
            backgroundColor ?? .clear
        }

        updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in

            var container = incoming
            container.foregroundColor = foregroundColor

            return container
        }

        updatedConfiguration.background = background
        self.configuration = updatedConfiguration

        // Apply super configuration
        super.updateConfiguration()
    }
}

// MARK: - ImageButton

final class ImageButton: UIButton {
    init(image: UIImage) {
        super.init(frame: .zero)
        configuration = .image(asset: image)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: - ActionButton

@objc(DWActionButton)
class ActionButton: ActivityIndicatorButton {
    @objc
    init() {
        super.init(configuration: .action())
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        var actionConfiguration: UIButton.Configuration = .action()

        if let configuration {
            actionConfiguration.title = configuration.title
            actionConfiguration.baseForegroundColor = configuration.baseForegroundColor ?? actionConfiguration.baseForegroundColor
            actionConfiguration.baseBackgroundColor = configuration.baseBackgroundColor ?? actionConfiguration.baseBackgroundColor
        }

        configuration = actionConfiguration
    }

    override func updateConfiguration() {
        super.updateConfiguration()

        guard let configuration else {
            return
        }

        var updatedConfiguration = configuration

        let accentColor = (accentColor ?? configuration.baseBackgroundColor) ?? .dw_darkBlue()
        var background = configuration.background

        var strokeWidth: CGFloat = 0
        var strokeColor: UIColor?
        var foregroundColor: UIColor?
        var backgroundColor: UIColor?

        switch state {
        case .normal:
            backgroundColor = accentColor
            foregroundColor = .white
        case .highlighted:
            strokeWidth = 2
            strokeColor = accentColor
            foregroundColor = accentColor
            backgroundColor = .clear
        case .disabled:
            backgroundColor = .dw_disabledButton()
            foregroundColor = .dw_disabledButtonText()
        default:
            backgroundColor = accentColor
            foregroundColor = .white
        }

        background.strokeWidth = strokeWidth
        background.strokeColor = strokeColor

        if let backgroundColor {
            background.backgroundColorTransformer = UIConfigurationColorTransformer { _ in
                backgroundColor
            }
        }

        if let foregroundColor, !showsActivityIndicator {
            updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in

                var container = incoming
                container.foregroundColor = foregroundColor
                container.font = .dw_mediumFont(ofSize: 15)
                return container
            }
        }

        updatedConfiguration.background = background
        self.configuration = updatedConfiguration
    }
}

// MARK: - GrayButton

@objc
final class GrayButton: ActivityIndicatorButton {
    init() {
        super.init(configuration: .dashGray())
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        configuration = .dashGray()
    }

    override func updateConfiguration() {
        guard let configuration else {
            return
        }

        var updatedConfiguration = configuration

        var foregroundColor: UIColor?
        let accentColor = (accentColor ?? configuration.baseForegroundColor) ?? .dw_darkTitle()

        switch state {
        case .normal:
            foregroundColor = accentColor
        case .highlighted:
            foregroundColor = accentColor.withAlphaComponent(0.7)
        case .disabled:
            foregroundColor = accentColor.withAlphaComponent(0.1)
        default:
            foregroundColor = accentColor
        }

        if let foregroundColor {
            updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in

                var container = incoming
                container.foregroundColor = foregroundColor
                container.font = .dw_mediumFont(ofSize: 15)
                return container
            }
        }

        self.configuration = updatedConfiguration

        super.updateConfiguration()
    }
}

// MARK: - PlainButton

@objc
final class PlainButton: ActivityIndicatorButton {
    init() {
        super.init(configuration: .dashPlain())
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        configuration = .dashPlain()
    }

    override func updateConfiguration() {
        guard let configuration else {
            return
        }

        var updatedConfiguration = configuration

        let accentColor = (accentColor ?? configuration.baseForegroundColor) ?? .dw_dashBlue()

        var foregroundColor: UIColor?

        switch state {
        case .normal:
            foregroundColor = accentColor
        case .highlighted:
            foregroundColor = accentColor.withAlphaComponent(0.7)
        case .disabled:
            foregroundColor = .dw_disabledButtonText()
        default:
            foregroundColor = accentColor
        }

        if let foregroundColor {
            updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in

                var container = incoming
                container.foregroundColor = foregroundColor
                container.font = .title3
                return container
            }
        }

        self.configuration = updatedConfiguration

        super.updateConfiguration()
    }
}

// MARK: - ActivityIndicatorButton

class ActivityIndicatorButton: DWDashButton {
    final class ActivityIndicatorView: UIView {
        var color: UIColor {
            set {
                activityIndicator.color = newValue
            }
            get {
                activityIndicator.color
            }
        }

        private let activityIndicator: UIActivityIndicatorView!

        override init(frame: CGRect) {
            activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.hidesWhenStopped = false
            activityIndicator.color = .white

            super.init(frame: frame)

            addSubview(activityIndicator)
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public func start() {
            activityIndicator.startAnimating()
        }

        public func stop() {
            activityIndicator.stopAnimating()
        }
    }

    private var activityIndicatorView: ActivityIndicatorView!
    internal var showsActivityIndicator = false

    @objc
    public func showActivityIndicator() {
        if activityIndicatorView == nil {
            activityIndicatorView = ActivityIndicatorView()
        }

        activityIndicatorView.start()

        isUserInteractionEnabled = false
        showsActivityIndicator = true
        setNeedsUpdateConfiguration()
    }

    @objc
    public func hideActivityIndicator() {
        activityIndicatorView?.stop()

        isUserInteractionEnabled = true
        showsActivityIndicator = false
        setNeedsUpdateConfiguration()
    }

    override func updateConfiguration() {
        guard let configuration else {
            return
        }

        var updatedConfiguration = configuration

        var background = configuration.background

        var foregroundColor: UIColor?

        if showsActivityIndicator {
            // Use custom background to show activity indicator instead of updatedConfiguration.showsActivityIndicator property
            // Using updatedConfiguration.showsActivityIndicator doesn't hide the title label and we can't center the activity indicator
            activityIndicatorView.color = state == .normal ? .white : .darkGray
            background.customView = activityIndicatorView
            foregroundColor = .clear
        } else {
            background.customView = nil
        }

        if let foregroundColor {
            updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in

                var container = incoming
                container.foregroundColor = foregroundColor
                return container
            }
        }

        updatedConfiguration.background = background
        self.configuration = updatedConfiguration
    }
}


// MARK: - DashButton

class DWDashButton: UIButton {
    @IBInspectable
    public var accentColor: UIColor? {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }

    /// Configures the title label font.
    /// A nil value uses the default button's font: `UIFont.dw_font(forTextStyle: .body)`
    public var titleLabelFont: UIFont? {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }

    convenience init() {
        self.init(configuration: .dashPlain())
    }

    init(configuration: UIButton.Configuration = UIButton.Configuration.dashPlain()) {
        super.init(frame: .zero)

        self.configuration = configuration
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        if let configuration {
            self.configuration = UIButton.Configuration.configuration(from: configuration, with: nil, and: nil)
        } else {
            configuration = .dashPlain()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureButton()
    }

    override func updateConfiguration() {
        guard let configuration else {
            return
        }

        var updatedConfiguration = configuration

        if let titleLabelFont {
            var attributes = AttributeContainer()
            attributes.foregroundColor = accentColor ?? updatedConfiguration.baseForegroundColor
            attributes.font = titleLabelFont

            updatedConfiguration.attributedTitle = AttributedString(updatedConfiguration.title ?? "", attributes: attributes)
        }

        self.configuration = updatedConfiguration
    }

    private func configureButton() {
        // Dynamic type support
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.5
        titleLabel?.lineBreakMode = .byClipping

        NotificationCenter.default.addObserver(self, selector: #selector(setNeedsLayout), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
