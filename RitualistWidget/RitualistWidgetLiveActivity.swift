//
//  RitualistWidgetLiveActivity.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RitualistWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RitualistWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RitualistWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension RitualistWidgetAttributes {
    fileprivate static var preview: RitualistWidgetAttributes {
        RitualistWidgetAttributes(name: "World")
    }
}

extension RitualistWidgetAttributes.ContentState {
    fileprivate static var smiley: RitualistWidgetAttributes.ContentState {
        RitualistWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RitualistWidgetAttributes.ContentState {
         RitualistWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RitualistWidgetAttributes.preview) {
   RitualistWidgetLiveActivity()
} contentStates: {
    RitualistWidgetAttributes.ContentState.smiley
    RitualistWidgetAttributes.ContentState.starEyes
}
