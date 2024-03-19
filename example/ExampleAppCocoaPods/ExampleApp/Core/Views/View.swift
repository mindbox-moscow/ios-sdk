//
//  View.swift
//  ExampleApp
//
//  Created by Sergei Semko on 3/19/24.
//

import UIKit

protocol ViewProtocol: AnyObject {
    func startAnimationOfActivityIndicator()
    func stopAnimationOfActivityIndicator()
    func showData(apnsToken: String, deviceUUID: String, sdkVersion: String)
    
    func addTriggerInAppTarget(_ target: Any?, action: Selector, for: UIControl.Event)
}

final class View: UIView {
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = Constants.mindboxColor
        return activityIndicator
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.spacing = 10
        return stackView
    }()
    
    private lazy var deviceUuidLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        label.alpha = Constants.startAlpha
        label.isUserInteractionEnabled = true
        
        label.layer.cornerRadius = Constants.cornerRadius
        label.layer.cornerCurve = .continuous
        label.layer.borderColor = Constants.mindboxColor.cgColor
        label.layer.borderWidth = 1
        
        return label
    }()
    
    private lazy var apnsTokenLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.alpha = Constants.startAlpha
        label.isUserInteractionEnabled = true
        
        label.layer.cornerRadius = Constants.cornerRadius
        label.layer.cornerCurve = .continuous
        label.layer.borderColor = Constants.mindboxColor.cgColor
        label.layer.borderWidth = 1
        
        return label
    }()
    
    private lazy var sdkVersionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .center
        label.alpha = Constants.startAlpha
        return label
    }()
    
    private lazy var inAppTriggerButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = Constants.startAlpha
        button.isHidden = true
        
        var configuration = UIButton.Configuration.filled()
        configuration.title = Constants.inAppTriggerButtonTitle
        configuration.image = Constants.inAppTriggerButtonImage
        configuration.baseBackgroundColor = Constants.mindboxColor
        configuration.cornerStyle = .medium
        
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 10,
            leading: 10,
            bottom: 10,
            trailing: 10
        )
        
        button.configuration = configuration
        
        return button
    }()
    
    private lazy var pushNotificationView = PushNotificationView()
    
    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
        setUpCopyData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createNotificationInfo(buttons: [(text: String?, url: String?)], urlFromPush: String, payload: String) {
        pushNotificationView.fillData(buttons: buttons, urlFromPush: urlFromPush, payload: payload)
//        if !urlFromPush.isEmpty {
//            let urlFromPushLabel = UILabel()
//            urlFromPushLabel.text = "URL from push: \(urlFromPush)"
//            urlFromPushLabel.alpha = 0
//            let stackViewsCount = stackView.subviews.count - 1
//            self.stackView.insertArrangedSubview(urlFromPushLabel, at: stackViewsCount - 1)
//            UIView.animate(withDuration: 1) {
//                urlFromPushLabel.alpha = 1
//            }
//        }
//        
//        if !payload.isEmpty {
//            let payloadLabel = UILabel()
//            payloadLabel.text = "Payload: \(payload)"
//            let stackViewsCount = stackView.subviews.count - 1
//            stackView.insertArrangedSubview(payloadLabel, at: stackViewsCount - 1)
//        }
//        
//        if !buttons.isEmpty {
//            for (index, button) in buttons.enumerated(){
//                let buttonLabel = UILabel()
//                buttonLabel.numberOfLines = 3
//                buttonLabel.textAlignment = .center
//                buttonLabel.text = "Button \(index + 1):\nText: \(button.text),\nURL: \(button.url)"
//                let stackViewsCount = stackView.subviews.count - 1
//                stackView.insertArrangedSubview(buttonLabel, at: stackViewsCount - 1)
//            }
//        }
        
    }
    
    // MARK: Private methods

    private func setUpLayout() {
        self.backgroundColor = .systemBackground
        
        self.addSubviews(
            activityIndicator,
            stackView
        )
        
        stackView.addArrangedSubviews(
            apnsTokenLabel,
            deviceUuidLabel,
            
            pushNotificationView,
            
            inAppTriggerButton,
            sdkVersionLabel
        )
        
        setUpConstraints()
    }
    
    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            
            inAppTriggerButton.heightAnchor.constraint(lessThanOrEqualToConstant: 70)
        ])
    }
    
    private func setUpCopyData() {
        apnsTokenLabel.addInteraction(UIContextMenuInteraction(delegate: self))
        deviceUuidLabel.addInteraction(UIContextMenuInteraction(delegate: self))
    }
}

extension View: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration?
    {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            
            let copyAction = UIAction(
                title: Constants.copyActionTitle,
                image: Constants.copyActionImage
            ) { action in
                
                var textToCopy: String = ""
                if interaction.view == self?.apnsTokenLabel {
                    guard let apnsToken = self?.apnsTokenLabel.text?.split(separator: " ").last else { return }
                    textToCopy = String(apnsToken)
                    print(textToCopy)
                }
                
                if interaction.view == self?.deviceUuidLabel {
                    guard let deviceUUID = self?.deviceUuidLabel.text?.split(separator: "\n").last else { return }
                    textToCopy = String(deviceUUID)
                    print(textToCopy)
                }
                
                UIPasteboard.general.string = textToCopy
            }
            
            return UIMenu(title: "", children: [copyAction])
        }
    }
}

// MARK: - ViewProtocol

extension View: ViewProtocol {
    func startAnimationOfActivityIndicator() {
        activityIndicator.startAnimating()
    }
    
    func stopAnimationOfActivityIndicator() {
        activityIndicator.stopAnimating()
    }
    
    func showData(apnsToken: String, deviceUUID: String, sdkVersion: String) {
        activityIndicator.stopAnimating()
        
        DispatchQueue.main.async {
            self.apnsTokenLabel.text = "APNS token: \(apnsToken)"
            self.deviceUuidLabel.text = "Device UUID:\n\(deviceUUID)"
            self.sdkVersionLabel.text = "SDK version: \(sdkVersion)"
            
            self.activityIndicator.stopAnimating()
            
            UIView.animate(withDuration: Constants.animationDuration) {
                self.apnsTokenLabel.alpha = Constants.endAlpha
                self.deviceUuidLabel.alpha = Constants.endAlpha
                self.sdkVersionLabel.alpha = Constants.endAlpha
                
                self.inAppTriggerButton.isHidden = false
                self.inAppTriggerButton.alpha = Constants.endAlpha
                
                if deviceUUID.isEmpty {
                    self.deviceUuidLabel.text = "Device UUID is missing"
                }
                
                if apnsToken.isEmpty {
                    self.apnsTokenLabel.text = "APNS token is missing"
                }
            }
        }
    }
    
    func addTriggerInAppTarget(_ target: Any?, action: Selector, for: UIControl.Event) {
        inAppTriggerButton.addTarget(target, action: action, for: `for`)
    }
}
