//
//  NotificationService.swift
//  MindboxNotificationServiceExtension
//
//  Created by Дмитрий Ерофеев on 30.03.2024.
//  Copyright © 2024 Mindbox. All rights reserved.
//

import UserNotifications
import MindboxNotifications
import Mindbox

class NotificationService: UNNotificationServiceExtension {
    
    lazy var mindboxService = MindboxNotificationService()
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
//        if let mindboxPushNotification = Mindbox.shared.getMindboxPushData(userInfo: request.content.userInfo) {
//            Task {
//                await saveSwiftDataItem(mindboxPushNotification)
//            }
//        }
        print("HELLO")
        Task {
            await saveSwiftDataItem(request)
        }
        
        mindboxService.didReceive(request, withContentHandler: contentHandler)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        mindboxService.serviceExtensionTimeWillExpire()
    }
    
//    @MainActor
//    private func saveSwiftDataItem(_ pushNotification: MBPushNotification) async {
//        let context = SwiftDataManager.shared.container.mainContext
//
//        let newItem = Item(timestamp: Date(), pushNotification: pushNotification)
//        
//        context.insert(newItem)
//        do {
//            try context.save()
//        } catch {
//            print("Failed to save context: \(error.localizedDescription)")
//        }
//    }
    
    @MainActor
    private func saveSwiftDataItem(_ request: UNNotificationRequest) async {
        let context = SwiftDataManager.shared.container.mainContext
        
        let userInfo = request.content.userInfo
        print(userInfo)
        guard let aps = userInfo["aps"] as? [AnyHashable: Any], 
                let alert = aps["alert"] as? [AnyHashable: Any],
                let title = alert["title"] as? String, let body = alert["body"] as? String else {
            return
        }
        
        print(title)
        print(body)


        let newItem = Item(timestamp: Date(), title: title, body: body)
//        let newItem = Item(timestamp: Date(), pushNotification: pushNotification)
        
        context.insert(newItem)
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
}
