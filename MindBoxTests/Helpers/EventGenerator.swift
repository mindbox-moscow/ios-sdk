//
//  EventGenerator.swift
//  MindBoxTests
//
//  Created by Maksim Kazachkov on 08.02.2021.
//  Copyright © 2021 Mikhail Barilov. All rights reserved.
//

import Foundation
@testable import MindBox

struct EventGenerator {

    let utility = MockUtility()
    
    func generateEvent() -> Event {
        Event(
            type: .installed,
            body: utility.randomString()
        )
    }
        
    func generateEvents(count: Int) -> [Event] {
        return (1...count).map { _ in
            return Event(
                type: .installed,
                body: utility.randomString()
            )
        }
    }

}
