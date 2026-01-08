//
//  RitualistWidgetBundle.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import WidgetKit
import SwiftUI
import Factory
import RitualistCore

@main
struct RitualistWidgetBundle: WidgetBundle {

    init() {
        // Initialize widget-specific dependency injection
        Container.shared.reset()
        let logger = Container.shared.widgetLogger()
        logger.log("Widget bundle initialized", level: .info, category: .widget)
    }

    var body: some Widget {
        RitualistWidget()
        RitualistWidgetControl()
        RitualistWidgetLiveActivity()
    }
}
