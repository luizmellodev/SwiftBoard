import SwiftUI

/// Rasterizes a `Scenario`'s view into PNG data on demand, using `ImageRenderer`.
@MainActor
public enum ScenarioRenderer {
    public static func renderPNG(scenario: Scenario, scale: CGFloat, colorScheme: ColorScheme) -> Data? {
        let background = colorScheme == .dark ? Color(white: 0.11) : Color.white
        let sized: AnyView

        switch scenario.layout {
        case .fitContent(let maxWidth):
            sized = AnyView(
                scenario.render()
                    .environment(\.colorScheme, colorScheme)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: maxWidth, alignment: .topLeading)
                    .padding(20)
                    .background(background)
            )
        case .fixed(let width, let height):
            sized = AnyView(
                scenario.render()
                    .environment(\.colorScheme, colorScheme)
                    .frame(width: width, height: height)
                    .padding(20)
                    .background(background)
            )
        }

        let renderer = ImageRenderer(content: sized)
        renderer.scale = scale
        renderer.isOpaque = false

        guard let cgImage = renderer.cgImage else { return nil }
        return PNGEncoding.data(from: cgImage, scale: scale)
    }
}
