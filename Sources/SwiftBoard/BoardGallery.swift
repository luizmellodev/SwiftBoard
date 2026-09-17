import SwiftUI

/// A drop-in SwiftUI view that browses every registered scenario **natively** — no server, no
/// snapshot rendering, just your actual views rendered live. Present it however fits your app,
/// e.g. `.sheet(isPresented: $showGallery) { BoardGallery() }` or push it from a debug menu.
/// Reads the same registry that powers the website, so registering once gives you both.
@MainActor
public struct BoardGallery: View {
    private let board: SwiftBoard
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    public init(board: SwiftBoard? = nil) {
        self.board = board ?? .shared
    }

    public var body: some View {
        NavigationStack {
            List {
                ForEach(filteredGroups) { group in
                    Section(group.name) {
                        ForEach(group.components) { component in
                            NavigationLink(component.name) {
                                ComponentDetail(component: component)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search components")
            .navigationTitle("Components")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
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
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(component.resolvedSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if component.parameters.isEmpty {
                    Text("No initializer docs yet. Pass summary: and parameters: to addScenarios, and docs: ScenarioDocs(snippet:) on each Scenario.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(component.parameters, id: \.name) { parameter in
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(parameter.name)
                                    .font(.caption.monospaced())
                                Text(parameter.type)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                if let defaultValue = parameter.defaultValue {
                                    Text("= \(defaultValue)")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            if let description = parameter.description {
                                Text(description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.background)
        }
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

            if let summary = scenario.docs.summary {
                Text(summary)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if let snippet = scenario.docs.snippet {
                Text(snippet)
                    .font(.system(.caption2, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 6))
            }
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
