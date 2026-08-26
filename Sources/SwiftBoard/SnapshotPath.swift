/// The single place that defines the relative URL/file-path scheme for a rendered snapshot.
/// Shared by `ManifestBuilder` (core), the live server, and the static exporter so all three
/// agree on identical paths.
public enum SnapshotPath {
    public static func relative(categorySlug: String, componentSlug: String, scenarioSlug: String, scale: Int, dark: Bool) -> String {
        "snapshots/\(categorySlug)/\(componentSlug)/\(scenarioSlug)@\(scale)x\(dark ? "-dark" : "").png"
    }
}
