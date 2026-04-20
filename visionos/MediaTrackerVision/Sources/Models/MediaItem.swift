import Foundation
import SwiftUI

// MARK: - Enums

enum MediaType: String, Codable, CaseIterable, Identifiable {
    case movie, tv, book, podcast, game, music, anime, comic

    var id: String { rawValue }

    var label: String {
        switch self {
        case .movie:   return "Movie"
        case .tv:      return "TV Show"
        case .book:    return "Book"
        case .podcast: return "Podcast"
        case .game:    return "Video Game"
        case .music:   return "Music"
        case .anime:   return "Anime"
        case .comic:   return "Comic/Manga"
        }
    }

    var emoji: String {
        switch self {
        case .movie:   return "🎬"
        case .tv:      return "📺"
        case .book:    return "📖"
        case .podcast: return "🎙️"
        case .game:    return "🎮"
        case .music:   return "🎵"
        case .anime:   return "✨"
        case .comic:   return "💬"
        }
    }

    var creatorLabel: String {
        switch self {
        case .movie:   return "Director"
        case .tv:      return "Creator"
        case .book:    return "Author"
        case .podcast: return "Host"
        case .game:    return "Developer"
        case .music:   return "Artist"
        case .anime:   return "Studio"
        case .comic:   return "Author"
        }
    }

    var accentColor: Color {
        switch self {
        case .movie:   return .red
        case .tv:      return .blue
        case .book:    return Color(red: 0.9, green: 0.6, blue: 0.1)
        case .podcast: return .purple
        case .game:    return .green
        case .music:   return .pink
        case .anime:   return .cyan
        case .comic:   return .orange
        }
    }

    /// Theme for the immersive consuming space
    var immersiveTheme: ImmersiveTheme {
        switch self {
        case .movie, .tv, .anime: return .cinema
        case .book, .comic:       return .library
        case .game:               return .arcade
        case .music, .podcast:    return .concert
        }
    }
}

enum MediaStatus: String, Codable, CaseIterable, Identifiable {
    case backlog
    case inProgress = "in_progress"
    case completed
    case dropped
    case onHold = "on_hold"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .backlog:    return "Backlog"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .dropped:    return "Dropped"
        case .onHold:     return "On Hold"
        }
    }

    var color: Color {
        switch self {
        case .backlog:    return .gray
        case .inProgress: return .blue
        case .completed:  return .green
        case .dropped:    return .red
        case .onHold:     return .yellow
        }
    }
}

enum ImmersiveTheme: String {
    case cinema, library, arcade, concert
}

// MARK: - MediaItem

struct MediaItem: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var type: MediaType
    var status: MediaStatus
    var rating: Int?           // 1-5
    var notes: String
    var genre: String
    var creator: String
    var year: Int?
    var progress: String
    var totalLength: String
    var coverUrl: String
    var tags: [String]
    var dateAdded: Date
    var dateStarted: Date?
    var dateCompleted: Date?
    var isFavorite: Bool
    var playCount: Int

    // visionOS-specific: world anchor ID for room-pinned lists
    var worldAnchorID: String?

    init(
        id: String = UUID().uuidString,
        title: String,
        type: MediaType,
        status: MediaStatus = .backlog,
        rating: Int? = nil,
        notes: String = "",
        genre: String = "",
        creator: String = "",
        year: Int? = nil,
        progress: String = "",
        totalLength: String = "",
        coverUrl: String = "",
        tags: [String] = [],
        dateAdded: Date = .now,
        dateStarted: Date? = nil,
        dateCompleted: Date? = nil,
        isFavorite: Bool = false,
        playCount: Int = 1,
        worldAnchorID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.status = status
        self.rating = rating
        self.notes = notes
        self.genre = genre
        self.creator = creator
        self.year = year
        self.progress = progress
        self.totalLength = totalLength
        self.coverUrl = coverUrl
        self.tags = tags
        self.dateAdded = dateAdded
        self.dateStarted = dateStarted
        self.dateCompleted = dateCompleted
        self.isFavorite = isFavorite
        self.playCount = playCount
        self.worldAnchorID = worldAnchorID
    }
}

// MARK: - Sample Data

extension MediaItem {
    static let samples: [MediaItem] = [
        MediaItem(title: "Dune", type: .book, status: .completed, rating: 5,
                  notes: "Absolute masterpiece of science fiction.", genre: "Science Fiction",
                  creator: "Frank Herbert", year: 1965, progress: "Finished", totalLength: "688 pages",
                  tags: ["classic", "sci-fi", "epic"], dateCompleted: .now, isFavorite: true),
        MediaItem(title: "The Last of Us", type: .game, status: .completed, rating: 5,
                  notes: "Best narrative in gaming.", genre: "Action-Adventure",
                  creator: "Naughty Dog", year: 2013, progress: "100%", totalLength: "~15 hours",
                  tags: ["story-rich", "emotional"], dateCompleted: .now, isFavorite: true),
        MediaItem(title: "Inception", type: .movie, status: .completed, rating: 4,
                  genre: "Sci-Fi / Thriller", creator: "Christopher Nolan", year: 2010,
                  progress: "Watched", totalLength: "148 min", tags: ["mind-bending"]),
        MediaItem(title: "Breaking Bad", type: .tv, status: .completed, rating: 5,
                  genre: "Drama", creator: "Vince Gilligan", year: 2008,
                  totalLength: "5 seasons", tags: ["drama", "crime"], isFavorite: true),
        MediaItem(title: "Lex Fridman Podcast", type: .podcast, status: .inProgress,
                  rating: 4, genre: "Technology", creator: "Lex Fridman", year: 2018,
                  progress: "Ep. 320", totalLength: "400+ episodes", tags: ["tech", "ai"]),
        MediaItem(title: "Hollow Knight", type: .game, status: .inProgress,
                  genre: "Metroidvania", creator: "Team Cherry", year: 2017,
                  progress: "40%", totalLength: "~40 hours", tags: ["indie", "difficult"]),
        MediaItem(title: "Neuromancer", type: .book, status: .backlog,
                  genre: "Cyberpunk", creator: "William Gibson", year: 1984,
                  totalLength: "271 pages", tags: ["cyberpunk", "classic"]),
        MediaItem(title: "Attack on Titan", type: .anime, status: .completed, rating: 5,
                  genre: "Action / Dark Fantasy", creator: "MAPPA", year: 2013,
                  progress: "Finished", totalLength: "87 episodes",
                  tags: ["action", "dark", "epic"], isFavorite: true),
    ]
}
