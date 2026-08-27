//
//  WelcomeStore.swift
//  WelcomeKit
//

import Foundation

/// The flag behind ``SwiftUICore/View/welcomeSheetOnFirstLaunch(id:store:title:features:configuration:presentation:onContinue:onSecondaryAction:)``.
///
/// Read it to branch on whether the welcome screen has run, or reset it to make
/// it run again — after a big update, or from a debug menu.
public enum WelcomeStore {

    /// Identifier used when you do not pass one.
    public static let defaultID = "welcome"

    /// The `UserDefaults` key for a given welcome screen.
    ///
    /// Exposed so you can seed it in UI tests:
    /// `app.launchArguments += ["-WelcomeKit.hasSeen.welcome", "YES"]`.
    public static func key(for id: String = defaultID) -> String {
        "WelcomeKit.hasSeen.\(id)"
    }

    /// Whether this welcome screen has already been shown.
    public static func hasSeenWelcome(id: String = defaultID, in store: UserDefaults? = nil) -> Bool {
        (store ?? .standard).bool(forKey: key(for: id))
    }

    /// Records the screen as seen without showing it — useful when an account
    /// restore means the user has been through this before.
    public static func markAsSeen(id: String = defaultID, in store: UserDefaults? = nil) {
        (store ?? .standard).set(true, forKey: key(for: id))
    }

    /// Arms the first-launch screen again. It shows on the next launch, or as
    /// soon as the view carrying the modifier appears.
    public static func reset(id: String = defaultID, in store: UserDefaults? = nil) {
        (store ?? .standard).removeObject(forKey: key(for: id))
    }
}
