//
//  FileManager.swift
//  MindboxLogger
//
//  Created by Sergei Semko on 4/12/24.
//  Copyright © 2024 Mindbox. All rights reserved.
//

import Foundation

protocol FileManagerProtocol {
    func append(toFileNamed fileName: String, data: Data) throws
}

final class SdkFileManager {
    
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

extension SdkFileManager: FileManagerProtocol {
    func append(toFileNamed fileName: String, data: Data) throws {
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

enum FileManagerError: Error {
    case fileAlreadyExists
    case invalidDirectory
    case writingFailed
    case fileNotExist
    case readingFailed
    case creatingFileFailed
    case creatingLogsDirectoryFailed
}
