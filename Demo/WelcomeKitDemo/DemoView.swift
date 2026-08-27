//
//  DemoView.swift
//  WelcomeKitDemo
//
//  A playground for every knob WelcomeConfiguration exposes. Change something,
//  tap Show welcome screen, see it.
//

import SwiftUI
import WelcomeKit

struct DemoView: View {
    @State private var isShowingWelcome = false

    // Stored, so the playground comes back the way you left it — and so a
    // screenshot script can set any of these from the command line:
    // `xcrun simctl launch booted <bundle-id> -demo.tint pink`
    @AppStorage("demo.tint") private var tint: DemoTint = .blue
    @AppStorage("demo.symbols") private var symbolRenderingMode: WelcomeSymbolRenderingMode = .monochrome
    @AppStorage("demo.button") private var buttonStyle: WelcomeButtonStyle = .automatic
    @AppStorage("demo.background") private var background: DemoBackground = .automatic

    @AppStorage("demo.reveal") private var revealStyle: WelcomeRevealStyle = .blur
    @AppStorage("demo.speed") private var speed: Double = 1
    @AppStorage("demo.haptics") private var isHapticsEnabled = true

    @AppStorage("demo.featureCount") private var featureCount = 5
    @AppStorage("demo.footnote") private var showsFootnote = false
    @AppStorage("demo.secondaryAction") private var showsSecondaryAction = false
    @AppStorage("demo.dismissible") private var isDismissible = true
    @AppStorage("demo.fullScreenCover") private var usesFullScreenCover = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        isShowingWelcome = true
                    } label: {
                        Label("Show welcome screen", systemImage: "sparkles")
                    }
                } footer: {
                    Text("The same screen this app showed you on its first launch.")
                }

                Section("Appearance") {
                    Picker("Tint", selection: $tint) {
                        ForEach(DemoTint.allCases, id: \.self) { tint in
                            Text(tint.name).tag(tint)
                        }
                    }
                    Picker("Symbols", selection: $symbolRenderingMode) {
                        ForEach(WelcomeSymbolRenderingMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue.capitalized).tag(mode)
                        }
                    }
                    Picker("Button", selection: $buttonStyle) {
                        ForEach(WelcomeButtonStyle.allCases, id: \.self) { style in
                            Text(style.rawValue.capitalized).tag(style)
                        }
                    }
                    Picker("Background", selection: $background) {
                        ForEach(DemoBackground.allCases, id: \.self) { background in
                            Text(background.name).tag(background)
                        }
                    }
                }

                Section("Motion") {
                    Picker("Reveal", selection: $revealStyle) {
                        ForEach(WelcomeRevealStyle.allCases, id: \.self) { style in
                            Text(style.rawValue.capitalized).tag(style)
                        }
                    }
                    LabeledContent("Speed") {
                        HStack {
                            Slider(value: $speed, in: 0.5...2, step: 0.1)
                            Text(speed, format: .number.precision(.fractionLength(1)))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    Toggle("Haptics", isOn: $isHapticsEnabled)
                }

                Section("Content") {
                    Stepper("Features: \(featureCount)", value: $featureCount, in: 1...DemoFeatures.all.count)
                    Toggle("Footnote", isOn: $showsFootnote)
                    Toggle("Secondary button", isOn: $showsSecondaryAction)
                }

                Section {
                    Toggle("Dismissible", isOn: $isDismissible)
                    #if os(iOS)
                    Toggle("Full screen cover", isOn: $usesFullScreenCover)
                    #endif
                    Button("Reset first-launch flag") {
                        WelcomeStore.reset(id: "demo")
                    }
                } header: {
                    Text("Presentation")
                } footer: {
                    Text("Reset, then relaunch: the welcome screen comes back on its own.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("WelcomeKit")
        }
        .welcomeSheet(
            isPresented: $isShowingWelcome,
            title: "Welcome to WelcomeKit",
            features: Array(DemoFeatures.all.prefix(featureCount)),
            configuration: configuration,
            presentation: WelcomePresentation(
                style: usesFullScreenCover ? .fullScreenCover : .sheet,
                isDismissible: isDismissible
            ),
            onSecondaryAction: showsSecondaryAction ? {} : nil
        )
        .welcomeSheetOnFirstLaunch(
            id: "demo",
            title: "Welcome to WelcomeKit",
            features: Array(DemoFeatures.all.prefix(5)),
            configuration: .default
        )
        .onAppear {
            // `-demo.autoPresent YES` opens the sheet straight away, which is
            // how the screenshots in the README are taken.
            if UserDefaults.standard.bool(forKey: "demo.autoPresent") {
                isShowingWelcome = true
            }
        }
    }

    private var configuration: WelcomeConfiguration {
        var configuration = WelcomeConfiguration.default
        configuration.accentColor = tint.color
        configuration.symbolRenderingMode = symbolRenderingMode
        configuration.symbolPalette = [tint.color, tint.color.opacity(0.35)]
        configuration.buttonStyle = buttonStyle
        configuration.background = background.background
        configuration.animation = WelcomeAnimation(style: revealStyle, speed: speed)
        configuration.isHapticsEnabled = isHapticsEnabled
        configuration.footnote = showsFootnote ? "You can change any of this later in Settings." : nil
        configuration.secondaryTitle = showsSecondaryAction ? "Not now" : nil
        return configuration
    }
}

// MARK: - Demo options

enum DemoTint: String, CaseIterable {
    case blue, indigo, pink, orange, green, teal

    var name: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .blue: .blue
        case .indigo: .indigo
        case .pink: .pink
        case .orange: .orange
        case .green: .green
        case .teal: .teal
        }
    }
}

enum DemoBackground: String, CaseIterable {
    case automatic, gradient, clear

    var name: String { rawValue.capitalized }

    var background: WelcomeBackground {
        switch self {
        case .automatic: .automatic
        case .gradient: .gradient([Color.blue.opacity(0.16), Color.purple.opacity(0.10), Color.clear])
        case .clear: .clear
        }
    }
}

#Preview {
    DemoView()
}
