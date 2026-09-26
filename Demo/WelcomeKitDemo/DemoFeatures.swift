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
        ),
        WelcomeFeature(
            id: "localized",
            "Speaks your language",
            subtitle: "Every string goes through your own string catalog.",
            systemImage: "character.bubble.fill"
        ),
        WelcomeFeature(
            id: "scrolls",
            "Room for more",
            subtitle: "A long list scrolls under the button, never behind it.",
            systemImage: "list.bullet.rectangle.portrait.fill"
        ),
        WelcomeFeature(
            id: "haptics",
            "Felt, not just seen",
            subtitle: "Each row lands with a tap you can feel.",
            systemImage: "hand.tap.fill"
        )
    ]
}
