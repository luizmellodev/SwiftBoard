@MainActor
public enum ManifestBuilder {
    public static func build(from board: SwiftBoard, boardName: String = "SwiftBoard") -> BoardManifest {
        let categories = board.categorizedComponents.map { group in
            let components = group.components.map { component in
                let scenarios = component.scenarios.map { scenario in
                    ManifestScenario(
                        name: scenario.name,
                        slug: scenario.id,
                        snapshots: snapshotVariants(
                            categorySlug: group.id,
                            componentSlug: component.id,
                            scenarioSlug: scenario.id
                        )
                    )
                }
                return ManifestComponent(name: component.name, slug: component.id, scenarios: scenarios)
            }
            return ManifestCategory(name: group.name, slug: group.id, components: components)
        }

        return BoardManifest(boardName: boardName, categories: categories)
    }

    private static func snapshotVariants(categorySlug: String, componentSlug: String, scenarioSlug: String) -> ManifestSnapshotVariants {
        func path(scale: Int, dark: Bool) -> String {
            SnapshotPath.relative(categorySlug: categorySlug, componentSlug: componentSlug, scenarioSlug: scenarioSlug, scale: scale, dark: dark)
        }
        return ManifestSnapshotVariants(
            light: ManifestSnapshotScales(
                scale1x: path(scale: 1, dark: false),
                scale2x: path(scale: 2, dark: false),
                scale3x: path(scale: 3, dark: false)
            ),
            dark: ManifestSnapshotScales(
                scale1x: path(scale: 1, dark: true),
                scale2x: path(scale: 2, dark: true),
                scale3x: path(scale: 3, dark: true)
            )
        )
    }
}
