/// Parses a `:file` route segment (e.g. `primary@2x.png`, `primary@2x-dark.png`) back into its
/// scenario/scale/theme components. This is the mirror of `SnapshotPath.relative`.
struct SnapshotKey {
    let categorySlug: String
    let componentSlug: String
    let scenarioSlug: String
    let scale: Int
    let isDark: Bool

    var cacheKey: String {
        "\(categorySlug)/\(componentSlug)/\(scenarioSlug)@\(scale)x\(isDark ? "-dark" : "")"
    }

    init?(categorySlug: String, componentSlug: String, file: String) {
        guard file.hasSuffix(".png") else { return nil }
        let base = file.dropLast(4) // remove ".png"

        let isDark = base.hasSuffix("-dark")
        let withoutDark = isDark ? base.dropLast(5) : base

        guard let atIndex = withoutDark.lastIndex(of: "@") else { return nil }
        let scenarioSlug = String(withoutDark[withoutDark.startIndex..<atIndex])
        let scalePart = withoutDark[withoutDark.index(after: atIndex)...]

        guard scalePart.hasSuffix("x"), !scenarioSlug.isEmpty else { return nil }
        guard let scale = Int(scalePart.dropLast()) else { return nil }

        self.categorySlug = categorySlug
        self.componentSlug = componentSlug
        self.scenarioSlug = scenarioSlug
        self.scale = scale
        self.isDark = isDark
    }
}
