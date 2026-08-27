//
//  WelcomeConfiguration.swift
//  WelcomeKit
//

import SwiftUI

/// Everything you can change about a ``WelcomeView`` without rewriting it.
///
/// Start from ``default`` and override what you need:
///
/// ```swift
/// var configuration = WelcomeConfiguration.default
/// configuration.accentColor = .pink
/// configuration.symbolRenderingMode = .hierarchical
/// configuration.animation = .speed(1.4)
/// ```
///
/// Or build one inline — every parameter has a default:
///
/// ```swift
/// WelcomeConfiguration(accentColor: .pink, symbolRenderingMode: .hierarchical)
/// ```
///
/// - Note: `@unchecked Sendable` because of the optional `Bundle` used for
///   localisation. `Bundle` is thread-safe and every other stored property is a
///   value type, so the struct is safe to hand across isolation domains.
public struct WelcomeConfiguration: @unchecked Sendable {

    // MARK: - Colour

    /// Tint for the SF Symbols and the continue button.
    ///
    /// `nil` inherits the tint of the surrounding view hierarchy, which is what
    /// you want when the app already sets a global `.tint(_:)`.
    public var accentColor: Color?

    /// How the SF Symbols are drawn. Individual rows can override this through
    /// ``WelcomeFeature/symbolRenderingMode``.
    public var symbolRenderingMode: WelcomeSymbolRenderingMode

    /// Layer colours used when the rendering mode is
    /// ``WelcomeSymbolRenderingMode/palette``. Up to three are read.
    public var symbolPalette: [Color]

    /// What sits behind the content.
    public var background: WelcomeBackground

    // MARK: - Symbols

    /// Point size of the SF Symbols. `nil` uses 28pt on iOS and 27pt on macOS.
    public var symbolSize: CGFloat?

    /// Stroke weight of the SF Symbols.
    public var symbolWeight: Font.Weight

    // MARK: - Type

    /// Font of the big title. `nil` uses `.title` bold on iOS, 26pt bold on macOS.
    public var titleFont: Font?

    /// Font of each feature's first line. `nil` uses `.body` semibold.
    public var featureTitleFont: Font?

    /// Font of each feature's second line. `nil` uses `.body`.
    public var featureSubtitleFont: Font?

    /// Font of the button's label. `nil` uses `.headline` on iOS and 15pt medium
    /// on macOS, where `.headline` comes out both smaller and heavier than the
    /// same button reads on a phone.
    public var buttonFont: Font?

    /// Alignment of the title. Feature rows always read from the leading edge.
    public var titleAlignment: TextAlignment

    /// Maximum number of lines for the title before it starts shrinking.
    public var titleLineLimit: Int?

    /// Small print under the continue button — a privacy note, a legal line.
    /// `nil` hides it.
    public var footnote: WelcomeText?

    // MARK: - Content

    /// Caps how many rows are shown, ignoring the rest. `nil` shows them all.
    ///
    /// Handy when the same feature list feeds several surfaces and the welcome
    /// screen should only show the top few.
    public var maximumFeatureCount: Int?

    // MARK: - Actions

    /// Label of the primary button.
    public var continueTitle: WelcomeText

    /// Look of the primary button.
    public var buttonStyle: WelcomeButtonStyle

    // MARK: - Motion

    /// The staggered reveal. Use ``WelcomeAnimation/disabled`` for an instant
    /// screen.
    public var animation: WelcomeAnimation

    /// Plays impact feedback as the rows land, and a success notification when
    /// the button arrives. iOS only; a no-op everywhere else.
    public var isHapticsEnabled: Bool

    // MARK: - Metrics

    /// Paddings, widths and the iPad breakpoint.
    public var metrics: WelcomeMetrics

    // MARK: - Localisation

    /// Bundle used to resolve localized keys. `nil` means `Bundle.main`, i.e.
    /// your app's own string catalog.
    public var localizationBundle: Bundle?

    /// Strings table used to resolve localized keys. `nil` means `Localizable`.
    public var localizationTable: String?

    // MARK: - Init

    public init(
        accentColor: Color? = nil,
        symbolRenderingMode: WelcomeSymbolRenderingMode = .monochrome,
        symbolPalette: [Color] = [],
        background: WelcomeBackground = .automatic,
        symbolSize: CGFloat? = nil,
        symbolWeight: Font.Weight = .regular,
        titleFont: Font? = nil,
        featureTitleFont: Font? = nil,
        featureSubtitleFont: Font? = nil,
        buttonFont: Font? = nil,
        titleAlignment: TextAlignment = .leading,
        titleLineLimit: Int? = 2,
        footnote: WelcomeText? = nil,
        maximumFeatureCount: Int? = nil,
        continueTitle: WelcomeText = .localized("Continue"),
        buttonStyle: WelcomeButtonStyle = .automatic,
        animation: WelcomeAnimation = .default,
        isHapticsEnabled: Bool = true,
        metrics: WelcomeMetrics = .automatic,
        localizationBundle: Bundle? = nil,
        localizationTable: String? = nil
    ) {
        self.accentColor = accentColor
        self.symbolRenderingMode = symbolRenderingMode
        self.symbolPalette = symbolPalette
        self.background = background
        self.symbolSize = symbolSize
        self.symbolWeight = symbolWeight
        self.titleFont = titleFont
        self.featureTitleFont = featureTitleFont
        self.featureSubtitleFont = featureSubtitleFont
        self.buttonFont = buttonFont
        self.titleAlignment = titleAlignment
        self.titleLineLimit = titleLineLimit
        self.footnote = footnote
        self.maximumFeatureCount = maximumFeatureCount
        self.continueTitle = continueTitle
        self.buttonStyle = buttonStyle
        self.animation = animation
        self.isHapticsEnabled = isHapticsEnabled
        self.metrics = metrics
        self.localizationBundle = localizationBundle
        self.localizationTable = localizationTable
    }

    /// The stock look: monochrome symbols, the blur reveal, haptics on.
    public static let `default` = WelcomeConfiguration()

    /// No animation, no haptics — for screenshots, tests, and people who would
    /// rather their app just appear.
    public static let plain = WelcomeConfiguration(animation: .disabled, isHapticsEnabled: false)
}

// MARK: - Background

/// What is painted behind the welcome content.
public enum WelcomeBackground: Sendable, Equatable {
    /// The grouped-background grey Apple uses on its own welcome sheets:
    /// `#F2F2F6` in light, `#1C1C1E` in dark.
    case automatic
    /// A flat colour.
    case color(Color)
    /// A vertical gradient, top to bottom.
    case gradient([Color])
    /// Nothing — whatever the sheet or window already shows comes through.
    case clear
}

// MARK: - Button style

/// The look of the primary call to action.
public enum WelcomeButtonStyle: String, Sendable, CaseIterable {
    /// Prominent, with Liquid Glass on iOS 26 / macOS 26 and later.
    case automatic
    /// Prominent and filled on every OS version, glass never applied.
    case prominent
    /// Glass on iOS 26 / macOS 26 and later, bordered below.
    case glass
    /// A bordered, non-filled button.
    case bordered
}

// MARK: - Animation

/// How the screen assembles itself: title first, then the rows one by one, then
/// the button.
public struct WelcomeAnimation: Sendable, Equatable {

    /// The transform each element animates out of.
    public var style: WelcomeRevealStyle

    /// Multiplies every duration and delay. `2` is twice as fast.
    public var speed: Double

    /// Beat before the title shows up.
    public var initialDelay: TimeInterval

    /// Gap between two consecutive feature rows.
    public var featureStagger: TimeInterval

    /// Beat between the last row and the button.
    public var buttonDelay: TimeInterval

    /// Skips straight to the finished screen when the system's Reduce Motion
    /// setting is on. Leave this on.
    public var respectsReduceMotion: Bool

    public init(
        style: WelcomeRevealStyle = .blur,
        speed: Double = 1,
        initialDelay: TimeInterval = 0.12,
        featureStagger: TimeInterval = 0.10,
        buttonDelay: TimeInterval = 0.10,
        respectsReduceMotion: Bool = true
    ) {
        self.style = style
        self.speed = max(speed, 0.01)
        self.initialDelay = initialDelay
        self.featureStagger = featureStagger
        self.buttonDelay = buttonDelay
        self.respectsReduceMotion = respectsReduceMotion
    }

    /// Whether anything animates at all.
    public var isEnabled: Bool { style != .none }

    /// The reference reveal, ported from a shipping app.
    public static let `default` = WelcomeAnimation()

    /// Everything on screen from the first frame.
    public static let disabled = WelcomeAnimation(style: .none)

    /// The default reveal, run faster or slower.
    public static func speed(_ speed: Double) -> WelcomeAnimation {
        WelcomeAnimation(speed: speed)
    }

    /// The default timings with a different transform.
    public static func style(_ style: WelcomeRevealStyle) -> WelcomeAnimation {
        WelcomeAnimation(style: style)
    }
}

/// The transform elements animate out of as they arrive.
public enum WelcomeRevealStyle: String, Sendable, CaseIterable {
    /// Blur, rise and fade together. The reference look.
    case blur
    /// Rise and fade, no blur — cheaper on older hardware.
    case slide
    /// Fade only.
    case fade
    /// Grow from 94% and fade.
    case scale
    /// No reveal; the screen is complete on the first frame.
    case none
}

// MARK: - Metrics

/// The numbers behind the layout. Every one of them is a point value you can
/// override, but the defaults are tuned against Apple's own welcome sheets.
public struct WelcomeMetrics: Sendable, Equatable {

    /// Past this width the layout switches to its iPad numbers. Only ever true
    /// on an actual iPad, so an iPhone in landscape keeps the phone metrics.
    public var wideWidthThreshold: CGFloat

    /// The primary button stops growing here on wide layouts, instead of
    /// stretching across a whole iPad sheet.
    public var actionMaxWidth: CGFloat

    /// The text column stops growing here on wide layouts.
    public var featureListMaxWidth: CGFloat

    /// Side margins on wide layouts.
    public var wideHorizontalPadding: CGFloat

    /// Side margins on compact layouts, and on macOS.
    public var compactHorizontalPadding: CGFloat

    /// Headroom above the title on compact layouts — enough to clear a notch.
    public var compactTopPadding: CGFloat

    /// Headroom above the title on wide layouts, where there is no notch.
    public var wideTopPadding: CGFloat

    /// Extra room under the button on surfaces with no home indicator.
    public var extraBottomPadding: CGFloat

    /// Vertical padding inside the bottom bar.
    public var bottomBarVerticalPadding: CGFloat

    /// Extra height inside the primary button, added around its label. iOS gets
    /// a tall enough button from `.controlSize(.large)` alone; a Mac one comes
    /// out thin next to the same layout on iPad.
    public var actionLabelPadding: CGFloat

    /// Gap between the title and the first row.
    public var titleBottomPadding: CGFloat

    /// Gap between two rows.
    public var featureSpacing: CGFloat

    /// Gap between a symbol and its text.
    public var symbolSpacing: CGFloat

    /// Width of the symbol gutter. Keeping it fixed is what lines every title
    /// up on the same vertical.
    public var symbolColumnWidth: CGFloat

    /// Height of the symbol gutter.
    public var symbolColumnHeight: CGFloat

    public init(
        wideWidthThreshold: CGFloat = 500,
        actionMaxWidth: CGFloat = 340,
        featureListMaxWidth: CGFloat = 520,
        wideHorizontalPadding: CGFloat = 44,
        compactHorizontalPadding: CGFloat = 42,
        compactTopPadding: CGFloat = 84,
        wideTopPadding: CGFloat = 64,
        extraBottomPadding: CGFloat = 34,
        bottomBarVerticalPadding: CGFloat = 8,
        actionLabelPadding: CGFloat = 0,
        titleBottomPadding: CGFloat = 28,
        featureSpacing: CGFloat = 20,
        symbolSpacing: CGFloat = 12,
        symbolColumnWidth: CGFloat = 42,
        symbolColumnHeight: CGFloat = 34
    ) {
        self.wideWidthThreshold = wideWidthThreshold
        self.actionMaxWidth = actionMaxWidth
        self.featureListMaxWidth = featureListMaxWidth
        self.wideHorizontalPadding = wideHorizontalPadding
        self.compactHorizontalPadding = compactHorizontalPadding
        self.compactTopPadding = compactTopPadding
        self.wideTopPadding = wideTopPadding
        self.extraBottomPadding = extraBottomPadding
        self.bottomBarVerticalPadding = bottomBarVerticalPadding
        self.actionLabelPadding = actionLabelPadding
        self.titleBottomPadding = titleBottomPadding
        self.featureSpacing = featureSpacing
        self.symbolSpacing = symbolSpacing
        self.symbolColumnWidth = symbolColumnWidth
        self.symbolColumnHeight = symbolColumnHeight
    }

    /// Platform defaults: the iOS numbers, or the tighter macOS ones inside a
    /// 500×580 sheet.
    public static var automatic: WelcomeMetrics {
        #if os(macOS)
        WelcomeMetrics(
            compactTopPadding: 32,
            extraBottomPadding: 46,
            actionLabelPadding: 5,
            symbolColumnWidth: 41,
            symbolColumnHeight: 33
        )
        #else
        WelcomeMetrics()
        #endif
    }
}
