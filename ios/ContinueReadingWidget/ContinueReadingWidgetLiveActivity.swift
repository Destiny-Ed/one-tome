//
//  ContinueReadingWidgetLiveActivity.swift
//  ContinueReadingWidget
//
//  Created by Destiny Ed on 06/11/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ContinueReadingWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ContinueReadingWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ContinueReadingWidgetAttributes.self) { context in
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

extension ContinueReadingWidgetAttributes {
    fileprivate static var preview: ContinueReadingWidgetAttributes {
        ContinueReadingWidgetAttributes(name: "World")
    }
}

extension ContinueReadingWidgetAttributes.ContentState {
    fileprivate static var smiley: ContinueReadingWidgetAttributes.ContentState {
        ContinueReadingWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ContinueReadingWidgetAttributes.ContentState {
         ContinueReadingWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ContinueReadingWidgetAttributes.preview) {
   ContinueReadingWidgetLiveActivity()
} contentStates: {
    ContinueReadingWidgetAttributes.ContentState.smiley
    ContinueReadingWidgetAttributes.ContentState.starEyes
}
