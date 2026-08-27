//
//  WelcomeKitTests.swift
//  WelcomeKit
//

import Foundation
import SwiftUI
import Testing
@testable import WelcomeKit

@Suite("Configuration")
struct ConfigurationTests {

    @Test("Default configuration animates and vibrates")
    func defaults() {
        let configuration = WelcomeConfiguration.default
        #expect(configuration.animation.isEnabled)
        #expect(configuration.animation.style == .blur)
        #expect(configuration.isHapticsEnabled)
        #expect(configuration.symbolRenderingMode == .monochrome)
    }

    @Test("The plain preset holds still")
    func plain() {
        #expect(WelcomeConfiguration.plain.animation.isEnabled == false)
        #expect(WelcomeConfiguration.plain.isHapticsEnabled == false)
    }

    @Test("Disabling the reveal is the same as the none style")
    func disabledAnimation() {
        #expect(WelcomeAnimation.disabled.style == .none)
        #expect(WelcomeAnimation.disabled.isEnabled == false)
    }

    @Test("Speed never reaches zero, which would stall the timeline")
    func speedFloor() {
        #expect(WelcomeAnimation(speed: 0).speed > 0)
        #expect(WelcomeAnimation(speed: -4).speed > 0)
        #expect(WelcomeAnimation.speed(2).speed == 2)
    }
}

@Suite("Layout")
@MainActor
struct LayoutTests {

    @Test("A phone-width surface keeps the compact metrics")
    func compactWidth() {
        #expect(WelcomeLayout.isWide(width: 393, threshold: 500) == false)
    }

    #if os(macOS)
    @Test("macOS never takes the iPad metrics")
    func macIsNeverWide() {
        #expect(WelcomeLayout.isWide(width: 1200, threshold: 500) == false)
    }
    #endif

    @Test("macOS metrics tighten the top padding and the symbol gutter")
    func platformMetrics() {
        let metrics = WelcomeMetrics.automatic
        #if os(macOS)
        #expect(metrics.compactTopPadding == 32)
        #expect(metrics.symbolColumnWidth == 38)
        #expect(metrics.actionLabelPadding == 5)
        #else
        #expect(metrics.compactTopPadding == 84)
        #expect(metrics.symbolColumnWidth == 42)
        #expect(metrics.actionLabelPadding == 0)
        #endif
    }
}

@Suite("Features")
struct FeatureTests {

    @Test("Rows get distinct identities by default")
    func generatedIdentifiers() {
        let first = WelcomeFeature("Same", systemImage: "star")
        let second = WelcomeFeature("Same", systemImage: "star")
        #expect(first.id != second.id)
    }

    @Test("An explicit identifier is kept")
    func explicitIdentifier() {
        #expect(WelcomeFeature(id: "privacy", "Private", systemImage: "lock").id == "privacy")
        #expect(WelcomeFeature.verbatim("Ova", systemImage: "star").id == "Ova")
    }

    @Test("Verbatim rows are not looked up in a string catalog")
    func verbatimText() {
        let feature = WelcomeFeature.verbatim("Ova", subtitle: "v2", systemImage: "star")
        guard case .verbatim(let title) = feature.title else {
            Issue.record("Expected verbatim copy")
            return
        }
        #expect(title == "Ova")
    }

    @Test("Every SF Symbols rendering mode is offered")
    func renderingModes() {
        #expect(
            WelcomeSymbolRenderingMode.allCases.map(\.rawValue)
            == ["monochrome", "hierarchical", "palette", "multicolor"]
        )
    }

    @Test("A row can override the global tint and rendering mode")
    func perRowOverrides() {
        let feature = WelcomeFeature(
            "Private",
            systemImage: "lock.fill",
            tint: .pink,
            symbolRenderingMode: .palette,
            symbolPalette: [.pink, .purple]
        )
        #expect(feature.tint == .pink)
        #expect(feature.symbolRenderingMode == .palette)
        #expect(feature.symbolPalette?.count == 2)
    }
}

@Suite("Store", .serialized)
struct StoreTests {

    private func makeStore(_ name: String = UUID().uuidString) -> UserDefaults {
        UserDefaults(suiteName: name)!
    }

    @Test("A fresh install has not seen the welcome screen")
    func unseenByDefault() {
        #expect(WelcomeStore.hasSeenWelcome(id: "test", in: makeStore()) == false)
    }

    @Test("Marking as seen sticks, and resetting arms it again")
    func roundTrip() {
        let store = makeStore()
        WelcomeStore.markAsSeen(id: "test", in: store)
        #expect(WelcomeStore.hasSeenWelcome(id: "test", in: store))

        WelcomeStore.reset(id: "test", in: store)
        #expect(WelcomeStore.hasSeenWelcome(id: "test", in: store) == false)
    }

    @Test("Two identifiers do not share a flag")
    func independentIdentifiers() {
        let store = makeStore()
        WelcomeStore.markAsSeen(id: "welcome", in: store)
        #expect(WelcomeStore.hasSeenWelcome(id: "whats-new-2.0", in: store) == false)
    }

    @Test("The key is stable enough to seed from a UI test")
    func keyFormat() {
        #expect(WelcomeStore.key(for: "welcome") == "WelcomeKit.hasSeen.welcome")
    }
}
