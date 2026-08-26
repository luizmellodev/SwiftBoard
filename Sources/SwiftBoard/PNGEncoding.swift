import CoreGraphics
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum PNGEncoding {
    static func data(from cgImage: CGImage, scale: CGFloat) -> Data? {
        #if canImport(UIKit)
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up).pngData()
        #elseif canImport(AppKit)
        let rep = NSBitmapImageRep(cgImage: cgImage)
        return rep.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
}
