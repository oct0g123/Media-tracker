import SwiftUI

enum NavTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case library   = "Library"
    case shelf     = "Shelf"
}

struct ContentView: View {
    @Environment(MediaStore.self) private var store
    @State private var tab: NavTab = .dashboard
    @State private var showAdd = false
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var immersiveOpen = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .sheet(isPresented: $showAdd) {
            MediaFormView(item: nil)
                .environment(store)
        }
        // Show immersive consuming space when a new in-progress item is set
        .onChange(of: store.immersiveItem) { _, newItem in
            Task {
                if newItem != nil && !immersiveOpen {
                    immersiveOpen = true
                    await openImmersiveSpace(id: "consuming-space")
                } else if newItem == nil && immersiveOpen {
                    immersiveOpen = false
                    await dismissImmersiveSpace()
                }
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $tab) {
            Section("Navigate") {
                ForEach(NavTab.allCases, id: \.self) { t in
                    Label(t.rawValue, systemImage: icon(for: t))
                        .tag(t)
                }
            }

            Section("Media Types") {
                ForEach(MediaType.allCases) { type in
                    NavigationLink {
                        EyeTrackLibraryView(filterType: type)
                            .environment(store)
                    } label: {
                        HStack {
                            Text(type.emoji)
                            Text(type.label)
                            Spacer()
                            Text("\(store.items(for: type).count)")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }

            Section("Spaces") {
                Button {
                    openWindow(id: "spatial-shelf")
                } label: {
                    Label("Open 3D Shelf", systemImage: "cube.transparent")
                }

                Button {
                    openImmersiveSpaceForInProgress()
                } label: {
                    Label("Now Consuming", systemImage: "sparkles")
                }
                .disabled(store.inProgress.isEmpty)

                NavigationLink {
                    RoomAnchorManagerView()
                        .environment(store)
                } label: {
                    Label("Room Lists", systemImage: "mappin.and.ellipse")
                }
            }
        }
        .navigationTitle("MediaTracker")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        switch tab {
        case .dashboard:
            DashboardView()
                .environment(store)
        case .library:
            EyeTrackLibraryView(filterType: nil)
                .environment(store)
        case .shelf:
            // Redirect to volumetric window
            VStack(spacing: 16) {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Open the 3D shelf in its own window")
                    .font(.title2)
                Button("Open 3D Shelf") {
                    openWindow(id: "spatial-shelf")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func icon(for tab: NavTab) -> String {
        switch tab {
        case .dashboard: return "chart.bar"
        case .library:   return "books.vertical"
        case .shelf:     return "cube.transparent"
        }
    }

    private func openImmersiveSpaceForInProgress() {
        guard let item = store.inProgress.first else { return }
        store.immersiveItem = item
    }
}
