//
//  PlatformSupport.swift
//  WelcomeKit
//
//  The parts that differ between OS versions and platforms, kept in one place
//  so the views above stay readable.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Adaptive colour

extension Color {
    /// A colour that resolves per appearance. `Color(light:dark:)` has no
    /// SwiftUI equivalent before iOS 26, so it goes through UIKit / AppKit.
    static func welcomeAdaptive(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        return Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
        })
        #else
        return light
        #endif
    }

    /// `#F2F2F6` / `#1C1C1E` — the grey Apple's own welcome sheets sit on.
    static let welcomeDefaultBackground = Color.welcomeAdaptive(
        light: Color(red: 242 / 255, green: 242 / 255, blue: 246 / 255),
        dark: Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    )
}

// MARK: - Wide layout tracking

enum WelcomeLayout {
    /// True only on an iPad-sized surface. The idiom check keeps an iPhone in
    /// landscape — and an iPad in Slide Over — on the compact metrics, which is
    /// where they belong.
    @MainActor
    static func isWide(width: CGFloat, threshold: CGFloat) -> Bool {
        #if os(iOS)
        guard UIDevice.current.userInterfaceIdiom == .pad else { return false }
        return width >= threshold
        #elseif os(visionOS)
        return width >= threshold
        #else
        return false
        #endif
    }
}

extension View {
    /// Measures the root and reports whether it is wide enough for the iPad
    /// metrics. Measure the container, never the control: a button that caps
    /// its own width changes the measurement that produced the cap.
    @ViewBuilder
    func welcomeTracksWideLayout(_ isWide: Binding<Bool>, threshold: CGFloat) -> some View {
        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                let newValue = WelcomeLayout.isWide(width: width, threshold: threshold)
                if isWide.wrappedValue != newValue {
                    isWide.wrappedValue = newValue
                }
            }
        } else {
            modifier(LegacyWideLayoutTracker(isWide: isWide, threshold: threshold))
        }
    }

    /// Caps a full-bleed control on wide layouts and keeps it centred in the
    /// space it gives up. The inner frame sizes, the outer one centres; on a
    /// phone both collapse to "fill" and nothing changes.
    func welcomeAdaptiveActionWidth(isWide: Bool, maxWidth: CGFloat) -> some View {
        frame(maxWidth: isWide ? maxWidth : .infinity)
            .frame(maxWidth: .infinity)
    }
}

private struct WelcomeWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// `onGeometryChange` is iOS 18. Below that, a background reader posts the
/// width through a preference instead.
private struct LegacyWideLayoutTracker: ViewModifier {
    @Binding var isWide: Bool
    let threshold: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(key: WelcomeWidthPreferenceKey.self, value: proxy.size.width)
                }
            }
            .onPreferenceChange(WelcomeWidthPreferenceKey.self) { width in
                Task { @MainActor in
                    let newValue = WelcomeLayout.isWide(width: width, threshold: threshold)
                    if isWide != newValue {
                        isWide = newValue
                    }
                }
            }
    }
}

// MARK: - OS 26 chrome

extension View {
    /// A bottom bar that the content scrolls under. `safeAreaBar` brings the
    /// progressive blur with it on OS 26; below that a gradient stands in so
    /// text never collides with the button.
    @ViewBuilder
    func welcomeBottomBar<Bar: View>(
        fadeColor: Color?,
        @ViewBuilder bar: () -> Bar
    ) -> some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            safeAreaBar(edge: .bottom, alignment: .center, spacing: 0) {
                bar()
            }
        } else {
            safeAreaInset(edge: .bottom, spacing: 0) {
                bar().background {
                    if let fadeColor {
                        LinearGradient(
                            colors: [fadeColor.opacity(0), fadeColor, fadeColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    }
                }
            }
        }
    }

    /// Liquid Glass where it exists, untouched everywhere else.
    @ViewBuilder
    func welcomeGlassEffect(_ isEnabled: Bool) -> some View {
        if isEnabled, #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            glassEffect(.regular.interactive())
        } else {
            self
        }
    }

    /// `buttonSizing(.flexible)` on OS 26, a flexible label frame below it.
    @ViewBuilder
    func welcomeFlexibleButtonSizing() -> some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            buttonSizing(.flexible)
        } else {
            self
        }
    }

    /// The other half of the pair: before `buttonSizing` existed, a button only
    /// went full-bleed if its label did.
    @ViewBuilder
    func welcomeFlexibleLabelWidth() -> some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            self
        } else {
            frame(maxWidth: .infinity)
        }
    }
}
