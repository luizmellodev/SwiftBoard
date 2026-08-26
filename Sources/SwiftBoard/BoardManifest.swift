/// Codable description of the whole registry, shared by the live server and the static exporter
/// so both backends produce byte-identical JSON/URL shapes.
public struct BoardManifest: Codable, Equatable, Sendable {
    public var boardName: String
    public var categories: [ManifestCategory]
}

public struct ManifestCategory: Codable, Equatable, Sendable {
    public var name: String
    public var slug: String
    public var components: [ManifestComponent]
}

public struct ManifestComponent: Codable, Equatable, Sendable {
    public var name: String
    public var slug: String
    public var scenarios: [ManifestScenario]
}

public struct ManifestScenario: Codable, Equatable, Sendable {
    public var name: String
    public var slug: String
    public var snapshots: ManifestSnapshotVariants
}

public struct ManifestSnapshotVariants: Codable, Equatable, Sendable {
    public var light: ManifestSnapshotScales
    public var dark: ManifestSnapshotScales
}

public struct ManifestSnapshotScales: Codable, Equatable, Sendable {
    public var scale1x: String
    public var scale2x: String
    public var scale3x: String

    enum CodingKeys: String, CodingKey {
        case scale1x = "1x"
        case scale2x = "2x"
        case scale3x = "3x"
    }
}
