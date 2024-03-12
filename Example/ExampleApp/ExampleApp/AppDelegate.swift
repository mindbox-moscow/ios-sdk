//
//  AppDelegate.swift
//  ExampleApp
//
//  Created by Дмитрий Ерофеев on 11.03.2024.
//

import UIKit
import Mindbox
import Foundation


@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        do {
                    
            let mindboxSdkConfig = try MBConfiguration(
                endpoint: "Mpush-test.ExampleApp.IosApp",
              domain: "api.mindbox.ru",
              subscribeCustomerIfCreated: true,
              shouldCreateCustomer: true
            )
            
            Mindbox.shared.initialization(configuration: mindboxSdkConfig)
            Mindbox.shared.getDeviceUUID{
                deviceUUID in print(deviceUUID)
            }
        } catch  {
           print(error)
        }
       
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

