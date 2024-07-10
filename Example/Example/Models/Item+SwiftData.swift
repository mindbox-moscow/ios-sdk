//
//  Item+SwiftData.swift
//  Example
//
//  Created by Sergei Semko on 6/11/24.
//  Copyright © 2024 Mindbox. All rights reserved.
//

import Foundation
import Mindbox
import SwiftData

@Model
public final class Item {
    public var timestamp: Date
    public var title: String
    public var body: String
    
//    public var mbPushNotification: MBPushNotification
    
//    public init(timestamp: Date, pushNotification: MBPushNotification) {
//        self.timestamp = timestamp
//        self.mbPushNotification = pushNotification
//    }
    
    public init(timestamp: Date, title: String, body: String) {
        self.timestamp = timestamp
        self.title = title
        self.body = body
    }
}
