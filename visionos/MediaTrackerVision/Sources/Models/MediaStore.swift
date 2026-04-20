import Foundation
import Observation
import ARKit

@Observable
final class MediaStore {
    var items: [MediaItem] = []

    // Currently open immersive space item
    var immersiveItem: MediaItem?

    // Room-anchored list assignments: anchorID -> [itemIDs]
    var anchoredLists: [String: [String]] = [:]

    private let saveURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("media_items.json")
    }()

    init() {
        load()
        if items.isEmpty { items = MediaItem.samples }
    }

    // MARK: - CRUD

    func add(_ item: MediaItem) {
        items.insert(item, at: 0)
        save()
    }

    func update(_ item: MediaItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx] = item
        save()
    }

    func delete(_ id: String) {
        items.removeAll { $0.id == id }
        save()
    }

    func toggleFavorite(_ id: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isFavorite.toggle()
        save()
    }

    func setStatus(_ id: String, status: MediaStatus) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].status = status
        if status == .inProgress && items[idx].dateStarted == nil {
            items[idx].dateStarted = .now
        }
        if status == .completed && items[idx].dateCompleted == nil {
            items[idx].dateCompleted = .now
        }
        save()
    }

    // MARK: - Filtered views

    var inProgress: [MediaItem] { items.filter { $0.status == .inProgress } }
    var completed: [MediaItem] { items.filter { $0.status == .completed } }
    var backlog: [MediaItem] { items.filter { $0.status == .backlog } }
    var favorites: [MediaItem] { items.filter { $0.isFavorite } }

    func items(for type: MediaType) -> [MediaItem] {
        items.filter { $0.type == type }
    }

    // MARK: - World Anchor assignment

    func assignAnchor(id: String, anchorID: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].worldAnchorID = anchorID
        save()
    }

    func itemsWithAnchor(_ anchorID: String) -> [MediaItem] {
        items.filter { $0.worldAnchorID == anchorID }
    }

    // MARK: - Persistence

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: saveURL)
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard
            let data = try? Data(contentsOf: saveURL),
            let decoded = try? decoder.decode([MediaItem].self, from: data)
        else { return }
        items = decoded
    }
}
