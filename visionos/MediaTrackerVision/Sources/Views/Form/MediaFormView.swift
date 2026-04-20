import SwiftUI

/// Add / Edit sheet for a media item.
struct MediaFormView: View {
    @Environment(MediaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let item: MediaItem?

    // Form state
    @State private var title = ""
    @State private var type: MediaType = .movie
    @State private var status: MediaStatus = .backlog
    @State private var rating: Int? = nil
    @State private var creator = ""
    @State private var year = ""
    @State private var genre = ""
    @State private var progress = ""
    @State private var totalLength = ""
    @State private var coverUrl = ""
    @State private var notes = ""
    @State private var tagText = ""
    @State private var tags: [String] = []
    @State private var isFavorite = false
    @State private var playCount = 1
    @State private var dateStarted: Date? = nil
    @State private var dateCompleted: Date? = nil
    @State private var hasStarted = false
    @State private var hasCompleted = false

    init(item: MediaItem?) {
        self.item = item
    }

    var body: some View {
        NavigationStack {
            Form {
                // Media type picker
                Section("Media Type") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MediaType.allCases) { t in
                                Button {
                                    type = t
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(t.emoji).font(.title2)
                                        Text(t.label).font(.caption2)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(type == t ? t.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(type == t ? t.accentColor : Color.clear, lineWidth: 1.5)
                                    )
                                    .clipShape(.rect(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Details") {
                    TextField("Title *", text: $title)
                    TextField(type.creatorLabel, text: $creator)
                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)
                    TextField("Genre", text: $genre)
                }

                Section("Status & Progress") {
                    Picker("Status", selection: $status) {
                        ForEach(MediaStatus.allCases) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .onChange(of: status) { _, newStatus in
                        if newStatus == .inProgress && !hasStarted {
                            hasStarted = true
                            dateStarted = .now
                        }
                        if newStatus == .completed && !hasCompleted {
                            hasCompleted = true
                            dateCompleted = .now
                        }
                    }

                    TextField("Progress (e.g. p.142, Ep 5, 40%)", text: $progress)
                    TextField("Total Length (e.g. 300 pages, 24 eps)", text: $totalLength)

                    Stepper("Times Consumed: \(playCount)", value: $playCount, in: 0...99)
                }

                Section("Rating") {
                    HStack {
                        Text("Your rating")
                        Spacer()
                        StarRatingPicker(rating: $rating)
                    }
                }

                Section("Dates") {
                    Toggle("Started", isOn: $hasStarted)
                    if hasStarted {
                        DatePicker("Start Date",
                                   selection: Binding(get: { dateStarted ?? .now }, set: { dateStarted = $0 }),
                                   displayedComponents: .date)
                    }
                    Toggle("Completed", isOn: $hasCompleted)
                    if hasCompleted {
                        DatePicker("Complete Date",
                                   selection: Binding(get: { dateCompleted ?? .now }, set: { dateCompleted = $0 }),
                                   displayedComponents: .date)
                    }
                }

                Section("Tags") {
                    if !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text("#\(tag)").font(.caption)
                                        Button {
                                            tags.removeAll { $0 == tag }
                                        } label: {
                                            Image(systemName: "xmark").font(.caption2)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.secondary.opacity(0.15))
                                    .clipShape(.capsule)
                                }
                            }
                        }
                    }
                    HStack {
                        TextField("Add tag…", text: $tagText)
                        Button("Add") { addTag() }
                            .disabled(tagText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("Cover & Notes") {
                    TextField("Cover Image URL", text: $coverUrl)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(4...8)
                }

                Section {
                    Toggle("Favorite ❤️", isOn: $isFavorite)
                }
            }
            .navigationTitle(item == nil ? "Add Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { populateFromItem() }
        }
    }

    // MARK: - Helpers

    private func addTag() {
        let tag = tagText.trimmingCharacters(in: .whitespaces)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
        guard !tag.isEmpty, !tags.contains(tag) else { return }
        tags.append(tag)
        tagText = ""
    }

    private func populateFromItem() {
        guard let item else { return }
        title = item.title
        type = item.type
        status = item.status
        rating = item.rating
        creator = item.creator
        year = item.year.map { String($0) } ?? ""
        genre = item.genre
        progress = item.progress
        totalLength = item.totalLength
        coverUrl = item.coverUrl
        notes = item.notes
        tags = item.tags
        isFavorite = item.isFavorite
        playCount = item.playCount
        hasStarted = item.dateStarted != nil
        dateStarted = item.dateStarted
        hasCompleted = item.dateCompleted != nil
        dateCompleted = item.dateCompleted
    }

    private func save() {
        var updated = item ?? MediaItem(
            title: title, type: type, status: status,
            rating: rating, notes: notes, genre: genre,
            creator: creator, year: Int(year),
            progress: progress, totalLength: totalLength,
            coverUrl: coverUrl, tags: tags,
            isFavorite: isFavorite, playCount: playCount,
            worldAnchorID: item?.worldAnchorID
        )
        updated.title = title
        updated.type = type
        updated.status = status
        updated.rating = rating
        updated.creator = creator
        updated.year = Int(year)
        updated.genre = genre
        updated.progress = progress
        updated.totalLength = totalLength
        updated.coverUrl = coverUrl
        updated.notes = notes
        updated.tags = tags
        updated.isFavorite = isFavorite
        updated.playCount = playCount
        updated.dateStarted = hasStarted ? dateStarted : nil
        updated.dateCompleted = hasCompleted ? dateCompleted : nil

        if item != nil {
            store.update(updated)
        } else {
            store.add(updated)
        }
        dismiss()
    }
}
