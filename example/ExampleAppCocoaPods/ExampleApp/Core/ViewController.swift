//
//  ViewController.swift
//  ExampleApp
//
//  Created by Sergei Semko on 3/11/24.
//

import UIKit
import Mindbox

final class ViewController: UIViewController {
    
    private var deviceUUID: String = ""
    private var sdkVersion: String = ""
    private var apnsToken: String = ""
    
    private let router: Router
    
    private let eaView = View()
    
    // MARK: Init
    
    init(
        router: Router = EARouter()
    ) {
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Life Cycle
    
    override func loadView() {
        view = eaView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNotificationCenter()
        setUpDelegates()
        
        getDeviceUUID()
        getSdkVersion()
        getApnsTokenVersion()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        eaView.showData(apnsToken: apnsToken, deviceUUID: deviceUUID, sdkVersion: sdkVersion)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Private methods
    
    private func getDeviceUUID() {
        // https://developers.mindbox.ru/docs/ios-sdk-methods#getdeviceuuid
        Mindbox.shared.getDeviceUUID { deviceUUID in
            self.deviceUUID = deviceUUID
        }
        
        Mindbox.logger.log(level: .info, message: "Device UUID: \(self.deviceUUID)")
    }
    
    private func getSdkVersion() {
        // https://developers.mindbox.ru/docs/ios-sdk-methods#sdkversion
        sdkVersion = Mindbox.shared.sdkVersion
        
        Mindbox.logger.log(level: .info, message: "SDK version: \(sdkVersion)")
    }
    
    private func getApnsTokenVersion() {
        // https://developers.mindbox.ru/docs/ios-sdk-methods#getapnstoken
        Mindbox.shared.getAPNSToken({ [weak self] token in
            self?.apnsToken = token
        })
    }
    
    private func triggerInApp() {
        eaView.startAnimationOfActivityIndicator()
        
        /// https://developers.mindbox.ru/docs/in-app-targeting-by-custom-operation#ios
        let operationSystemName = "InAppTestOperationIOSExampleApp"
        let operationBody = OperationBodyRequest()
        
        // https://developers.mindbox.ru/docs/ios-integration-actions
        // https://developers.mindbox.ru/docs/ios-integration-actions#передача-и-получение-данных-от-mindbox--синхронное-выполнение
        Mindbox.shared.executeSyncOperation(
            operationSystemName: operationSystemName,
            operationBody: operationBody
        ) { [weak self] result in
            switch result {
            case .success(let operationResponse):
                Mindbox.logger.log(
                    level: .info,
                    message: "Operation \(operationSystemName) succeeded. Response: \(operationResponse)"
                )
            case .failure(let mindboxError):
                Mindbox.logger.log(
                    level: .info,
                    message: "Operation \(operationSystemName) failed. Error: \(mindboxError.localizedDescription)"
                )
            }
            
            self?.eaView.stopAnimationOfActivityIndicator()
        }
    }
    
    private func registerCustomer() {
        // https://developers.mindbox.ru/docs/ios-integration-actions#передача-данных-в-mindbox--асинхронное-выполнение
        let operationSystemName = "CustomerOperationIOSExampleApp"
        let operationBody = OperationBodyRequest()
        
        operationBody.customer = .init(
            birthDate: Date().asDateOnly,
            sex: .female,
            lastName: "Surname",
            firstName: "Name",
            middleName: nil,
            email: "example@example.com",
            ids: ["websideid": "id"],
            customFields: .init(
                [
                    "ExtraField": "Value",
                    "NewExtraField": "NewValue"
                ]
            ),
            subscriptions: [
                .init(
                    brand: "Brand",
                    pointOfContact: .email,
                    topic: "Topic",
                    isSubscribed: true
                )
            ]
        )
        
        Mindbox.shared.executeAsyncOperation(
            operationSystemName: operationSystemName,
            operationBody: operationBody
        )
    }
    
    private func setUpDelegates() {
        Mindbox.shared.inAppMessagesDelegate = self
    }
    
    private func setUpNotificationCenter() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMindboxNotification),
            name: Notification.Name(Constants.NotificationCenterName),
            object: nil
        )
    }
    
    @objc private func handleMindboxNotification(_ notification: Notification) {
        guard let notificationInfo = notification.userInfo as? [String: Any],
              let userInfo = notificationInfo["userInfo"] as? [AnyHashable: Any],
              let actionIdentifier = notificationInfo["actionIdentifier"] as? String else {
            return
        }
        
        if let pushModel = Mindbox.shared.getMindboxPushData(userInfo: userInfo),
           Mindbox.shared.isMindboxPush(userInfo: userInfo) {
            
            var buttons = [(text: String?, url: String?)]()
            
            if let mbButtons = pushModel.buttons {
                print(mbButtons.count)
                mbButtons.forEach { buttons.append((text: $0.text, url: $0.url)) }
            }
            
            var clickUrl = ""
            
            if let clickStringUrl = pushModel.clickUrl {
                clickUrl = clickStringUrl
            }
            
            var payloadText = ""
            
            if let payload = pushModel.payload {
                payloadText = payload
            }
            
            eaView.createNotificationInfo(buttons: buttons, urlFromPush: clickUrl, payload: payloadText)
        }
    }
}

// MARK: - InAppMessagesDelegate
/// Overriding the behavior when tapping on the InApp
/// Default behavior: https://developers.mindbox.ru/docs/in-app#defaultinappmessagedelegate

//https://developers.mindbox.ru/docs/in-app#inappmessagesdelegate
extension ViewController: InAppMessagesDelegate {
    func inAppMessageTapAction(id: String, url: URL?, payload: String) {
        Mindbox.logger.log(level: .debug, message: """
            Id: \(id)
            url: \(String(describing: url))
            payload: \(payload)
        """)
        
        router.showWebViewController(from: self, url: url)
    }
    
    func inAppMessageDismissed(id: String) {
        Mindbox.logger.log(level: .debug, message: "Dismiss InAppView")
    }
}
