//
//  DemoFeatures.swift
//  WelcomeKitDemo
//

import SwiftUI
import WelcomeKit

enum DemoFeatures {
    static let all: [WelcomeFeature] = [
        WelcomeFeature(
            id: "drop-in",
            "Drop it in",
            subtitle: "One modifier, and your first run has a welcome screen.",
            systemImage: "shippingbox.fill"
        ),
        WelcomeFeature(
            id: "yours",
            "Make it yours",
            subtitle: "Tint, symbols, motion and copy are all yours to set.",
            systemImage: "paintbrush.pointed.fill"
        ),
        WelcomeFeature(
            id: "platforms",
            "iPhone, iPad, Mac",
            subtitle: "One layout that knows which room it is standing in.",
            systemImage: "macbook.and.iphone"
        ),
        WelcomeFeature(
            id: "again",
            "Once, then on demand",
            subtitle: "Shown on first launch, and again from Settings.",
            systemImage: "arrow.trianglehead.counterclockwise"
        ),
        WelcomeFeature(
            id: "accessible",
            "Reads well out loud",
            subtitle: "VoiceOver, Dynamic Type and Reduce Motion, handled.",
            systemImage: "accessibility"
        ),
        WelcomeFeature(
            id: "swift",
            "Swift 6, no dependencies",
            subtitle: "Strict concurrency on, third-party code out.",
            systemImage: "swift"
        )
    ]
}
