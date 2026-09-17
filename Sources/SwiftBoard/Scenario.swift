import SwiftUI

/// A single, named state of a component (e.g. Button/Primary, Button/Disabled).
@MainActor
public struct Scenario: Identifiable {
    public let id: String
    public let name: String
    public let layout: ScenarioLayout
    public let docs: ScenarioDocs
    private let makeContent: () -> AnyView

    public init<V: View>(
        _ name: String,
        layout: ScenarioLayout = .fitContent(maxWidth: 375),
        docs: ScenarioDocs = .empty,
        @ViewBuilder content: @escaping () -> V
    ) {
        self.init(
            name: name,
            id: Slug.make(name),
            layout: layout,
            docs: docs,
            makeContent: { AnyView(content()) }
        )
    }

    /// Bridge-friendly initializer for callers that already have a type-erased view
    /// (e.g. a catalog of `AnyView` entries from an existing design system).
    public init(
        _ name: String,
        layout: ScenarioLayout = .fitContent(maxWidth: 375),
        docs: ScenarioDocs = .empty,
        view: AnyView
    ) {
        self.init(
            name: name,
            id: Slug.make(name),
            layout: layout,
            docs: docs,
            makeContent: { view }
        )
    }

    private init(
        name: String,
        id: String,
        layout: ScenarioLayout,
        docs: ScenarioDocs,
        makeContent: @escaping () -> AnyView
    ) {
        self.name = name
        self.id = id
        self.layout = layout
        self.docs = docs
        self.makeContent = makeContent
    }

    /// Returns a copy of this scenario with a different id, used to resolve id collisions.
    func withID(_ newID: String) -> Scenario {
        Scenario(name: name, id: newID, layout: layout, docs: docs, makeContent: makeContent)
    }

    func render() -> AnyView {
        makeContent()
    }
}

/// How a scenario's view should be sized before being rasterized into a snapshot.
public enum ScenarioLayout: Equatable {
    case fitContent(maxWidth: CGFloat)
    case fixed(width: CGFloat, height: CGFloat)
}
