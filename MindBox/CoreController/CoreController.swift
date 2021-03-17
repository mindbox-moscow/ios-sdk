//
//  CoreController.swift
//  MindBox
//
//  Created by Mikhail Barilov on 13.01.2021.
//  Copyright © 2021 Mikhail Barilov. All rights reserved.
//

import Foundation
import UIKit

class CoreController {
    
    @Injected private var persistenceStorage: PersistenceStorage
    @Injected private var utilitiesFetcher: UtilitiesFetcher
    @Injected private var notificationStatusProvider: UNAuthorizationStatusProviding
    @Injected private var databaseRepository: MBDatabaseRepository
    @Injected private var guaranteedDeliveryManager: GuaranteedDeliveryManager
    
    func initialization(configuration: MBConfiguration) {
        persistenceStorage.configuration = configuration
        if !persistenceStorage.isInstalled {
            primaryInitialization(with: configuration)
        } else {
            repeatedInitialization()
        }
        guaranteedDeliveryManager.canScheduleOperations = true
    }
    
    private let infoUpdatedSemathore = DispatchSemaphore(value: 1)

    func apnsTokenDidUpdate(token: String) {
        infoUpdatedSemathore.wait()
        defer {
            infoUpdatedSemathore.signal()
        }
        let isNotificationsEnabled = notificationStatusProvider.isNotificationsEnabled()
        if persistenceStorage.isInstalled {
            infoUpdated(
                apnsToken: token,
                isNotificationsEnabled: isNotificationsEnabled
            )
        }
        persistenceStorage.apnsToken = token
        persistenceStorage.isNotificationsEnabled = isNotificationsEnabled
    }
    
    func checkNotificationStatus(granted: Bool? = nil) {
        infoUpdatedSemathore.wait()
        defer {
            infoUpdatedSemathore.signal()
        }
        let isNotificationsEnabled = granted ?? notificationStatusProvider.isNotificationsEnabled()
        guard persistenceStorage.isNotificationsEnabled != isNotificationsEnabled else {
            return
        }
        if persistenceStorage.isInstalled {
            infoUpdated(
                apnsToken: persistenceStorage.apnsToken,
                isNotificationsEnabled: isNotificationsEnabled
            )
        }
        persistenceStorage.isNotificationsEnabled = isNotificationsEnabled
    }
    
    // MARK: - Private
    private func primaryInitialization(with configutaion: MBConfiguration) {
        if let deviceUUID = configutaion.deviceUUID {
            installed(
                deviceUUID: deviceUUID,
                installationId: configutaion.installationId,
                subscribe: configutaion.subscribeCustomerIfCreated
            )
        } else {
            utilitiesFetcher.getDeviceUUID(completion: { [self] (deviceUUID) in
                installed(
                    deviceUUID: deviceUUID,
                    installationId: configutaion.installationId,
                    subscribe: configutaion.subscribeCustomerIfCreated
                )
            })
        }
    }
    
    private func repeatedInitialization() {
        guard let deviceUUID = persistenceStorage.deviceUUID else {
            Log("Unable to find deviceUUID in persistenceStorage")
                .inChanel(.system).withType(.error).make()
            return
        }
        persistenceStorage.configuration?.deviceUUID = deviceUUID
        checkNotificationStatus()
    }
    
    private func installed(deviceUUID: String, installationId: String?, subscribe: Bool) {
        persistenceStorage.deviceUUID = deviceUUID
        persistenceStorage.installationId = installationId
        let apnsToken = persistenceStorage.apnsToken
        let isNotificationsEnabled = notificationStatusProvider.isNotificationsEnabled()
        let installed = MobileApplicationInstalled(
            token: apnsToken,
            isNotificationsEnabled: isNotificationsEnabled,
            installationId: installationId,
            subscribe: subscribe
        )
        let body = BodyEncoder(encodable: installed).body
        let event = Event(
            type: .installed,
            body: body
        )
        do {
            try databaseRepository.create(event: event)
            persistenceStorage.isNotificationsEnabled = isNotificationsEnabled
            persistenceStorage.installationDate = Date()
            Log("MobileApplicationInstalled")
                .inChanel(.system).withType(.verbose).make()
        } catch {
            Log("MobileApplicationInstalled failed with error: \(error.localizedDescription)")
                .inChanel(.system).withType(.error).make()
        }
        
    }
    
    private func infoUpdated(apnsToken: String?, isNotificationsEnabled: Bool) {
        let infoUpdated = MobileApplicationInfoUpdated(
            token: apnsToken,
            isNotificationsEnabled: isNotificationsEnabled
        )
        let event = Event(
            type: .infoUpdated,
            body: BodyEncoder(encodable: infoUpdated).body
        )
        do {
            try databaseRepository.create(event: event)
            Log("MobileApplicationInfoUpdated")
                .inChanel(.system).withType(.verbose).make()
        } catch {
            Log("MobileApplicationInfoUpdated failed with error: \(error.localizedDescription)")
                .inChanel(.system).withType(.error).make()
        }
    }
    
}
