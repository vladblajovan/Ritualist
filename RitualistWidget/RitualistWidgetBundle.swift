//
//  RitualistWidgetBundle.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import WidgetKit
import SwiftUI

@main
struct RitualistWidgetBundle: WidgetBundle {
    var body: some Widget {
        RitualistWidget()
        RitualistWidgetControl()
        RitualistWidgetLiveActivity()
    }
}
