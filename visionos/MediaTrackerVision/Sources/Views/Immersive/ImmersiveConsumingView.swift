import SwiftUI
import RealityKit

/// Full progressive immersive space that wraps around you when you mark something as "In Progress."
/// Each media type has a distinct themed environment:
///   - Cinema  (movies / TV / anime): dark theatre, projector beam, floating film reel particles
///   - Library (books / comics):      warm reading lamp glow, floating page particles
///   - Arcade  (games):               neon grid floor, colorful light pulses
///   - Concert (music / podcasts):    stage spotlights, audio-waveform particles
struct ImmersiveConsumingView: View {
    @Environment(MediaStore.self) private var store
    @Environment(\.dismissImmersiveSpace) private var dismiss

    // Pick the first in-progress item; user can cycle through them
    @State private var itemIndex = 0

    private var currentItem: MediaItem? {
        guard !store.inProgress.isEmpty else { return nil }
        return store.inProgress[min(itemIndex, store.inProgress.count - 1)]
    }

    var body: some View {
        ZStack {
            if let item = currentItem {
                // RealityKit environment layer
                RealityView { content in
                    buildEnvironment(for: item, in: content)
                } update: { content in
                    content.entities.removeAll()
                    buildEnvironment(for: item, in: content)
                }

                // Floating HUD overlay
                ConsumingHUD(item: item,
                             totalItems: store.inProgress.count,
                             currentIndex: itemIndex,
                             onNext: { itemIndex = min(itemIndex + 1, store.inProgress.count - 1) },
                             onPrev: { itemIndex = max(itemIndex - 1, 0) },
                             onMarkComplete: {
                    store.setStatus(item.id, status: .completed)
                    store.immersiveItem = store.inProgress.first
                    if store.inProgress.isEmpty { store.immersiveItem = nil }
                },
                             onDismiss: {
                    store.immersiveItem = nil
                })
            } else {
                // Nothing in progress — auto-dismiss
                Color.clear.onAppear {
                    Task { await dismiss() }
                }
            }
        }
    }

    // MARK: - Environment builder

    private func buildEnvironment(for item: MediaItem, in content: RealityViewContent) {
        let theme = item.type.immersiveTheme
        switch theme {
        case .cinema:  buildCinema(in: content)
        case .library: buildLibrary(in: content)
        case .arcade:  buildArcade(in: content)
        case .concert: buildConcert(in: content)
        }

        // Ambient color wash matching type
        addColorWash(color: item.type.accentColor, in: content)
    }

    // MARK: - Cinema

    private func buildCinema(in content: RealityViewContent) {
        // Large dark screen in front
        let screenMesh = MeshResource.generatePlane(width: 4.0, height: 2.5)
        var screenMat = UnlitMaterial(color: .init(white: 0.05, alpha: 1))
        let screen = ModelEntity(mesh: screenMesh, materials: [screenMat])
        screen.position = [0, 1.2, -3.5]
        content.add(screen)

        // Projector beam (narrow box pointing forward)
        let beamMesh = MeshResource.generateBox(width: 0.08, height: 0.08, depth: 3.0)
        var beamMat = UnlitMaterial(color: .init(white: 1, alpha: 0.06))
        let beam = ModelEntity(mesh: beamMesh, materials: [beamMat])
        beam.position = [0, 2.4, -1.5]
        content.add(beam)

        // Scattered seat rows (simple dark boxes)
        for row in 0..<3 {
            for col in -3...3 {
                let seatMesh = MeshResource.generateBox(width: 0.3, height: 0.4, depth: 0.35, cornerRadius: 0.04)
                var seatMat = PhysicallyBasedMaterial()
                seatMat.baseColor = .init(tint: UIColor(red: 0.15, green: 0.1, blue: 0.2, alpha: 1))
                let seat = ModelEntity(mesh: seatMesh, materials: [seatMat])
                seat.position = [Float(col) * 0.6, Float(row) * 0.5 - 0.6, Float(row) * -0.8 - 0.5]
                content.add(seat)
            }
        }

        // Floating film-grain particles
        addParticleField(count: 120, spread: SIMD3(4, 3, 4),
                         color: .init(white: 0.9, alpha: 0.15), size: 0.003, in: content)
    }

    // MARK: - Library

    private func buildLibrary(in content: RealityViewContent) {
        // Bookshelf walls left + right
        for side: Float in [-2.5, 2.5] {
            let shelfMesh = MeshResource.generateBox(width: 0.12, height: 3.0, depth: 2.0)
            var shelfMat = PhysicallyBasedMaterial()
            shelfMat.baseColor = .init(tint: UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1))
            shelfMat.roughness = .init(floatLiteral: 0.8)
            let shelf = ModelEntity(mesh: shelfMesh, materials: [shelfMat])
            shelf.position = [side, 0.5, -1.0]
            content.add(shelf)
        }

        // Warm desk lamp glow
        let lamp = PointLight()
        lamp.light.color = UIColor(red: 1.0, green: 0.85, blue: 0.55, alpha: 1)
        lamp.light.intensity = 2000
        lamp.light.attenuationRadius = 4.0
        let lampEntity = Entity()
        lampEntity.components.set(lamp)
        lampEntity.position = [0.4, 1.4, 0]
        content.add(lampEntity)

        // Floating page fragments
        addParticleField(count: 60, spread: SIMD3(3, 2, 3),
                         color: .init(red: 1, green: 0.95, blue: 0.8, alpha: 0.3), size: 0.025, in: content)
    }

    // MARK: - Arcade

    private func buildArcade(in content: RealityViewContent) {
        // Neon grid floor
        let floorMesh = MeshResource.generatePlane(width: 8, depth: 8)
        var floorMat = UnlitMaterial(color: .init(red: 0, green: 0.05, blue: 0.1, alpha: 1))
        let floor = ModelEntity(mesh: floorMesh, materials: [floorMat])
        floor.position = [0, -1.1, -2]
        content.add(floor)

        // Grid lines (thin box strips)
        for i in -4...4 {
            let lineMesh = MeshResource.generateBox(width: 8, height: 0.005, depth: 0.01)
            var lineMat = UnlitMaterial(color: .init(red: 0, green: 0.8, blue: 1, alpha: 0.5))
            let line = ModelEntity(mesh: lineMesh, materials: [lineMat])
            line.position = [0, -1.09, Float(i) * 1.0 - 2]
            content.add(line)

            let lineMesh2 = MeshResource.generateBox(width: 0.01, height: 0.005, depth: 8)
            let line2 = ModelEntity(mesh: lineMesh2, materials: [lineMat])
            line2.position = [Float(i) * 1.0, -1.09, -2]
            content.add(line2)
        }

        // Neon light columns
        let neonColors: [UIColor] = [
            .init(red: 1, green: 0, blue: 0.8, alpha: 1),
            .init(red: 0, green: 1, blue: 0.8, alpha: 1),
            .init(red: 1, green: 0.8, blue: 0, alpha: 1),
        ]
        for (i, color) in neonColors.enumerated() {
            let light = PointLight()
            light.light.color = color
            light.light.intensity = 1500
            light.light.attenuationRadius = 3.0
            let e = Entity()
            e.components.set(light)
            e.position = [Float(i - 1) * 2.0, 0.5, -2.5]
            content.add(e)
        }

        // Pixel-sparkle particles
        addParticleField(count: 200, spread: SIMD3(4, 2, 4),
                         color: .init(red: 0, green: 1, blue: 0.8, alpha: 0.5), size: 0.006, in: content)
    }

    // MARK: - Concert

    private func buildConcert(in content: RealityViewContent) {
        // Stage platform
        let stageMesh = MeshResource.generateBox(width: 5, height: 0.2, depth: 2)
        var stageMat = PhysicallyBasedMaterial()
        stageMat.baseColor = .init(tint: UIColor(red: 0.15, green: 0.05, blue: 0.2, alpha: 1))
        stageMat.roughness = .init(floatLiteral: 0.3)
        stageMat.metallic = .init(floatLiteral: 0.5)
        let stage = ModelEntity(mesh: stageMesh, materials: [stageMat])
        stage.position = [0, -1.1, -3]
        content.add(stage)

        // Spotlights from above
        let spotColors: [UIColor] = [.init(red: 1, green: 0.3, blue: 0.1, alpha: 1),
                                      .init(red: 0.3, green: 0.5, blue: 1, alpha: 1),
                                      .init(red: 1, green: 0.9, blue: 0.2, alpha: 1)]
        for (i, color) in spotColors.enumerated() {
            let spot = SpotLight()
            spot.light.color = color
            spot.light.intensity = 30_000
            spot.light.attenuationRadius = 8
            spot.light.innerAngleInDegrees = 8
            spot.light.outerAngleInDegrees = 25
            let e = Entity()
            e.components.set(spot)
            e.position = [Float(i - 1) * 2.0, 4.0, -1.5]
            e.look(at: [Float(i - 1) * 0.5, 0, -3], from: e.position, relativeTo: nil)
            content.add(e)
        }

        // Waveform-like floating particles
        addParticleField(count: 150, spread: SIMD3(4, 2, 2),
                         color: .init(red: 1, green: 0.6, blue: 0.1, alpha: 0.4), size: 0.008, in: content)
    }

    // MARK: - Helpers

    private func addColorWash(color: Color, in content: RealityViewContent) {
        let uiColor = UIColor(color).withAlphaComponent(0.15)
        let washLight = PointLight()
        washLight.light.color = uiColor
        washLight.light.intensity = 500
        washLight.light.attenuationRadius = 10
        let e = Entity()
        e.components.set(washLight)
        e.position = [0, 2, -2]
        content.add(e)
    }

    /// Scatter small glowing spheres as a simple particle stand-in.
    private func addParticleField(count: Int, spread: SIMD3<Float>,
                                  color: UIColor, size: Float,
                                  in content: RealityViewContent) {
        let mesh = MeshResource.generateSphere(radius: size)
        var mat = UnlitMaterial(color: color)
        for _ in 0..<count {
            let e = ModelEntity(mesh: mesh, materials: [mat])
            e.position = SIMD3(
                Float.random(in: -spread.x...spread.x),
                Float.random(in: 0...spread.y),
                Float.random(in: -spread.z...0)
            )
            content.add(e)
        }
    }
}

// MARK: - HUD overlay (always-visible glass panel)

struct ConsumingHUD: View {
    let item: MediaItem
    let totalItems: Int
    let currentIndex: Int
    let onNext: () -> Void
    let onPrev: () -> Void
    let onMarkComplete: () -> Void
    let onDismiss: () -> Void

    @State private var expanded = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 12) {
                    // Collapse/expand
                    Button(action: { withAnimation { expanded.toggle() } }) {
                        Image(systemName: expanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)

                    if expanded {
                        VStack(alignment: .trailing, spacing: 8) {
                            HStack(spacing: 8) {
                                Text(item.type.emoji)
                                    .font(.title2)
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(item.title)
                                        .font(.headline)
                                    if !item.creator.isEmpty {
                                        Text(item.creator)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }

                            if !item.progress.isEmpty {
                                Label(item.progress, systemImage: "bookmark")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 8) {
                                if totalItems > 1 {
                                    Button(action: onPrev) {
                                        Image(systemName: "chevron.left")
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(currentIndex == 0)

                                    Text("\(currentIndex + 1) / \(totalItems)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Button(action: onNext) {
                                        Image(systemName: "chevron.right")
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(currentIndex == totalItems - 1)
                                }

                                Button("Done!", action: onMarkComplete)
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                    .controlSize(.small)

                                Button(action: onDismiss) {
                                    Image(systemName: "xmark")
                                }
                                .buttonStyle(.bordered)
                                .tint(.secondary)
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(16)
                .glassBackgroundEffect()
                .padding(.trailing, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
