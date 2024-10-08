//
//  MainViewModel.swift
//  Example
//
//  Created by Дмитрий Ерофеев on 29.03.2024.
//  Copyright © 2024 Mindbox. All rights reserved.
//

import Foundation
import Mindbox
import Observation

@Observable final class MainViewModel {
    
    var SDKVersion: String = ""
    var deviceUUID: String = ""
    var APNSToken: String = ""
    var testUUID: String? = nil
    
    //https://developers.mindbox.ru/docs/ios-sdk-methods
    func setupData() {
        self.SDKVersion = Mindbox.shared.sdkVersion
        Mindbox.shared.getDeviceUUID { deviceUUID in
            DispatchQueue.main.async {
                self.deviceUUID = deviceUUID
            }
        }
        Mindbox.shared.getAPNSToken { APNSToken in
            DispatchQueue.main.async {
                self.APNSToken = APNSToken
            }
        }
        ChooseInAppMessagesDelegate.shared.select(chooseInappMessageDelegate: .InAppMessagesDelegate)
    }
    
    func getDeviceUUID() {
        JSCoreDownloader.shared.fetchJSON { _ in
            Mindbox.shared.getDeviceUUID { uuid in
                self.testUUID = uuid
            }
        }
    }
    
    //https://developers.mindbox.ru/docs/in-app-targeting-by-custom-operation
    func showInAppWithExecuteSyncOperation () {
        let json = """
        { "viewProduct":
            { "product":
                { "ids":
                    { "website": "1" }
                }
            }
        }
        """
        Mindbox.shared.executeSyncOperation(operationSystemName: "APIMethodForReleaseExampleIos", json: json) { result in
            switch result {
            case .success(let success):
                Mindbox.logger.log(level: .info, message: "\(success)")
            case .failure(let error):
                Mindbox.logger.log(level: .error, message: "\(error)")
            }
        }
    }
    
    //https://developers.mindbox.ru/docs/in-app-targeting-by-custom-operation
    func showInAppWithExecuteAsyncOperation () {
        let json = """
        { "viewProduct":
            { "product":
                { "ids":
                    { "website": "2" }
                }
            }
        }
        """
        Mindbox.shared.executeAsyncOperation(operationSystemName: "APIMethodForReleaseExampleIos", json: json)
    }
}
