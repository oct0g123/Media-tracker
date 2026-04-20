import SwiftUI

@main
struct MediaTrackerVisionApp: App {
    @State private var store = MediaStore()

    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .defaultSize(width: 1200, height: 800)

        // Spatial shelf window — ornamental 3D display
        WindowGroup(id: "spatial-shelf") {
            SpatialShelfView()
                .environment(store)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.2, height: 0.8, depth: 0.6, in: .meters)

        // Full immersive space for "now consuming"
        ImmersiveSpace(id: "consuming-space") {
            ImmersiveConsumingView()
                .environment(store)
        }
        .immersionStyle(selection: .constant(.progressive), in: .progressive)

        // Room-anchored list overlay (mixed immersion)
        ImmersiveSpace(id: "room-anchored") {
            RoomAnchoredView()
                .environment(store)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
