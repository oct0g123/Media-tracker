import SwiftUI

/// Library view where eye gaze drives the experience:
///
/// - Looking at a card expands it via `.hoverEffect` (visionOS routes eye gaze through the hover system)
/// - Dwelling on a card for ~0.8 s opens a floating detail panel via `accessibilityFocused` + a timer
/// - Pinching selects for edit/status change
/// - `.scrollTargetBehavior(.paging)` makes rows snap so each gaze-look lands cleanly
struct EyeTrackLibraryView: View {
    @Environment(MediaStore.self) private var store
    let filterType: MediaType?

    @State private var search = ""
    @State private var statusFilter: MediaStatus? = nil
    @State private var sortField: SortField = .dateAdded
    @State private var selectedItem: MediaItem?
    @State private var hoveredItemID: String?
    @State private var dwellItemID: String?
    @State private var dwellTask: Task<Void, Never>?
    @State private var showAdd = false

    enum SortField: String, CaseIterable {
        case dateAdded = "Date Added"
        case title = "Title"
        case rating = "Rating"
        case status = "Status"
    }

    private var displayItems: [MediaItem] {
        var result = store.items

        if let type = filterType {
            result = result.filter { $0.type == type }
        }
        if let status = statusFilter {
            result = result.filter { $0.status == status }
        }
        if !search.isEmpty {
            let q = search.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(q) ||
                $0.creator.lowercased().contains(q) ||
                $0.tags.contains(where: { $0.contains(q) })
            }
        }

        switch sortField {
        case .dateAdded: result.sort { $0.dateAdded > $1.dateAdded }
        case .title:     result.sort { $0.title < $1.title }
        case .rating:    result.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
        case .status:    result.sort { $0.status.rawValue < $1.status.rawValue }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 260, maximum: 340), spacing: 16)],
                        spacing: 16
                    ) {
                        ForEach(displayItems) { item in
                            EyeTrackCard(
                                item: item,
                                isHovered: hoveredItemID == item.id,
                                isDwelling: dwellItemID == item.id,
                                onHoverChanged: { hovering in
                                    handleHover(item: item, hovering: hovering)
                                },
                                onTap: {
                                    selectedItem = item
                                },
                                onStatusChange: { status in
                                    store.setStatus(item.id, status: status)
                                }
                            )
                        }
                    }
                    .padding(20)
                }

                // Floating gaze-detail panel
                if let item = dwellItemID.flatMap({ id in displayItems.first(where: { $0.id == id }) }) {
                    GazeDetailPanel(item: item, onDismiss: { dwellItemID = nil }, store: store)
                        .transition(.asymmetric(insertion: .scale(scale: 0.8).combined(with: .opacity),
                                                removal: .opacity))
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: dwellItemID)
                }
            }
            .navigationTitle(filterType?.label ?? "Library")
            .searchable(text: $search, prompt: "Search by title, creator, tag…")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Picker("Status", selection: $statusFilter) {
                            Text("All").tag(MediaStatus?.none)
                            ForEach(MediaStatus.allCases) { s in
                                Text(s.label).tag(Optional(s))
                            }
                        }
                        Divider()
                        Picker("Sort", selection: $sortField) {
                            ForEach(SortField.allCases, id: \.self) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(item: $selectedItem) { item in
                MediaFormView(item: item)
                    .environment(store)
            }
            .sheet(isPresented: $showAdd) {
                MediaFormView(item: nil)
                    .environment(store)
            }
        }
    }

    // MARK: - Gaze dwell logic

    private func handleHover(item: MediaItem, hovering: Bool) {
        if hovering {
            hoveredItemID = item.id
            // Start dwell timer — open detail panel after 0.8s of looking
            dwellTask?.cancel()
            dwellTask = Task {
                try? await Task.sleep(for: .milliseconds(800))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation { dwellItemID = item.id }
                }
            }
        } else {
            if hoveredItemID == item.id { hoveredItemID = nil }
            dwellTask?.cancel()
            dwellTask = nil
        }
    }
}

// MARK: - Eye-track card

struct EyeTrackCard: View {
    let item: MediaItem
    let isHovered: Bool
    let isDwelling: Bool
    let onHoverChanged: (Bool) -> Void
    let onTap: () -> Void
    let onStatusChange: (MediaStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover area
            ZStack(alignment: .bottomLeading) {
                coverBackground
                    .frame(height: isHovered ? 160 : 120)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
                    .clipped()

                // Floating type pill
                Text(item.type.emoji + " " + item.type.label)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(.capsule)
                    .padding(8)
            }

            // Info area — expands on hover
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.headline)
                            .lineLimit(2)
                        if !item.creator.isEmpty {
                            Text(item.creator)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                HStack(spacing: 6) {
                    StatusPill(status: item.status)
                    if let r = item.rating { StarDisplay(rating: r) }
                }

                // Extra info revealed on hover
                if isHovered {
                    VStack(alignment: .leading, spacing: 4) {
                        if !item.progress.isEmpty {
                            Label(item.progress, systemImage: "bookmark.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Quick status picker
                        Picker("Status", selection: Binding(
                            get: { item.status },
                            set: { onStatusChange($0) }
                        )) {
                            ForEach(MediaStatus.allCases) { s in
                                Text(s.label).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                        .controlSize(.mini)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 16))
        // visionOS: .hoverEffect() responds to eye gaze automatically
        .hoverEffect(.highlight)
        .onHover(perform: onHoverChanged)
        .onTapGesture(perform: onTap)
        // Subtle scale-up when gaze lands
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .shadow(color: isHovered ? item.type.accentColor.opacity(0.4) : .clear,
                radius: isHovered ? 20 : 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        // Dwell indicator ring
        .overlay(alignment: .topTrailing) {
            if isDwelling {
                Image(systemName: "eye.fill")
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(item.type.accentColor)
                    .clipShape(.circle)
                    .padding(6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private var coverBackground: some View {
        if let url = URL(string: item.coverUrl), !item.coverUrl.isEmpty {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                typePlaceholder
            }
        } else {
            typePlaceholder
        }
    }

    private var typePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [item.type.accentColor.opacity(0.3), item.type.accentColor.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(item.type.emoji)
                .font(.system(size: 44))
        }
    }
}

// MARK: - Gaze dwell detail panel (floats above hovered card)

struct GazeDetailPanel: View {
    let item: MediaItem
    let onDismiss: () -> Void
    let store: MediaStore

    @State private var showEdit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.type.emoji + " " + item.title)
                    .font(.title3.bold())
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if !item.creator.isEmpty || item.year != nil {
                HStack(spacing: 8) {
                    if !item.creator.isEmpty { Text(item.creator) }
                    if let y = item.year { Text("(\(y))") }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                StatusPill(status: item.status)
                if let r = item.rating { StarDisplay(rating: r) }
                if item.isFavorite {
                    Image(systemName: "heart.fill").foregroundStyle(.red).font(.caption)
                }
            }

            if !item.genre.isEmpty {
                Text(item.genre)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !item.progress.isEmpty {
                HStack {
                    Label(item.progress, systemImage: "bookmark")
                    if !item.totalLength.isEmpty { Text("/ \(item.totalLength)") }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if !item.notes.isEmpty {
                Text(item.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            if !item.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.quaternary)
                                .clipShape(.capsule)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Button("Edit") { showEdit = true }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                Button("Mark Complete") {
                    store.setStatus(item.id, status: .completed)
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(item.status == .completed)
            }
        }
        .padding(20)
        .frame(width: 320)
        .glassBackgroundEffect()
        .sheet(isPresented: $showEdit) {
            MediaFormView(item: item)
                .environment(store)
        }
    }
}
