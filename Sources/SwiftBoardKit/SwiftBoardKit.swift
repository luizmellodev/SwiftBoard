/// Optional product: SwiftBoard + SwiftDS. Link this instead of copying a registrar.
/// Apps that only want a custom design system should depend on **SwiftBoardServer** only.
public enum SwiftBoardKit {
    @MainActor
    public static func registerAll(into board: SwiftBoard? = nil) {
        SwiftDSCatalogRegistrar.registerAll(into: board)
    }
}
