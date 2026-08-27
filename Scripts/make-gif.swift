//
//  make-gif.swift
//
//  Turns the simulator recording into the animated GIF in README.md.
//  ffmpeg would do this in one line; this needs nothing that is not already on
//  a Mac with Xcode.
//
//  Usage: xcrun swift Scripts/make-gif.swift <input.mov> <output.gif>
//         [width] [fps] [start] [duration]
//

import AVFoundation
import CoreServices
import Foundation
import ImageIO

let arguments = CommandLine.arguments
guard arguments.count >= 3 else {
    print("usage: make-gif.swift <input.mov> <output.gif> [width] [fps] [start] [duration]")
    exit(1)
}

let input = URL(fileURLWithPath: arguments[1])
let output = URL(fileURLWithPath: arguments[2])
let width = arguments.count > 3 ? Double(arguments[3])! : 300
let fps = arguments.count > 4 ? Double(arguments[4])! : 12
let start = arguments.count > 5 ? Double(arguments[5])! : 0
let duration = arguments.count > 6 ? Double(arguments[6])! : 5

let asset = AVURLAsset(url: input)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
generator.maximumSize = CGSize(width: width, height: 0)

let frameCount = Int(duration * fps)
let times = (0..<frameCount).map {
    NSValue(time: CMTime(seconds: start + Double($0) / fps, preferredTimescale: 600))
}

guard let destination = CGImageDestinationCreateWithURL(
    output as CFURL,
    "com.compuserve.gif" as CFString,
    frameCount,
    nil
) else {
    print("could not create \(output.path)")
    exit(1)
}

CGImageDestinationSetProperties(destination, [
    kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]
] as CFDictionary)

let frameProperties = [
    kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1 / fps]
] as CFDictionary

var written = 0
for time in times {
    do {
        let image = try generator.copyCGImage(at: time.timeValue, actualTime: nil)
        CGImageDestinationAddImage(destination, image, frameProperties)
        written += 1
    } catch {
        // A frame past the end of the recording is not worth failing over.
        break
    }
}

if CGImageDestinationFinalize(destination) {
    let size = (try? FileManager.default.attributesOfItem(atPath: output.path)[.size] as? Int) ?? 0
    print("wrote \(output.lastPathComponent): \(written) frames, \((size ?? 0) / 1024) KB")
} else {
    print("could not finalise the GIF")
    exit(1)
}
