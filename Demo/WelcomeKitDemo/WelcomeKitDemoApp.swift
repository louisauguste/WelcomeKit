//
//  WelcomeKitDemoApp.swift
//  WelcomeKitDemo
//

import SwiftUI

@main
struct WelcomeKitDemoApp: App {
    var body: some Scene {
        WindowGroup {
            DemoView()
                #if os(macOS)
                .onAppear { WindowCapture.captureIfRequested() }
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 620, height: 780)
        #endif
    }
}
