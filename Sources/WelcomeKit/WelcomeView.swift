//
//  WelcomeView.swift
//  WelcomeKit
//

import SwiftUI

/// A single-screen welcome, laid out like Apple's own "Welcome to…" sheets:
/// a big left-aligned title, a list of icon + title + subtitle rows, and a
/// full-bleed call to action pinned to the bottom.
///
/// ```swift
/// WelcomeView(
///     headline: "Welcome to Ova",
///     features: [
///         WelcomeFeature("Private", subtitle: "Runs on device.", systemImage: "lock.fill"),
///         WelcomeFeature("Fast", subtitle: "No round trip.", systemImage: "bolt.fill")
///     ]
/// ) {
///     // the user tapped Continue
/// }
/// ```
///
/// Pass ``WelcomeHeadline/whatsNew(in:)`` instead of a plain string to get
/// Apple's two-tone update headline — a tinted "What's New in" over the app's
/// own name.
///
/// Use it directly when you present it yourself, or reach for
/// ``SwiftUICore/View/welcomeSheet(isPresented:title:features:configuration:presentation:onContinue:)``
/// and its first-launch sibling to skip the plumbing.
public struct WelcomeView: View {

    private let headline: WelcomeHeadline
    private let features: [WelcomeFeature]
    private let configuration: WelcomeConfiguration
    private let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isWideLayout = false
    @State private var didStartTimeline = false
    @State private var timelineTask: Task<Void, Never>?
    @State private var isContinuing = false

    @State private var isTitleVisible: Bool
    @State private var visibleFeatureCount: Int
    @State private var isActionVisible: Bool

    @State private var mediumFeedback = 0
    @State private var softFeedback = 0
    @State private var successFeedback = 0

    /// Creates a welcome screen.
    ///
    /// - Parameters:
    ///   - headline: The big line at the top. A string literal is looked up in
    ///     your app's string catalog; ``WelcomeHeadline/whatsNew(in:)`` and
    ///     ``WelcomeHeadline/welcome(to:)`` give you the two-tone variant.
    ///   - features: The rows, in the order they should arrive.
    ///   - configuration: Colour, motion, copy and metrics. See
    ///     ``WelcomeConfiguration``.
    ///   - onContinue: Called once when the button is tapped.
    public init(
        headline: WelcomeHeadline,
        features: [WelcomeFeature],
        configuration: WelcomeConfiguration = .default,
        onContinue: @escaping () -> Void
    ) {
        self.headline = headline
        self.features = features
        self.configuration = configuration
        self.onContinue = onContinue

        // With the reveal switched off the screen is complete from the first
        // frame, rather than appearing empty until `onAppear` runs. That also
        // makes the view render correctly outside a live hierarchy — in an
        // `ImageRenderer`, say.
        let isStatic = !configuration.animation.isEnabled
        _isTitleVisible = State(initialValue: isStatic)
        _visibleFeatureCount = State(initialValue: isStatic ? features.count : 0)
        _isActionVisible = State(initialValue: isStatic)
    }

    /// Creates a welcome screen with a single-colour headline.
    ///
    /// - Parameters:
    ///   - title: The headline. A string literal is looked up in your app's
    ///     string catalog; use `.verbatim("…")` to opt out.
    ///   - features: The rows, in the order they should arrive.
    ///   - configuration: Colour, motion, copy and metrics. See
    ///     ``WelcomeConfiguration``.
    ///   - onContinue: Called once when the button is tapped.
    public init(
        title: WelcomeText,
        features: [WelcomeFeature],
        configuration: WelcomeConfiguration = .default,
        onContinue: @escaping () -> Void
    ) {
        self.init(
            headline: .plain(title),
            features: features,
            configuration: configuration,
            onContinue: onContinue
        )
    }

    public var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    titleView
                        .padding(.bottom, metrics.titleBottomPadding)

                    featureList
                }
                .frame(
                    maxWidth: isWideLayout ? metrics.featureListMaxWidth : .infinity,
                    alignment: .leading
                )
                .frame(maxWidth: .infinity, alignment: isWideLayout ? .center : .leading)
                .padding(.horizontal, horizontalInset)
                .padding(.top, isWideLayout ? metrics.wideTopPadding : metrics.compactTopPadding)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .welcomeBottomBar(fadeColor: backgroundFadeColor) {
            bottomBar
        }
        .welcomeTracksWideLayout($isWideLayout, threshold: metrics.wideWidthThreshold)
        .sensoryFeedback(trigger: mediumFeedback) { _, _ in
            configuration.isHapticsEnabled ? .impact(weight: .medium) : nil
        }
        .sensoryFeedback(trigger: softFeedback) { _, _ in
            configuration.isHapticsEnabled ? .impact(flexibility: .soft) : nil
        }
        .sensoryFeedback(trigger: successFeedback) { _, _ in
            configuration.isHapticsEnabled ? .success : nil
        }
        .onAppear(perform: startTimelineIfNeeded)
        .onDisappear {
            timelineTask?.cancel()
            timelineTask = nil
        }
    }

    // MARK: - Pieces

    @ViewBuilder
    private var background: some View {
        switch configuration.background {
        case .automatic:
            Color.welcomeDefaultBackground.ignoresSafeArea()
        case .color(let color):
            color.ignoresSafeArea()
        case .gradient(let colors):
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        case .clear:
            Color.clear
        }
    }

    private var titleView: some View {
        headline
            .text(
                bundle: configuration.localizationBundle,
                tableName: configuration.localizationTable,
                accent: headlineAccentStyle
            )
            .font(resolvedTitleFont)
            .foregroundStyle(.primary)
            .multilineTextAlignment(configuration.titleAlignment)
            .lineLimit(headline.lineLimit(configuration.titleLineLimit))
            .minimumScaleFactor(0.7)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: titleFrameAlignment)
            .accessibilityAddTraits(.isHeader)
            .welcomeReveal(style: revealStyle, isVisible: isTitleVisible, offset: 14, blur: 18)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: metrics.featureSpacing) {
            ForEach(Array(displayedFeatures.enumerated()), id: \.element.id) { index, feature in
                let isVisible = index < visibleFeatureCount

                WelcomeFeatureRow(feature: feature, configuration: configuration)
                    .welcomeReveal(style: revealStyle, isVisible: isVisible, offset: 18, blur: 14)
                    .accessibilityHidden(!isVisible)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            continueButton

            if let footnote = configuration.footnote {
                footnote
                    .text(bundle: configuration.localizationBundle, tableName: configuration.localizationTable)
                    .font(.system(.footnote, design: resolvedFontDesign))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .welcomeAdaptiveActionWidth(isWide: capsActionWidth, maxWidth: metrics.actionMaxWidth)
        .padding(.horizontal, metrics.actionHorizontalPadding)
        .padding(.top, metrics.bottomBarVerticalPadding)
        .padding(.bottom, actionBottomPadding)
        .welcomeReveal(style: revealStyle, isVisible: isActionVisible, offset: 16, blur: 10, scale: 0.94)
        .allowsHitTesting(isActionVisible && !isContinuing)
    }

    @ViewBuilder
    private var continueButton: some View {
        let label = continueLabel
        let action = {
            guard !isContinuing else { return }
            isContinuing = true
            mediumFeedback += 1
            onContinue()
        }

        switch configuration.buttonStyle {
        case .automatic:
            Button(action: action) { label }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .welcomeFlexibleButtonSizing()
                .welcomeGlassEffect(true)
                .tint(resolvedAccentColor)
        case .prominent:
            Button(action: action) { label }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .welcomeFlexibleButtonSizing()
                .tint(resolvedAccentColor)
        case .glass:
            Button(action: action) { label }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .welcomeFlexibleButtonSizing()
                .welcomeGlassEffect(true)
                .tint(resolvedAccentColor)
        case .bordered:
            Button(action: action) { label }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .welcomeFlexibleButtonSizing()
                .tint(resolvedAccentColor)
        }
    }

    private var continueLabel: some View {
        configuration.continueTitle
            .text(bundle: configuration.localizationBundle, tableName: configuration.localizationTable)
            .font(resolvedButtonFont)
            .padding(.vertical, metrics.actionLabelPadding)
            .welcomeFlexibleLabelWidth()
    }

    // MARK: - Resolved values

    private var metrics: WelcomeMetrics { configuration.metrics }

    private var displayedFeatures: [WelcomeFeature] {
        guard let limit = configuration.maximumFeatureCount, limit < features.count else { return features }
        return Array(features.prefix(max(0, limit)))
    }

    private var resolvedAccentColor: Color? { configuration.accentColor }

    /// A phone lets the button fill the width. Every wider surface caps it, a
    /// Mac window included: a 416pt slab reads as stretched next to the same
    /// layout on iPad.
    private var capsActionWidth: Bool {
        #if os(macOS)
        true
        #else
        isWideLayout
        #endif
    }

    private var horizontalInset: CGFloat {
        isWideLayout ? metrics.wideHorizontalPadding : metrics.compactHorizontalPadding
    }

    /// A phone takes its bottom gap from the home indicator; every other
    /// surface has to be told.
    private var actionBottomPadding: CGFloat {
        #if os(macOS)
        metrics.bottomBarVerticalPadding + metrics.extraBottomPadding
        #else
        isWideLayout
            ? metrics.bottomBarVerticalPadding + metrics.extraBottomPadding
            : metrics.compactActionBottomPadding
        #endif
    }

    private var titleFrameAlignment: Alignment {
        switch configuration.titleAlignment {
        case .center: .center
        case .trailing: .trailing
        case .leading: .leading
        }
    }

    private var resolvedFontDesign: Font.Design { configuration.fontDesign.fontDesign }

    /// The accent the two-tone headline's lead line is drawn in. With no accent
    /// configured it falls through to the surrounding tint, the same way the
    /// symbols and the button do.
    private var headlineAccentStyle: AnyShapeStyle {
        if let accent = configuration.accentColor { return AnyShapeStyle(accent) }
        return AnyShapeStyle(.tint)
    }

    private var resolvedTitleFont: Font {
        if let font = configuration.titleFont { return font }
        #if os(macOS)
        return .system(size: 26, weight: .bold, design: resolvedFontDesign)
        #else
        return .system(.title, design: resolvedFontDesign, weight: .bold)
        #endif
    }

    /// `.headline` is 17pt semibold on iOS and 13pt semibold on macOS, so the
    /// same font reads as a heavier, smaller label on a Mac. 15pt medium lands
    /// where the phone button already is.
    private var resolvedButtonFont: Font {
        if let font = configuration.buttonFont { return font }
        #if os(macOS)
        return .system(size: 15, weight: .medium, design: resolvedFontDesign)
        #else
        return .system(.headline, design: resolvedFontDesign)
        #endif
    }

    private var backgroundFadeColor: Color? {
        switch configuration.background {
        case .automatic: .welcomeDefaultBackground
        case .color(let color): color
        case .gradient(let colors): colors.last
        case .clear: nil
        }
    }

    /// Reduce Motion wins over the configuration, unless the app opts out.
    private var revealStyle: WelcomeRevealStyle {
        let animation = configuration.animation
        if animation.respectsReduceMotion && reduceMotion { return .none }
        return animation.style
    }

    // MARK: - Timeline

    private func startTimelineIfNeeded() {
        guard !didStartTimeline else { return }
        didStartTimeline = true

        guard revealStyle != .none else {
            isTitleVisible = true
            visibleFeatureCount = displayedFeatures.count
            isActionVisible = true
            return
        }

        timelineTask = Task { @MainActor in
            await runTimeline()
        }
    }

    @MainActor
    private func runTimeline() async {
        let animation = configuration.animation
        let speed = animation.speed

        await pause(animation.initialDelay, speed: speed)
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.34 / speed)) {
            isTitleVisible = true
        }

        await pause(0.06, speed: speed)
        guard !Task.isCancelled else { return }
        mediumFeedback += 1

        await pause(0.04, speed: speed)

        for index in displayedFeatures.indices {
            guard !Task.isCancelled else { return }

            withAnimation(.spring(response: 0.58 / speed, dampingFraction: 0.86)) {
                visibleFeatureCount = index + 1
            }

            await pause(animation.featureStagger / 2, speed: speed)
            guard !Task.isCancelled else { return }
            softFeedback += 1
            await pause(animation.featureStagger / 2, speed: speed)
        }

        await pause(animation.buttonDelay, speed: speed)
        guard !Task.isCancelled else { return }

        successFeedback += 1
        withAnimation(.spring(response: 0.56 / speed, dampingFraction: 0.84)) {
            isActionVisible = true
        }
    }

    private func pause(_ seconds: TimeInterval, speed: Double) async {
        let adjusted = max(0, seconds / speed)
        try? await Task.sleep(nanoseconds: UInt64(adjusted * 1_000_000_000))
    }
}

// MARK: - Row

/// One line of the welcome list: a large tinted glyph in its own gutter, then
/// the title and its explanation, both starting on the same edge.
private struct WelcomeFeatureRow: View {
    let feature: WelcomeFeature
    let configuration: WelcomeConfiguration

    var body: some View {
        HStack(alignment: .top, spacing: configuration.metrics.symbolSpacing) {
            symbol
                .frame(
                    width: configuration.metrics.symbolColumnWidth,
                    height: configuration.metrics.symbolColumnHeight,
                    alignment: .center
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                feature.title
                    .text(bundle: configuration.localizationBundle, tableName: configuration.localizationTable)
                    .font(resolvedTitleFont)
                    .foregroundStyle(.primary)

                if let subtitle = feature.subtitle {
                    subtitle
                        .text(bundle: configuration.localizationBundle, tableName: configuration.localizationTable)
                        .font(resolvedSubtitleFont)
                        .foregroundStyle(.secondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var symbol: some View {
        let image = Image(systemName: feature.systemImage)
            .font(.system(size: resolvedSymbolSize, weight: configuration.symbolWeight))
            .symbolRenderingMode(resolvedRenderingMode.symbolRenderingMode)

        switch resolvedRenderingMode {
        case .palette:
            image.foregroundStyle(
                paletteColor(0),
                paletteColor(1),
                paletteColor(2)
            )
        case .multicolor:
            image
        case .monochrome, .hierarchical:
            image.foregroundStyle(resolvedTint)
        }
    }

    private var resolvedRenderingMode: WelcomeSymbolRenderingMode {
        feature.symbolRenderingMode ?? configuration.symbolRenderingMode
    }

    private var resolvedTint: Color {
        feature.tint ?? configuration.accentColor ?? .accentColor
    }

    private var palette: [Color] {
        let palette = feature.symbolPalette ?? configuration.symbolPalette
        return palette.isEmpty ? [resolvedTint] : palette
    }

    /// SF Symbols repeats the last layer colour when a palette runs short,
    /// so short palettes stay legible instead of falling back to black.
    private func paletteColor(_ index: Int) -> Color {
        let colors = palette
        return colors[min(index, colors.count - 1)]
    }

    private var resolvedSymbolSize: CGFloat {
        if let size = configuration.symbolSize { return size }
        #if os(macOS)
        return 27
        #else
        return 28
        #endif
    }

    private var resolvedFontDesign: Font.Design { configuration.fontDesign.fontDesign }

    private var resolvedTitleFont: Font {
        if let font = configuration.featureTitleFont { return font }
        #if os(macOS)
        return .system(size: 15, weight: .semibold, design: resolvedFontDesign)
        #else
        return .system(.body, design: resolvedFontDesign, weight: .semibold)
        #endif
    }

    private var resolvedSubtitleFont: Font {
        if let font = configuration.featureSubtitleFont { return font }
        #if os(macOS)
        return .system(size: 14, design: resolvedFontDesign)
        #else
        return .system(.body, design: resolvedFontDesign)
        #endif
    }
}

// MARK: - Reveal

private extension View {
    /// The transform an element animates out of. One modifier for every style
    /// so the reveal stays a single value change.
    func welcomeReveal(
        style: WelcomeRevealStyle,
        isVisible: Bool,
        offset: CGFloat,
        blur: CGFloat,
        scale: CGFloat = 1
    ) -> some View {
        let hidden = !isVisible && style != .none

        return self
            .opacity(hidden ? 0 : 1)
            .blur(radius: hidden && style == .blur ? blur : 0)
            .offset(y: hidden && (style == .blur || style == .slide) ? offset : 0)
            .scaleEffect(hidden && style == .scale ? min(scale, 0.94) : 1)
    }
}
