import SwiftUI

// MARK: - Status pill badge

struct StatusPill: View {
    let status: MediaStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
            Text(status.label)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.15))
        .clipShape(.capsule)
    }
}

// MARK: - Star display (read-only)

struct StarDisplay: View {
    let rating: Int
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { n in
                Image(systemName: n <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(n <= rating ? .yellow : .secondary.opacity(0.4))
            }
        }
    }
}

// MARK: - Star rating (interactive)

struct StarRatingPicker: View {
    @Binding var rating: Int?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { n in
                Image(systemName: filled(n) ? "star.fill" : "star")
                    .font(.system(size: 22))
                    .foregroundStyle(filled(n) ? .yellow : .secondary.opacity(0.4))
                    .onTapGesture {
                        if rating == n { rating = nil } else { rating = n }
                    }
                    .hoverEffect(.highlight)
            }
        }
    }

    private func filled(_ n: Int) -> Bool {
        guard let r = rating else { return false }
        return n <= r
    }
}

// MARK: - Stat card

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)
                .padding(10)
                .background(color.opacity(0.15))
                .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title.bold())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 14))
    }
}
