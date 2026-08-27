//
//  WelcomeFeature.swift
//  WelcomeKit
//

import SwiftUI

/// One row of the welcome list: an SF Symbol in its own gutter, a title, and a
/// line of explanation underneath.
///
/// ```swift
/// WelcomeFeature(
///     "Private by design",
///     subtitle: "Everything stays on device.",
///     systemImage: "lock.fill"
/// )
/// ```
///
/// String literals are treated as localized keys and looked up in your app's
/// string catalog. For copy that is already localized, or that should never be
/// translated, build the row with ``verbatim(id:_:subtitle:systemImage:tint:symbolRenderingMode:symbolPalette:)``.
public struct WelcomeFeature: Identifiable, Sendable {

    /// Stable identity for the row. Generated unless you pass one in.
    public let id: String

    /// The bold first line.
    public var title: WelcomeText

    /// The secondary line. `nil` renders a title-only row.
    public var subtitle: WelcomeText?

    /// Name of the SF Symbol shown in the leading gutter.
    public var systemImage: String

    /// Overrides ``WelcomeConfiguration/accentColor`` for this row only.
    public var tint: Color?

    /// Overrides ``WelcomeConfiguration/symbolRenderingMode`` for this row only.
    public var symbolRenderingMode: WelcomeSymbolRenderingMode?

    /// Overrides ``WelcomeConfiguration/symbolPalette`` for this row only.
    /// Only read when the effective rendering mode is ``WelcomeSymbolRenderingMode/palette``.
    public var symbolPalette: [Color]?

    /// Creates a feature row.
    ///
    /// String literals are treated as localized keys. Wrap a runtime string in
    /// ``WelcomeText/verbatim(_:)`` to show it exactly as given.
    public init(
        id: String? = nil,
        _ title: WelcomeText,
        subtitle: WelcomeText? = nil,
        systemImage: String,
        tint: Color? = nil,
        symbolRenderingMode: WelcomeSymbolRenderingMode? = nil,
        symbolPalette: [Color]? = nil
    ) {
        self.id = id ?? UUID().uuidString
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.symbolRenderingMode = symbolRenderingMode
        self.symbolPalette = symbolPalette
    }

    /// Creates a feature row from strings that are shown exactly as given —
    /// already-localized copy, or a name that should never be translated.
    public static func verbatim(
        id: String? = nil,
        _ title: String,
        subtitle: String? = nil,
        systemImage: String,
        tint: Color? = nil,
        symbolRenderingMode: WelcomeSymbolRenderingMode? = nil,
        symbolPalette: [Color]? = nil
    ) -> WelcomeFeature {
        WelcomeFeature(
            id: id ?? title,
            .verbatim(title),
            subtitle: subtitle.map(WelcomeText.verbatim),
            systemImage: systemImage,
            tint: tint,
            symbolRenderingMode: symbolRenderingMode,
            symbolPalette: symbolPalette
        )
    }
}

// MARK: - Text

/// A piece of copy that is either looked up in a string catalog or shown as-is.
///
/// - Note: `@unchecked Sendable` because `LocalizedStringKey` predates
///   `Sendable` and never picked up the conformance. It is a frozen, immutable
///   value, so passing one between isolation domains is safe.
public enum WelcomeText: @unchecked Sendable {
    case localized(LocalizedStringKey)
    case verbatim(String)

    @MainActor
    func text(bundle: Bundle?, tableName: String?) -> Text {
        switch self {
        case .localized(let key):
            Text(key, tableName: tableName, bundle: bundle)
        case .verbatim(let string):
            Text(verbatim: string)
        }
    }
}

extension WelcomeText: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self = .localized(LocalizedStringKey(value))
    }
}

// MARK: - Symbol rendering

/// The SF Symbol rendering modes, mirrored so a configuration stays `Sendable`
/// and comparable.
///
/// - Note: ``multicolor`` falls back to the symbol's monochrome form for symbols
///   that ship without a multicolor variant — that is SF Symbols' own behaviour.
public enum WelcomeSymbolRenderingMode: String, Sendable, CaseIterable, Hashable {
    /// One flat colour. The look shipped by Apple's own welcome sheets.
    case monochrome
    /// One colour, with the symbol's secondary layers dimmed automatically.
    case hierarchical
    /// One colour per layer, taken from ``WelcomeConfiguration/symbolPalette``.
    case palette
    /// The symbol's own colours, ignoring the tint.
    case multicolor

    var symbolRenderingMode: SymbolRenderingMode {
        switch self {
        case .monochrome: .monochrome
        case .hierarchical: .hierarchical
        case .palette: .palette
        case .multicolor: .multicolor
        }
    }
}
