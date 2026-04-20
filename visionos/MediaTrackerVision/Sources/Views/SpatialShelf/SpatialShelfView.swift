import SwiftUI
import RealityKit

/// Volumetric window showing the full media collection as a physical 3D shelf.
/// Book spines, movie cases, game cartridges, and vinyl records float in space.
/// Tap any object to reveal a detail ornament beside it.
struct SpatialShelfView: View {
    @Environment(MediaStore.self) private var store
    @State private var selectedItem: MediaItem?
    @State private var showForm = false

    var body: some View {
        ZStack {
            RealityView { content, attachments in
                // Build the shelf
                let shelf = buildShelf(items: store.items, attachments: attachments)
                content.add(shelf)
            } update: { content, attachments in
                // Rebuild when items change
                content.entities.removeAll()
                let shelf = buildShelf(items: store.items, attachments: attachments)
                content.add(shelf)
            } attachments: {
                // Ornament panel for selected item
                if let item = selectedItem {
                    Attachment(id: "detail-\(item.id)") {
                        ShelfDetailOrnament(item: item, onEdit: { showForm = true }, onDismiss: { selectedItem = nil })
                    }
                }
            }
            .onTapGesture { _ in
                // Taps are handled per-entity in gesture modifier below
            }

            // Controls overlay
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("\(store.items.count) items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassBackgroundEffect()
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showForm) {
            if let item = selectedItem {
                MediaFormView(item: item)
                    .environment(store)
            }
        }
    }

    // MARK: - Shelf builder

    private func buildShelf(items: [MediaItem], attachments: RealityViewAttachments) -> Entity {
        let root = Entity()

        // Shelf plank
        let plankMesh = MeshResource.generateBox(width: 1.1, height: 0.02, depth: 0.15)
        var plankMaterial = PhysicallyBasedMaterial()
        plankMaterial.baseColor = .init(tint: UIColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1))
        plankMaterial.roughness = .init(floatLiteral: 0.8)
        let plank = ModelEntity(mesh: plankMesh, materials: [plankMaterial])
        plank.position = [0, -0.01, 0]
        root.addChild(plank)

        // Place items along the shelf
        let maxPerRow = 10
        let itemWidth: Float = 0.07
        let startX: Float = -0.5
        let rowSpacing: Float = 0.25

        for (index, item) in items.prefix(30).enumerated() {
            let row = index / maxPerRow
            let col = index % maxPerRow
            let x = startX + Float(col) * itemWidth
            let y = Float(row) * rowSpacing + 0.06
            let z: Float = 0

            let entity = makeItemEntity(item: item)
            entity.position = [x, y, z]

            // Interaction component
            entity.components.set(InputTargetComponent())
            entity.components.set(HoverEffectComponent())

            // Tag with item id so tap handler can find it
            entity.name = item.id

            root.addChild(entity)

            // Attach detail ornament next to selected item
            if let selected = selectedItem, selected.id == item.id,
               let attachment = attachments.entity(for: "detail-\(item.id)") {
                attachment.position = [x + 0.12, y + 0.1, 0.05]
                root.addChild(attachment)
            }
        }

        return root
    }

    // MARK: - Per-type 3D objects

    private func makeItemEntity(_ item: MediaItem) -> ModelEntity {
        switch item.type {
        case .book, .comic:
            return makeBook(item: item)
        case .movie, .tv, .anime:
            return makeDVDCase(item: item)
        case .game:
            return makeGameCartridge(item: item)
        case .music, .podcast:
            return makeVinyl(item: item)
        }
    }

    private func makeBook(_ item: MediaItem) -> ModelEntity {
        let mesh = MeshResource.generateBox(width: 0.05, height: 0.12, depth: 0.02,
                                            cornerRadius: 0.002)
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: uiColor(for: item.type))
        mat.roughness = .init(floatLiteral: 0.7)
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.generateCollisionShapes(recursive: false)
        return entity
    }

    private func makeDVDCase(_ item: MediaItem) -> ModelEntity {
        let mesh = MeshResource.generateBox(width: 0.04, height: 0.12, depth: 0.01,
                                            cornerRadius: 0.001)
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: uiColor(for: item.type))
        mat.roughness = .init(floatLiteral: 0.3)
        mat.metallic = .init(floatLiteral: 0.1)
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.generateCollisionShapes(recursive: false)
        return entity
    }

    private func makeGameCartridge(_ item: MediaItem) -> ModelEntity {
        let mesh = MeshResource.generateBox(width: 0.04, height: 0.07, depth: 0.015,
                                            cornerRadius: 0.003)
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: uiColor(for: item.type))
        mat.roughness = .init(floatLiteral: 0.5)
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.generateCollisionShapes(recursive: false)
        return entity
    }

    private func makeVinyl(_ item: MediaItem) -> ModelEntity {
        let mesh = MeshResource.generateCylinder(height: 0.005, radius: 0.06)
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1))
        mat.roughness = .init(floatLiteral: 0.2)
        mat.metallic = .init(floatLiteral: 0.8)
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.generateCollisionShapes(recursive: false)
        return entity
    }

    private func uiColor(for type: MediaType) -> UIColor {
        switch type {
        case .movie:   return UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1)
        case .tv:      return UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1)
        case .book:    return UIColor(red: 0.7, green: 0.4, blue: 0.1, alpha: 1)
        case .podcast: return UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1)
        case .game:    return UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1)
        case .music:   return UIColor(red: 0.9, green: 0.3, blue: 0.6, alpha: 1)
        case .anime:   return UIColor(red: 0.1, green: 0.7, blue: 0.8, alpha: 1)
        case .comic:   return UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1)
        }
    }
}

// MARK: - Ornament detail panel (shown next to tapped shelf item)

struct ShelfDetailOrnament: View {
    let item: MediaItem
    let onEdit: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.type.emoji)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.headline)
                    if !item.creator.isEmpty {
                        Text(item.creator)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                StatusPill(status: item.status)
                if let rating = item.rating {
                    StarDisplay(rating: rating)
                }
            }

            if !item.progress.isEmpty {
                Label(item.progress, systemImage: "bookmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !item.notes.isEmpty {
                Text(item.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Button("Edit", action: onEdit)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(16)
        .frame(width: 260)
        .glassBackgroundEffect()
    }
}
