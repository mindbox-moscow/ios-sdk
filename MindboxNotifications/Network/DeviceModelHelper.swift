//
//  DeviceModelHelper.swift
//  Mindbox
//
//  Created by Maksim Kazachkov on 02.02.2021.
//  Copyright © 2021 Mindbox. All rights reserved.
//

import Foundation
import UIKit.UIDevice
import MindboxLogger

struct DeviceModelHelper {
    
    static let os = UIDevice.current.systemName
    static let iOSVersion = UIDevice.current.systemVersion

    static let model: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else {
                Logger.common(message: "DeviceModelHelper: failed to cast element.value into Int8 or value == 0. element.value: \(element.value), value: \(0), identifier: \(identifier)", level: .error, category: .general)
                return identifier
            }
            Logger.common(message: "DeviceModelHelper: Successfully created identifier. Identifier: \(identifier)", level: .info, category: .general)
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()
    
}
