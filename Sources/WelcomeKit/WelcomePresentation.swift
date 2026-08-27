//
//  WelcomePresentation.swift
//  WelcomeKit
//

import SwiftUI

// MARK: - Presentation options

/// How the welcome screen gets on screen.
public struct WelcomePresentation: Sendable, Equatable {

    /// The container used to present the screen.
    public enum Style: String, Sendable, CaseIterable {
        /// A sheet. On macOS it is sized by ``WelcomePresentation/macOSSize``.
        case sheet
        /// A cover with no visible way out other than the button. Falls back to
        /// a sheet on macOS, which has no such presentation.
        case fullScreenCover
    }

    public var style: Style

    /// Whether a swipe or a click outside can dismiss the screen.
    ///
    /// `false` — the default — is what a first run wants: the button is the
    /// only way forward. Set it to `true` when the screen is being shown again
    /// from Settings.
    public var isDismissible: Bool

    /// Size of the macOS sheet. macOS does not resize a sheet to its content,
    /// so the number has to come from somewhere.
    public var macOSSize: CGSize

    public init(
        style: Style = .sheet,
        isDismissible: Bool = false,
        macOSSize: CGSize = CGSize(width: 500, height: 580)
    ) {
        self.style = style
        self.isDismissible = isDismissible
        self.macOSSize = macOSSize
    }

    /// A sheet the user cannot dismiss by hand.
    public static let automatic = WelcomePresentation()

    /// A sheet the user can swipe away — the right choice when the screen is
    /// re-opened from Settings.
    public static let dismissible = WelcomePresentation(isDismissible: true)
}

// MARK: - Modifiers

public extension View {

    /// Presents the welcome screen whenever `isPresented` becomes `true`.
    ///
    /// This is the "show it again" entry point — wire it to a Settings row:
    ///
    /// ```swift
    /// Button("Welcome screen") { showWelcome = true }
    ///     .welcomeSheet(
    ///         isPresented: $showWelcome,
    ///         title: "Welcome to Ova",
    ///         features: features,
    ///         presentation: .dismissible
    ///     )
    /// ```
    ///
    /// The binding is set back to `false` for you when the user continues.
    func welcomeSheet(
        isPresented: Binding<Bool>,
        title: WelcomeText,
        features: [WelcomeFeature],
        configuration: WelcomeConfiguration = .default,
        presentation: WelcomePresentation = .automatic,
        onContinue: (() -> Void)? = nil
    ) -> some View {
        modifier(
            WelcomeSheetModifier(
                isPresented: isPresented,
                content: WelcomeContent(
                    title: title,
                    features: features,
                    configuration: configuration,
                    onContinue: onContinue
                ),
                presentation: presentation,
                onDismiss: nil
            )
        )
    }

    /// Presents the welcome screen once, the first time the app runs, and never
    /// again.
    ///
    /// ```swift
    /// ContentView()
    ///     .welcomeSheetOnFirstLaunch(
    ///         title: "Welcome to Ova",
    ///         features: features
    ///     )
    /// ```
    ///
    /// "Seen" is recorded in `UserDefaults` under ``WelcomeStore/key(for:)``, so
    /// it survives launches but not a reinstall. Change `id` to show a second,
    /// unrelated welcome — `"whats-new-2.0"`, say — without disturbing the
    /// first one. Call ``WelcomeStore/reset(id:in:)`` to arm it again.
    ///
    /// - Parameters:
    ///   - id: Identifies this particular welcome screen.
    ///   - store: Where the flag lives. Pass an app-group `UserDefaults` to
    ///     share it with an extension.
    func welcomeSheetOnFirstLaunch(
        id: String = WelcomeStore.defaultID,
        store: UserDefaults? = nil,
        title: WelcomeText,
        features: [WelcomeFeature],
        configuration: WelcomeConfiguration = .default,
        presentation: WelcomePresentation = .automatic,
        onContinue: (() -> Void)? = nil
    ) -> some View {
        modifier(
            FirstLaunchWelcomeModifier(
                id: id,
                store: store,
                content: WelcomeContent(
                    title: title,
                    features: features,
                    configuration: configuration,
                    onContinue: onContinue
                ),
                presentation: presentation
            )
        )
    }
}

// MARK: - Internals

struct WelcomeContent {
    let title: WelcomeText
    let features: [WelcomeFeature]
    let configuration: WelcomeConfiguration
    let onContinue: (() -> Void)?
}

private struct WelcomeSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let content: WelcomeContent
    let presentation: WelcomePresentation
    let onDismiss: (() -> Void)?

    func body(content parent: Content) -> some View {
        switch presentation.style {
        case .sheet:
            parent.sheet(isPresented: $isPresented, onDismiss: onDismiss) { screen }
        case .fullScreenCover:
            #if os(iOS) || os(visionOS)
            parent.fullScreenCover(isPresented: $isPresented, onDismiss: onDismiss) { screen }
            #else
            parent.sheet(isPresented: $isPresented, onDismiss: onDismiss) { screen }
            #endif
        }
    }

    private var screen: some View {
        WelcomeView(
            title: content.title,
            features: content.features,
            configuration: content.configuration,
            onContinue: {
                isPresented = false
                content.onContinue?()
            }
        )
        .interactiveDismissDisabled(!presentation.isDismissible)
        .welcomeMacOSSheetSize(presentation.macOSSize)
    }
}

private struct FirstLaunchWelcomeModifier: ViewModifier {
    @AppStorage private var hasSeenWelcome: Bool
    @State private var isPresented = false

    let content: WelcomeContent
    let presentation: WelcomePresentation

    init(id: String, store: UserDefaults?, content: WelcomeContent, presentation: WelcomePresentation) {
        _hasSeenWelcome = AppStorage(wrappedValue: false, WelcomeStore.key(for: id), store: store)
        self.content = content
        self.presentation = presentation
    }

    func body(content parent: Content) -> some View {
        parent
            .modifier(
                WelcomeSheetModifier(
                    isPresented: $isPresented,
                    content: content,
                    presentation: presentation,
                    // Dismissed by hand or by the button: either way it has
                    // been seen, so a relaunch must not show it again.
                    onDismiss: { hasSeenWelcome = true }
                )
            )
            .task {
                if !hasSeenWelcome {
                    isPresented = true
                }
            }
    }
}

private extension View {
    @ViewBuilder
    func welcomeMacOSSheetSize(_ size: CGSize) -> some View {
        #if os(macOS)
        frame(width: size.width, height: size.height)
        #else
        self
        #endif
    }
}
