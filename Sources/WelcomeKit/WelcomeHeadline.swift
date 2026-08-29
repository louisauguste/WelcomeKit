//
//  WelcomeHeadline.swift
//  WelcomeKit
//

import SwiftUI

/// The big line at the top of the screen, in the two shapes Apple ships.
///
/// A first run gets one block of copy:
///
/// ```swift
/// WelcomeView(headline: "Welcome to Ova", features: features) { … }
/// ```
///
/// An update gets the two-tone treatment — a tinted lead line, then the app's
/// name on its own line in the text colour:
///
/// ```swift
/// WelcomeView(headline: .whatsNew(in: "Ova"), features: features) { … }
/// ```
///
/// - Note: `@unchecked Sendable` for the same reason as ``WelcomeText``: the
///   `LocalizedStringKey` it wraps is a frozen value that never picked up the
///   conformance.
public enum WelcomeHeadline: @unchecked Sendable {

    /// One block of copy, drawn entirely in the primary text colour.
    case plain(WelcomeText)

    /// Two lines: `lead` in the accent colour, `name` underneath in the primary
    /// text colour.
    case twoTone(lead: WelcomeText, name: WelcomeText)

    /// "Welcome to" in the accent colour, the app's name underneath.
    ///
    /// The lead line is looked up as a localized key, so an app that already
    /// translates `"Welcome to"` gets it for free. Pass your own lead line to
    /// ``twoTone(lead:name:)`` if you would rather word it differently.
    public static func welcome(to name: WelcomeText) -> WelcomeHeadline {
        .twoTone(lead: .localized("Welcome to"), name: name)
    }

    /// "What’s new in" in the accent colour, the app's name underneath — the
    /// headline Apple uses when a screen is describing an update rather than a
    /// first run. The apostrophe is the typographic one, as Apple sets it.
    public static func whatsNew(in name: WelcomeText) -> WelcomeHeadline {
        .twoTone(lead: .localized("What’s new in"), name: name)
    }

    // MARK: - Rendering

    /// Builds the headline as a single `Text`, so it wraps, scales and reads out
    /// loud as one string rather than two stacked views.
    @MainActor
    func text(bundle: Bundle?, tableName: String?, accent: AnyShapeStyle) -> Text {
        switch self {
        case .plain(let title):
            return title.text(bundle: bundle, tableName: tableName)
        case .twoTone(let lead, let name):
            return lead.text(bundle: bundle, tableName: tableName).foregroundStyle(accent)
                + Text(verbatim: "\n")
                + name.text(bundle: bundle, tableName: tableName)
        }
    }

    /// The two-tone headline spends a line on its lead, so the configured limit
    /// applies to the name and the lead line is extra.
    func lineLimit(_ configured: Int?) -> Int? {
        switch self {
        case .plain: configured
        case .twoTone: configured.map { $0 + 1 }
        }
    }
}

extension WelcomeHeadline: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    /// A string literal builds the plain headline, and is looked up in your
    /// app's string catalog.
    public init(stringLiteral value: String) {
        self = .plain(.localized(LocalizedStringKey(value)))
    }
}
