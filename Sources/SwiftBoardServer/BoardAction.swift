import SwiftBoard

/// A custom action exposed as a button on the site — e.g. "reset local data", "seed demo
/// content", or (in this repo's own demo) "run the iOS Simulator preview". Runs in your own
/// process, so it can do anything a normal function call can.
public struct BoardAction: Sendable {
    public let id: String
    public let title: String
    let run: @Sendable () async throws -> Void

    public init(title: String, id: String? = nil, run: @escaping @Sendable () async throws -> Void) {
        self.title = title
        self.id = id ?? Slug.make(title)
        self.run = run
    }
}
