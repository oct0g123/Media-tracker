import SwiftUI
import RealityKit
import ARKit

/// Mixed-immersion space: the user can tap any flat surface in their room
/// to pin a media list there. The list floats persistently at that physical location
/// across sessions using WorldAnchor.
///
/// Flow:
///   1. User opens the "Room Lists" immersive space.
///   2. A placement reticle follows detected surfaces.
///   3. Tap to drop a list at that location — choose which status group to pin.
///   4. The WorldAnchor ID is saved per-item so the panel re-appears on next launch.
struct RoomAnchoredView: View {
    @Environment(MediaStore.self) private var store
    @Environment(\.dismissImmersiveSpace) private var dismissSpace

    @State private var arSession = ARKitSession()
    @State private var worldTracking = WorldTrackingProvider()
    @State private var planeDetection = PlaneDetectionProvider(alignments: [.horizontal, .vertical])

    @State private var reticleTransform: Transform?
    @State private var detectedPlanes: [PlaneAnchor] = []
    @State private var placedAnchors: [WorldAnchor] = []
    @State private var showPinPicker = false
    @State private var pendingTransform: Transform?
    @State private var selectedStatus: MediaStatus = .backlog

    var body: some View {
        ZStack {
            RealityView { content, attachments in
                await startARSession()
                Task { await runPlaneUpdates(content: content) }
                Task { await runWorldAnchorUpdates(content: content, attachments: attachments) }
            } update: { content, attachments in
                updateReticle(content: content)
            } attachments: {
                // Render a floating list for every placed anchor
                ForEach(placedAnchors, id: \.id) { anchor in
                    Attachment(id: anchor.id.uuidString) {
                        AnchoredListPanel(
                            anchorID: anchor.id.uuidString,
                            status: statusForAnchor(anchor.id.uuidString),
                            store: store,
                            onRemove: { removeAnchor(anchor) }
                        )
                    }
                }

                // Placement HUD
                Attachment(id: "placement-hud") {
                    PlacementHUD(
                        canPlace: reticleTransform != nil,
                        onPlace: {
                            pendingTransform = reticleTransform
                            showPinPicker = true
                        },
                        onDismiss: {
                            Task { await dismissSpace() }
                        }
                    )
                }
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { _ in
                        pendingTransform = reticleTransform
                        showPinPicker = true
                    }
            )
        }
        .sheet(isPresented: $showPinPicker) {
            PinListPicker(selectedStatus: $selectedStatus) {
                if let transform = pendingTransform {
                    Task { await placeAnchor(at: transform, status: selectedStatus) }
                }
                showPinPicker = false
            }
        }
    }

    // MARK: - ARKit session

    private func startARSession() async {
        guard WorldTrackingProvider.isSupported && PlaneDetectionProvider.isSupported else { return }
        try? await arSession.run([worldTracking, planeDetection])
    }

    // MARK: - Plane updates (drives the reticle)

    private func runPlaneUpdates(content: RealityViewContent) async {
        for await update in planeDetection.anchorUpdates {
            switch update.event {
            case .added, .updated:
                let anchor = update.anchor
                if anchor.classification == .floor || anchor.classification == .table || anchor.classification == .wall {
                    await MainActor.run {
                        if !detectedPlanes.contains(where: { $0.id == anchor.id }) {
                            detectedPlanes.append(anchor)
                        }
                        // Set reticle to this plane's center
                        var t = Transform(matrix: anchor.originFromAnchorTransform)
                        t.translation += [0, 0.02, 0]  // Lift slightly off surface
                        reticleTransform = t
                    }
                }
            case .removed:
                await MainActor.run {
                    detectedPlanes.removeAll { $0.id == update.anchor.id }
                }
            }
        }
    }

    // MARK: - World anchor updates (restores pinned panels)

    private func runWorldAnchorUpdates(content: RealityViewContent, attachments: RealityViewAttachments) async {
        for await update in worldTracking.anchorUpdates {
            switch update.event {
            case .added, .updated:
                let anchor = update.anchor
                await MainActor.run {
                    if !placedAnchors.contains(where: { $0.id == anchor.id }) {
                        placedAnchors.append(anchor)
                    }
                    // Position the attachment at the anchor's world transform
                    if let attachment = attachments.entity(for: anchor.id.uuidString) {
                        attachment.transform = Transform(matrix: anchor.originFromAnchorTransform)
                        content.add(attachment)
                    }
                }
            case .removed:
                await MainActor.run {
                    placedAnchors.removeAll { $0.id == update.anchor.id }
                }
            }
        }
    }

    // MARK: - Reticle

    private func updateReticle(content: RealityViewContent) {
        // Find or create the reticle entity
        var reticle = content.entities.first(where: { $0.name == "reticle" })
        if reticle == nil {
            let mesh = MeshResource.generateCylinder(height: 0.005, radius: 0.12)
            var mat = UnlitMaterial(color: .init(white: 1, alpha: 0.5))
            reticle = ModelEntity(mesh: mesh, materials: [mat])
            reticle?.name = "reticle"
            content.add(reticle!)
        }
        if let t = reticleTransform {
            reticle?.transform = t
        }
    }

    // MARK: - Place anchor

    private func placeAnchor(at transform: Transform, status: MediaStatus) async {
        guard worldTracking.state == .running else { return }
        let anchor = WorldAnchor(originFromAnchorTransform: transform.matrix)
        do {
            try await worldTracking.addAnchor(anchor)
            await MainActor.run {
                placedAnchors.append(anchor)
            }
        } catch {
            print("Failed to add world anchor: \(error)")
        }
    }

    private func removeAnchor(_ anchor: WorldAnchor) {
        Task {
            try? await worldTracking.removeAnchor(anchor)
            await MainActor.run {
                placedAnchors.removeAll { $0.id == anchor.id }
            }
        }
    }

    // MARK: - Helpers

    private func statusForAnchor(_ anchorID: String) -> MediaStatus {
        // Derive status from which items are assigned to this anchor
        let items = store.itemsWithAnchor(anchorID)
        return items.first?.status ?? .backlog
    }
}

// MARK: - Anchored list panel (shown floating at each room position)

struct AnchoredListPanel: View {
    let anchorID: String
    let status: MediaStatus
    let store: MediaStore
    let onRemove: () -> Void

    private var items: [MediaItem] {
        store.items.filter { $0.status == status }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StatusPill(status: status)
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if items.isEmpty {
                Text("Nothing here yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(items.prefix(8)) { item in
                    HStack(spacing: 8) {
                        Text(item.type.emoji)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            if !item.progress.isEmpty {
                                Text(item.progress)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button {
                            store.setStatus(item.id, status: .completed)
                        } label: {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if items.count > 8 {
                    Text("+ \(items.count - 8) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(width: 280)
        .glassBackgroundEffect()
    }
}

// MARK: - Placement HUD

struct PlacementHUD: View {
    let canPlace: Bool
    let onPlace: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(canPlace ? "Tap to pin a list here" : "Look at a surface to detect it")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Pin List Here", action: onPlace)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canPlace)

                Button("Done", action: onDismiss)
                    .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .glassBackgroundEffect()
    }
}

// MARK: - Status picker for new pin

struct PinListPicker: View {
    @Binding var selectedStatus: MediaStatus
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Which list would you like to pin to this spot?") {
                    ForEach(MediaStatus.allCases) { status in
                        HStack {
                            StatusPill(status: status)
                            Spacer()
                            if selectedStatus == status {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(.rect)
                        .onTapGesture { selectedStatus = status }
                    }
                }
            }
            .navigationTitle("Pin a List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pin", action: onConfirm)
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Room anchor manager (shown in the main window sidebar)

struct RoomAnchorManagerView: View {
    @Environment(MediaStore.self) private var store
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var isOpen = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Room-Anchored Lists")
                .font(.title2.bold())

            Text("Pin your media lists to physical surfaces in your room. Your Backlog, In Progress, or any other list floats right where you placed it — even after relaunching the app.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .padding(.horizontal)

            Button(isOpen ? "Close Room View" : "Enter Room Placement") {
                Task {
                    if isOpen {
                        await dismissImmersiveSpace()
                        isOpen = false
                    } else {
                        await openImmersiveSpace(id: "room-anchored")
                        isOpen = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Requires Apple Vision Pro with LiDAR")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
