import SwiftUI

/// A drop-in SwiftUI view that browses every registered scenario **natively** — no server, no
/// snapshot rendering, just your actual views rendered live. Present it however fits your app,
/// e.g. `.sheet(isPresented: $showGallery) { BoardGallery() }` or push it from a debug menu.
/// Reads the same registry that powers the website, so registering once gives you both.
@MainActor
public struct BoardGallery: View {
    private let board: SwiftBoard
    @State private var searchText = ""
    @State private var selection: Selection?

    private struct Selection: Hashable {
        let category: String
        let component: String
    }

    public init(board: SwiftBoard? = nil) {
        self.board = board ?? .shared
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(filteredGroups) { group in
                    Section(group.name) {
                        ForEach(group.components) { component in
                            Text(component.name)
                                .tag(Selection(category: group.id, component: component.id))
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search components")
            .navigationTitle("Components")
        } detail: {
            if let selection, let component = board.component(categorySlug: selection.category, componentSlug: selection.component) {
                ComponentDetail(component: component)
            } else {
                ContentUnavailableView("Select a component", systemImage: "square.grid.2x2")
            }
        }
    }

    private var filteredGroups: [CategoryGroup] {
        let groups = board.categorizedComponents
        guard !searchText.isEmpty else { return groups }

        let query = searchText.lowercased()
        return groups.compactMap { group in
            let matches = group.components.filter {
                $0.name.lowercased().contains(query) || group.name.lowercased().contains(query)
            }
            return matches.isEmpty ? nil : CategoryGroup(id: group.id, name: group.name, components: matches)
        }
    }
}

private struct ComponentDetail: View {
    let component: Component

    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 16, alignment: .top)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(component.scenarios) { scenario in
                    ScenarioCard(scenario: scenario)
                }
            }
            .padding(20)
        }
        .navigationTitle(component.name)
    }
}

private struct ScenarioCard: View {
    let scenario: Scenario

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sizedContent
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))

            Text(scenario.name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var sizedContent: some View {
        switch scenario.layout {
        case .fitContent(let maxWidth):
            scenario.render()
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: maxWidth, alignment: .topLeading)
        case .fixed(let width, let height):
            scenario.render()
                .frame(width: width, height: height)
        }
    }
}
