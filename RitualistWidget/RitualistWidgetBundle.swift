//
//  RitualistWidgetBundle.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import WidgetKit
import SwiftUI
import Factory

@main
struct RitualistWidgetBundle: WidgetBundle {
    
    init() {
        // Initialize widget-specific dependency injection
        Container.shared.reset()
        print("[WIDGET-DI] WidgetContainer initialized for widget bundle")
    }
    
    var body: some Widget {
        RitualistWidget()
        RitualistWidgetControl()
        RitualistWidgetLiveActivity()
    }
}
