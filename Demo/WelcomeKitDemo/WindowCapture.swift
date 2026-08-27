//
//  WindowCapture.swift
//  WelcomeKitDemo
//
//  Writes a PNG of the app's own sheet, so Scripts/capture-screenshots.sh can
//  produce the macOS images in the README. `screencapture` would need a Screen
//  Recording permission that a fresh checkout — or CI — will not have; an app
//  snapshotting its own window needs nothing.
//
//  Not part of WelcomeKit. Delete it and the demo still works.
//

#if os(macOS)
import AppKit

@MainActor
enum WindowCapture {

    /// Honours `-demo.captureTo <path>` and `-demo.appearance light|dark` on
    /// the command line.
    static func captureIfRequested() {
        if let appearance = UserDefaults.standard.string(forKey: "demo.appearance") {
            NSApp.appearance = NSAppearance(named: appearance == "dark" ? .darkAqua : .aqua)
        }
        guard let path = UserDefaults.standard.string(forKey: "demo.captureTo") else { return }

        // Give the sheet time to present and the reveal time to finish.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            // A prominent button draws grey in an inactive window, so bring the
            // app forward before the shutter.
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first(where: { $0.isVisible })?.makeKeyAndOrderFront(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                capture(to: path)
                NSApp.terminate(nil)
            }
        }
    }

    private static func capture(to path: String) {
        let sheet = NSApp.windows.compactMap { $0.attachedSheet }.first
        guard let window = sheet ?? NSApp.windows.first(where: { $0.isVisible }),
              let view = window.contentView,
              let layer = view.layer else {
            print("capture: no window")
            return
        }

        // SwiftUI draws into CALayers, which `cacheDisplay` walks straight past.
        // Rendering the layer tree is what actually produces pixels.
        let scale = window.backingScaleFactor
        let width = Int(view.bounds.width * scale)
        let height = Int(view.bounds.height * scale)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            print("capture: no context")
            return
        }
        // Core Graphics draws from the bottom left, AppKit's layer tree from
        // the top left. Flip, or the screenshot comes out upside down.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: scale, y: -scale)
        layer.render(in: context)

        guard let image = context.makeImage(),
              let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            print("capture: no image")
            return
        }
        do {
            try png.write(to: URL(fileURLWithPath: path))
            print("capture: wrote \(path) (\(width)x\(height))")
        } catch {
            print("capture: \(error)")
        }
    }
}
#endif
