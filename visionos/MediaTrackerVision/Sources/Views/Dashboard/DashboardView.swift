import SwiftUI

struct DashboardView: View {
    @Environment(MediaStore.self) private var store

    var avgRating: Double {
        let rated = store.items.compactMap(\.rating)
        guard !rated.isEmpty else { return 0 }
        return Double(rated.reduce(0, +)) / Double(rated.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Stat cards
                Text("Overview")
                    .font(.title2.bold())

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
                    StatCard(title: "Total", value: "\(store.items.count)",
                             systemImage: "books.vertical", color: .indigo)
                    StatCard(title: "Completed", value: "\(store.completed.count)",
                             systemImage: "checkmark.circle.fill", color: .green)
                    StatCard(title: "In Progress", value: "\(store.inProgress.count)",
                             systemImage: "clock.fill", color: .blue)
                    StatCard(title: "Backlog", value: "\(store.backlog.count)",
                             systemImage: "tray.full", color: .gray)
                    StatCard(title: "Favorites", value: "\(store.favorites.count)",
                             systemImage: "heart.fill", color: .red)
                    StatCard(title: "Avg Rating", value: avgRating > 0 ? String(format: "%.1f", avgRating) : "—",
                             systemImage: "star.fill", color: .yellow)
                }

                // MARK: Type breakdown
                Text("By Type")
                    .font(.title2.bold())

                VStack(spacing: 10) {
                    ForEach(MediaType.allCases) { type in
                        let total = store.items(for: type).count
                        guard total > 0 else { return AnyView(EmptyView()) }
                        let done = store.items(for: type).filter { $0.status == .completed }.count
                        let maxCount = MediaType.allCases.map { store.items(for: $0).count }.max() ?? 1
                        return AnyView(
                            HStack(spacing: 12) {
                                Text(type.emoji).font(.title3)
                                Text(type.label)
                                    .font(.subheadline)
                                    .frame(width: 100, alignment: .leading)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(.secondary.opacity(0.15)).frame(height: 8)
                                        Capsule()
                                            .fill(type.accentColor)
                                            .frame(width: geo.size.width * CGFloat(total) / CGFloat(maxCount),
                                                   height: 8)
                                    }
                                }
                                .frame(height: 8)
                                Text("\(done)/\(total)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                        )
                    }
                }
                .padding(16)
                .background(.regularMaterial)
                .clipShape(.rect(cornerRadius: 14))

                // MARK: Currently consuming
                if !store.inProgress.isEmpty {
                    Text("Currently Consuming")
                        .font(.title2.bold())

                    VStack(spacing: 8) {
                        ForEach(store.inProgress) { item in
                            HStack(spacing: 12) {
                                Text(item.type.emoji).font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title).font(.headline).lineLimit(1)
                                    if !item.creator.isEmpty {
                                        Text(item.creator).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if !item.progress.isEmpty {
                                    Text(item.progress)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.08))
                            .clipShape(.rect(cornerRadius: 12))
                        }
                    }
                }

                // MARK: Recently completed
                let recent = store.completed
                    .sorted { ($0.dateCompleted ?? .distantPast) > ($1.dateCompleted ?? .distantPast) }
                    .prefix(6)

                if !recent.isEmpty {
                    Text("Recently Completed")
                        .font(.title2.bold())

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 10) {
                        ForEach(Array(recent)) { item in
                            HStack(spacing: 10) {
                                Text(item.type.emoji).font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title).font(.subheadline.bold()).lineLimit(1)
                                    if let r = item.rating { StarDisplay(rating: r) }
                                    if let d = item.dateCompleted {
                                        Text(d.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(.regularMaterial)
                            .clipShape(.rect(cornerRadius: 12))
                        }
                    }
                }

                // MARK: Top rated
                let topRated = store.items
                    .filter { $0.rating != nil }
                    .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
                    .prefix(5)

                if !topRated.isEmpty {
                    Text("Top Rated")
                        .font(.title2.bold())

                    VStack(spacing: 6) {
                        ForEach(Array(topRated)) { item in
                            HStack(spacing: 12) {
                                Text(item.type.emoji).font(.title2)
                                Text(item.title).font(.subheadline).lineLimit(1)
                                Spacer()
                                if let r = item.rating { StarDisplay(rating: r) }
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                    .padding(16)
                    .background(.regularMaterial)
                    .clipShape(.rect(cornerRadius: 14))
                }
            }
            .padding(24)
        }
        .navigationTitle("Dashboard")
    }
}
