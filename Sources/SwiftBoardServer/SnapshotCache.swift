import Foundation

/// Caches rendered snapshot PNGs, invalidated whenever the board's registration `revision` changes.
actor SnapshotCache {
    private struct Entry {
        let revision: Int
        let data: Data
    }

    private var storage: [String: Entry] = [:]

    func data(for key: String, revision: Int, render: () async -> Data?) async -> Data? {
        if let entry = storage[key], entry.revision == revision {
            return entry.data
        }
        guard let data = await render() else { return nil }
        storage[key] = Entry(revision: revision, data: data)
        return data
    }
}
