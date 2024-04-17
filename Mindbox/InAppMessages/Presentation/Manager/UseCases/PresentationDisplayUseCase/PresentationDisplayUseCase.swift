//
//  PresentationDisplayUseCase.swift
//  Mindbox
//
//  Created by vailence on 18.07.2023.
//  Copyright © 2023 Mindbox. All rights reserved.
//

import UIKit
import MindboxLogger

final class PresentationDisplayUseCase {

    private var presentationStrategy: PresentationStrategyProtocol?
    private var presentedVC: UIViewController?
    private var model: InAppFormData?
    private var factory: ViewFactoryProtocol?
    private var tracker: InAppMessagesTrackerProtocol

    init(tracker: InAppMessagesTrackerProtocol) {
        self.tracker = tracker
    }

    func presentInAppUIModel(model: InAppFormData, onPresented: @escaping () -> Void, onTapAction: @escaping (ContentBackgroundLayerAction?) -> Void, onClose: @escaping () -> Void) {
        
        changeType(model: model.content)
        
        guard let window = presentationStrategy?.getWindow() else {
            Logger.common(message: "In-app window creating failed")
            return
        }
        
        Logger.common(message: "PresentationDisplayUseCase window: \(window)")
        
        guard let factory = self.factory else {
            Logger.common(message: "Factory does not exists.", level: .error, category: .general)
            return
        }
        
        guard let viewController = factory.create(model: model.content,
                                                  id: model.inAppId,
                                                  imagesDict: model.imagesDict,
                                                  firstImageValue: model.firstImageValue,
                                                  onPresented: onPresented,
                                                  onTapAction: onTapAction,
                                                  onClose: onClose) else {
            return
        }
        
        presentedVC = viewController
        
        if let image = model.imagesDict[model.firstImageValue] {
            presentationStrategy?.setupWindowFrame(model: model.content, imageSize: image.size)
        }
        
        presentationStrategy?.present(id: model.inAppId, in: window, using: viewController)
    }
    
    func presentInAppUIModelWithObserver(model: InAppFormData, onPresented: @escaping () -> Void, onTapAction: @escaping (ContentBackgroundLayerAction?) -> Void, onClose: @escaping () -> Void) {
        switch UIApplication.shared.applicationState {
        case .active:
            presentInAppUIModel(model: model,
                                onPresented: onPresented,
                                onTapAction: onTapAction,
                                onClose: onClose)
        case .inactive:
            var observer: NSObjectProtocol?
            observer = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
                self.presentInAppUIModel(model: model,
                                         onPresented: onPresented,
                                         onTapAction: onTapAction,
                                         onClose: onClose)
                if let observer = observer {
                    NotificationCenter.default.removeObserver(observer)
                }
                observer = nil
            }
        case .background:
            return
        @unknown default:
            return
        }
    }

    func dismissInAppUIModel(onClose: @escaping () -> Void) {
        guard let presentedVC = presentedVC else {
            return
        }
        presentationStrategy?.dismiss(viewController: presentedVC)
        onClose()
        self.presentedVC = nil
        self.model = nil
        self.presentationStrategy = nil
        self.factory = nil
    }
    
    func onPresented(id: String, _ completion: @escaping () -> Void) {
        do {
            try tracker.trackView(id: id)
            Logger.common(message: "Track InApp.View. Id \(id)", level: .info, category: .notification)
        } catch {
            Logger.common(message: "Track InApp.View failed with error: \(error)", level: .error, category: .notification)
        }
        completion()
    }
    
    private func changeType(model: MindboxFormVariant) {
        switch model {
            case .modal:
                self.presentationStrategy = ModalPresentationStrategy()
                self.factory = ModalViewFactory()
            case .snackbar:
                self.presentationStrategy = SnackbarPresentationStrategy()
                self.factory = SnackbarViewFactory()
            default:
                break
        }
    }
}
