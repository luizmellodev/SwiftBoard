/// A category and every component registered under it, in first-registered order.
@MainActor
public struct CategoryGroup: Identifiable {
    public let id: String
    public let name: String
    public let components: [Component]
}
