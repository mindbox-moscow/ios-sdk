//
//  LogManager.swift
//  MindboxLogger
//
//  Created by Sergei Semko on 4/12/24.
//  Copyright © 2024 Mindbox. All rights reserved.
//

import Foundation

final class SdkLogManager {
    
    static let shared = SdkLogManager()
    
    private let fileManager: FileManagerProtocol
    private let logFileName = "appLogs"
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd/MM, HH:mm:ss"
        return formatter
    }()
    
    private init(fileManager: FileManagerProtocol = SdkFileManager()) {
        self.fileManager = fileManager
    }
    
    func log(_ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(message)\n"
        
        if let logData = logMessage.data(using: .utf8) {
            do {
                try self.fileManager.append(toFileNamed: logFileName, data: logData)
            } catch {
                
            }
        }
    }
}
