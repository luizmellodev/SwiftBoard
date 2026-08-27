import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Rasterizes a `Scenario`'s view into PNG data on demand.
///
/// Renders via a real (offscreen) `NSHostingView`/`UIHostingController`, not `ImageRenderer` —
/// `ImageRenderer` can't rasterize live text-entry controls (`TextField`, `SecureField`,
/// `TextEditor`, and native-styled pickers built on them): without a real window/responder
/// chain it substitutes a "can't render this" placeholder instead of the control's content.
/// Hosting views don't have that requirement.
@MainActor
public enum ScenarioRenderer {
    public static func renderPNG(scenario: Scenario, scale: CGFloat, colorScheme: ColorScheme) -> Data? {
        let background = colorScheme == .dark ? Color(white: 0.11) : Color.white
        let content = AnyView(
            scenario.render()
                .environment(\.colorScheme, colorScheme)
                .padding(20)
                .background(background)
        )

        #if canImport(AppKit)
        return renderOnAppKit(content, layout: scenario.layout, scale: scale)
        #elseif canImport(UIKit)
        return renderOnUIKit(content, layout: scenario.layout, scale: scale)
        #else
        return nil
        #endif
    }

    #if canImport(AppKit)
    private static func renderOnAppKit(_ content: AnyView, layout: ScenarioLayout, scale: CGFloat) -> Data? {
        let hostingView = NSHostingView(rootView: content)

        switch layout {
        case .fitContent(let maxWidth):
            hostingView.frame = CGRect(x: 0, y: 0, width: maxWidth, height: 10)
            hostingView.layoutSubtreeIfNeeded()
            let measured = hostingView.fittingSize
            hostingView.frame = CGRect(origin: .zero, size: measured)
        case .fixed(let width, let height):
            hostingView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }
        hostingView.layoutSubtreeIfNeeded()

        let size = hostingView.bounds.size
        guard size.width > 0, size.height > 0 else { return nil }

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width * scale),
            pixelsHigh: Int(size.height * scale),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        rep.size = size

        hostingView.cacheDisplay(in: hostingView.bounds, to: rep)
        return rep.representation(using: .png, properties: [:])
    }
    #endif

    #if canImport(UIKit)
    private static func renderOnUIKit(_ content: AnyView, layout: ScenarioLayout, scale: CGFloat) -> Data? {
        let hostingController = UIHostingController(rootView: content)
        guard let view = hostingController.view else { return nil }

        switch layout {
        case .fitContent(let maxWidth):
            view.frame = CGRect(x: 0, y: 0, width: maxWidth, height: 10)
            view.setNeedsLayout()
            view.layoutIfNeeded()
            let measured = view.systemLayoutSizeFitting(
                CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            view.frame = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: measured.height))
        case .fixed(let width, let height):
            view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }
        view.setNeedsLayout()
        view.layoutIfNeeded()

        let size = view.bounds.size
        guard size.width > 0, size.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        return image.pngData()
    }
    #endif
}
