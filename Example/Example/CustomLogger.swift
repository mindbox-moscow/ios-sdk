//
//  CustomLogger.swift
//  Example
//
//  Created by Sergei Semko on 7/11/24.
//  Copyright © 2024 Mindbox. All rights reserved.
//

import UIKit
import OSLog

@available(iOS 14.0, *)
public extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let customLogs = Logger(subsystem: subsystem, category: "CustomLogs")
    
    static let inApps = Logger(subsystem: subsystem, category: "InApps")
    
    static let appState = Logger(subsystem: subsystem, category: "AppState")
    
    static func logAppState(funcName: String) {
        DispatchQueue.main.async {
            let appState = UIApplication.shared.applicationState
            let stateDescription: String
            switch appState {
            case .active:
                stateDescription = "active"
            case .inactive:
                stateDescription = "inactive"
            case .background:
                stateDescription = "background"
            @unknown default:
                stateDescription = "unkown"
            }
            Logger.appState.info("\(funcName, privacy: .public): \(stateDescription, privacy: .public)")
        }
    }
}

public final class LogManager {
    
    public static let shared = LogManager()
    
    private let fileManager: SdkFileManagerProtocol
    
    private let logFile = "appLogs"
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd/MM, HH:mm:ss"
        return formatter
    }()
    
    private init(fileManager: SdkFileManagerProtocol = SdkFileManager()) {
        self.fileManager = fileManager
        logLaunchApp()
    }
    
    private func logLaunchApp() {
        let timestamp = dateFormatter.string(from: Date())
        let message = "New launch app \(Array(repeating: "=", count: 123).joined())"
        let logMessage = "\n\n\n[\(timestamp)] \(message)\n"
        
        if let logData = logMessage.data(using: .utf8) {
            do {
                try self.fileManager.append(toFileNamed: logFile, data: logData)
            } catch {
                
            }
        }
    }
    
    public func log(_ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(message)\n"
        
        if #available(iOS 14.0, *) {
            Logger.customLogs.notice("\(logMessage, privacy: .public)")
        }
        
        if let logData = logMessage.data(using: .utf8) {
            do {
                try self.fileManager.append(toFileNamed: logFile, data: logData)
            } catch {
                
            }
        }
    }
}

fileprivate protocol SdkFileManagerProtocol {
    func append(toFileNamed fileName: String, data: Data) throws
}

fileprivate final class SdkFileManager {
    
    private let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    private func makeURL(forFileNamed fileName: String) -> URL? {
        guard let url = fileManager.urls(
            for: .libraryDirectory,
            in: .userDomainMask).first
        else {
            return nil
        }
        
        let logsDirectoryURL = url.appendingPathComponent("Logs")
        
        if !fileManager.fileExists(atPath: logsDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: logsDirectoryURL, withIntermediateDirectories: true)
            } catch {
                debugPrint(FileManagerError.creatingLogsDirectoryFailed.localizedDescription)
                return nil
            }
        }

        return logsDirectoryURL.appendingPathComponent(fileName)
    }
}

extension SdkFileManager: SdkFileManagerProtocol {
    fileprivate func append(toFileNamed fileName: String, data: Data) throws {
        guard let url = makeURL(forFileNamed: fileName) else {
            throw FileManagerError.invalidDirectory
        }
        
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try data.write(to: url, options: [.noFileProtection, .atomic])
            } catch {
                throw FileManagerError.creatingFileFailed
            }
        } else {
            if let fileHandle = try? FileHandle(forWritingTo: url) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                throw FileManagerError.writingFailed
            }
        }
    }
}

fileprivate enum FileManagerError: Error {
    case fileAlreadyExists
    case invalidDirectory
    case writingFailed
    case fileNotExist
    case readingFailed
    case creatingFileFailed
    case creatingLogsDirectoryFailed
}
