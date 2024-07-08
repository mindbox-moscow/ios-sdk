//
//  DIManager.swift
//  Mindbox
//
//  Created by Mikhail Barilov on 13.01.2021.
//  Copyright © 2021 Mindbox. All rights reserved.
//

import CoreData
import Foundation
import UIKit

final class DependencyProvider: DependencyContainer {
    let utilitiesFetcher: UtilitiesFetcher
    let databaseRepository: MBDatabaseRepository
    let guaranteedDeliveryManager: GuaranteedDeliveryManager
    let sessionManager: SessionManager
    let instanceFactory: InstanceFactory
    let inAppMessagesManager: InAppCoreManagerProtocol
    var inappMessageEventSender: InappMessageEventSender
    var inappFilterService: InappFilterProtocol

    init() throws {
        utilitiesFetcher = MBUtilitiesFetcher()
        
        let persistenceStorage = DI.injectOrFail(PersistenceStorage.self)
        persistenceStorage.migrateShownInAppsIds()
        let inAppTargetingChecker = DI.injectOrFail(InAppTargetingCheckerProtocol.self)
        databaseRepository = DI.injectOrFail(MBDatabaseRepository.self)
        instanceFactory = MBInstanceFactory(
            persistenceStorage: persistenceStorage,
            utilitiesFetcher: utilitiesFetcher,
            databaseRepository: databaseRepository
        )
        guaranteedDeliveryManager = GuaranteedDeliveryManager(
            persistenceStorage: persistenceStorage,
            databaseRepository: databaseRepository,
            eventRepository: instanceFactory.makeEventRepository()
        )
        sessionManager = MBSessionManager(trackVisitManager: instanceFactory.makeTrackVisitManager())
        let logsManager = SDKLogsManager(persistenceStorage: persistenceStorage, eventRepository: instanceFactory.makeEventRepository())
        
        inappFilterService = InappsFilterService(persistenceStorage: persistenceStorage,
                                                 variantsFilter: DI.injectOrFail(VariantFilterProtocol.self),
                                                 sdkVersionValidator: DI.injectOrFail(SDKVersionValidator.self))
        
        inAppMessagesManager = InAppCoreManager(
            configManager: InAppConfigurationManager(
                inAppConfigAPI: InAppConfigurationAPI(persistenceStorage: persistenceStorage),
                inAppConfigRepository: InAppConfigurationRepository(),
                inAppConfigurationMapper: InAppConfigutationMapper(inappFilterService: inappFilterService,
                                                                   targetingChecker: inAppTargetingChecker,
                                                                   dataFacade: DI.injectOrFail(InAppConfigurationDataFacadeProtocol.self)),
                logsManager: logsManager,
            persistenceStorage: persistenceStorage),
            presentationManager: DI.injectOrFail(InAppPresentationManagerProtocol.self),
            persistenceStorage: persistenceStorage
        )
        inappMessageEventSender = InappMessageEventSender(inAppMessagesManager: inAppMessagesManager)        
    }
}

class MBInstanceFactory: InstanceFactory {
    private let persistenceStorage: PersistenceStorage
    private let utilitiesFetcher: UtilitiesFetcher
    private let databaseRepository: MBDatabaseRepository

    init(
        persistenceStorage: PersistenceStorage,
        utilitiesFetcher: UtilitiesFetcher,
        databaseRepository: MBDatabaseRepository
    ) {
        self.persistenceStorage = persistenceStorage
        self.utilitiesFetcher = utilitiesFetcher
        self.databaseRepository = databaseRepository
    }

    func makeNetworkFetcher() -> NetworkFetcher {
        return MBNetworkFetcher(
            utilitiesFetcher: utilitiesFetcher,
            persistenceStorage: persistenceStorage
        )
    }

    func makeEventRepository() -> EventRepository {
        return MBEventRepository(
            fetcher: makeNetworkFetcher(),
            persistenceStorage: persistenceStorage
        )
    }

    func makeTrackVisitManager() -> TrackVisitManager {
        return TrackVisitManager(databaseRepository: databaseRepository)
    }
}
