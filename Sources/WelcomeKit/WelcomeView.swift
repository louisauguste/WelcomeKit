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
///     title: "Welcome to Ova",
///     features: [
///         WelcomeFeature("Private", subtitle: "Runs on device.", systemImage: "lock.fill"),
///         WelcomeFeature("Fast", subtitle: "No round trip.", systemImage: "bolt.fill")
///     ]
/// ) {
///     // the user tapped Continue
/// }
/// ```
///
/// Use it directly when you present it yourself, or reach for
/// ``SwiftUICore/View/welcomeSheet(isPresented:title:features:configuration:onContinue:onSecondaryAction:)``
/// and its first-launch sibling to skip the plumbing.
public struct WelcomeView: View {

    private let title: WelcomeText
    private let features: [WelcomeFeature]
    private let configuration: WelcomeConfiguration
    private let onContinue: () -> Void
    private let onSecondaryAction: (() -> Void)?

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
    ///   - title: The headline. A string literal is looked up in your app's
    ///     string catalog; use `.verbatim("…")` to opt out.
    ///   - features: The rows, in the order they should arrive.
    ///   - configuration: Colour, motion, copy and metrics. See
    ///     ``WelcomeConfiguration``.
    ///   - onContinue: Called once when the primary button is tapped.
    ///   - onSecondaryAction: Called when the optional secondary button is
    ///     tapped. The button only shows when both this and
    ///     ``WelcomeConfiguration/secondaryTitle`` are set.
    public init(
        title: WelcomeText,
        features: [WelcomeFeature],
        configuration: WelcomeConfiguration = .default,
        onContinue: @escaping () -> Void,
        onSecondaryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.features = features
        self.configuration = configuration
        self.onContinue = onContinue
        self.onSecondaryAction = onSecondaryAction

        // With the reveal switched off the screen is complete from the first
        // frame, rather than appearing empty until `onAppear` runs. That also
        // makes the view render correctly outside a live hierarchy — in an
        // `ImageRenderer`, say.
        let isStatic = !configuration.animation.isEnabled
        _isTitleVisible = State(initialValue: isStatic)
        _visibleFeatureCount = State(initialValue: isStatic ? features.count : 0)
        _isActionVisible = State(initialValue: isStatic)
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
        title.text(bundle: configuration.localizationBundle, tableName: configuration.localizationTable)
            .font(resolvedTitleFont)
            .foregroundStyle(.primary)
            .multilineTextAlignment(configuration.titleAlignment)
            .lineLimit(configuration.titleLineLimit)
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

            if let secondaryTitle = configuration.secondaryTitle, let onSecondaryAction {
                Button {
                    onSecondaryAction()
                } label: {
                    secondaryTitle
                        .text(bundle: configuration.localizationBundle, tableName: configuration.localizationTable)
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(resolvedAccentColor ?? .accentColor)
            }

            if let footnote = configuration.footnote {
                footnote
                    .text(bundle: configuration.localizationBundle, tableName: configuration.localizationTable)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .welcomeAdaptiveActionWidth(isWide: isWideLayout, maxWidth: metrics.actionMaxWidth)
        .padding(.horizontal, horizontalInset)
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
            .font(.headline)
            .welcomeFlexibleLabelWidth()
    }

    // MARK: - Resolved values

    private var metrics: WelcomeMetrics { configuration.metrics }

    private var displayedFeatures: [WelcomeFeature] {
        guard let limit = configuration.maximumFeatureCount, limit < features.count else { return features }
        return Array(features.prefix(max(0, limit)))
    }

    private var resolvedAccentColor: Color? { configuration.accentColor }

    private var horizontalInset: CGFloat {
        isWideLayout ? metrics.wideHorizontalPadding : metrics.compactHorizontalPadding
    }

    /// A phone takes its bottom gap from the home indicator; every other
    /// surface has to be told.
    private var actionBottomPadding: CGFloat {
        #if os(macOS)
        metrics.bottomBarVerticalPadding + metrics.extraBottomPadding
        #else
        metrics.bottomBarVerticalPadding + (isWideLayout ? metrics.extraBottomPadding : 0)
        #endif
    }

    private var titleFrameAlignment: Alignment {
        switch configuration.titleAlignment {
        case .center: .center
        case .trailing: .trailing
        case .leading: .leading
        }
    }

    private var resolvedTitleFont: Font {
        if let font = configuration.titleFont { return font }
        #if os(macOS)
        return .system(size: 26, weight: .bold)
        #else
        return .title.weight(.bold)
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
        return 24
        #else
        return 28
        #endif
    }

    private var resolvedTitleFont: Font {
        if let font = configuration.featureTitleFont { return font }
        #if os(macOS)
        return .system(size: 15, weight: .semibold)
        #else
        return .body.weight(.semibold)
        #endif
    }

    private var resolvedSubtitleFont: Font {
        if let font = configuration.featureSubtitleFont { return font }
        #if os(macOS)
        return .system(size: 14)
        #else
        return .body
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
