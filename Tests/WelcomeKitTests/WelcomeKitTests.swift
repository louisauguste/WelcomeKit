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

    @Test("Every cut of San Francisco is offered, SF Pro by default")
    func fontDesigns() {
        #expect(WelcomeConfiguration.default.fontDesign == .default)
        #expect(
            WelcomeFontDesign.allCases.map(\.rawValue)
            == ["default", "rounded", "serif", "monospaced"]
        )
    }
}

@Suite("Headline")
struct HeadlineTests {

    @Test("A string literal is a plain, single-colour headline")
    func stringLiteral() {
        let headline: WelcomeHeadline = "Welcome to Ova"
        guard case .plain = headline else {
            Issue.record("Expected a plain headline")
            return
        }
    }

    @Test("The update headline leads with Apple's wording")
    func whatsNew() {
        guard case .twoTone(let lead, let name) = WelcomeHeadline.whatsNew(in: "Ova"),
              case .localized(let leadKey) = lead,
              case .localized(let nameKey) = name else {
            Issue.record("Expected a two-tone headline built from localized keys")
            return
        }
        #expect(leadKey == LocalizedStringKey("What\u{2019}s new in"))
        #expect(nameKey == LocalizedStringKey("Ova"))
    }

    @Test("The first-run headline leads with Welcome to")
    func welcomeTo() {
        guard case .twoTone(let lead, _) = WelcomeHeadline.welcome(to: "Ova"),
              case .localized(let leadKey) = lead else {
            Issue.record("Expected a two-tone headline")
            return
        }
        #expect(leadKey == LocalizedStringKey("Welcome to"))
    }

    @Test("The lead line costs a line on top of the configured limit")
    func lineLimits() {
        let plain = WelcomeHeadline.plain("Welcome to Ova")
        let twoTone = WelcomeHeadline.whatsNew(in: "Ova")
        #expect(plain.lineLimit(2) == 2)
        #expect(twoTone.lineLimit(2) == 3)
        #expect(twoTone.lineLimit(nil) == nil)
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
        #expect(metrics.compactTopPadding == 56)
        #expect(metrics.symbolColumnWidth == 41)
        #expect(metrics.actionLabelPadding == 5)
        #expect(metrics.actionMaxWidth == 300)
        #else
        #expect(metrics.compactTopPadding == 72)
        #expect(metrics.symbolColumnWidth == 42)
        #expect(metrics.actionLabelPadding == 1)
        #expect(metrics.actionMaxWidth == 320)
        #endif
    }

    @Test("The button's side margins and its bottom gap agree on a phone")
    func evenActionInset() {
        let metrics = WelcomeMetrics()
        // A notched phone contributes 34pt of home indicator under the bar. Add
        // the bar's own gap and it has to land on the side margins, or the
        // button sits closer to one edge than the other two.
        let homeIndicator: CGFloat = 34
        #expect(metrics.compactActionBottomPadding + homeIndicator == metrics.actionHorizontalPadding)
    }

    @Test("The button is inset a little further than the text above it")
    func actionOutdent() {
        let metrics = WelcomeMetrics()
        #expect(metrics.actionHorizontalPadding < metrics.compactHorizontalPadding)
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
