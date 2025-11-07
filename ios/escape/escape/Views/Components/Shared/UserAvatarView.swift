//
//  UserAvatarView.swift
//  escape
//
//  A reusable component that displays a user's avatar.
//  Supports badge image URLs with fallback to username initial.
//  Used across rankings, settings, and profile views.
//

import SwiftUI

/// Defines the size variants for the user avatar
enum AvatarSize {
    case small
    case medium
    case large

    var dimension: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 60
        case .large: return 80
        }
    }

    var font: Font {
        switch self {
        case .small: return .callout
        case .medium: return .title2
        case .large: return .title
        }
    }
}

struct UserAvatarView: View {
    let username: String
    let badgeImageUrl: String?
    let size: AvatarSize
    let colors: [Color]
    let strokeColor: Color?
    let strokeWidth: CGFloat
    let showLoadingIndicator: Bool

    /// Creates a user avatar with optional badge image support
    /// - Parameters:
    ///   - username: The user's display name
    ///   - badgeImageUrl: Optional URL to a badge image (will show initial if nil or fails to load)
    ///   - size: The size variant (small, medium, large)
    ///   - colors: Gradient colors for the background (defaults to accent color)
    ///   - strokeColor: Optional border color
    ///   - strokeWidth: Border width (default: 0)
    ///   - showLoadingIndicator: Whether to show loading spinner during image load (default: true)
    init(
        username: String,
        badgeImageUrl: String? = nil,
        size: AvatarSize = .small,
        colors: [Color]? = nil,
        strokeColor: Color? = nil,
        strokeWidth: CGFloat = 0,
        showLoadingIndicator: Bool = true
    ) {
        self.username = username
        self.badgeImageUrl = badgeImageUrl
        self.size = size
        self.colors = colors ?? [Color.accentColor]
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.showLoadingIndicator = showLoadingIndicator
    }

    var body: some View {
        ZStack {
            if let urlString = badgeImageUrl,
               let url = URL(string: urlString) {
                // Try to load badge image
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        // Loading state
                        loadingView
                    case .success(let image):
                        // Successfully loaded badge image
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.dimension, height: size.dimension)
                            .clipShape(Circle())
                    case .failure:
                        // Failed to load - show initial
                        initialView
                    @unknown default:
                        initialView
                    }
                }
            } else {
                // No badge URL - show initial
                initialView
            }
        }
        .overlay(
            Circle()
                .stroke(
                    strokeColor ?? Color.clear,
                    lineWidth: strokeWidth
                )
        )
    }

    /// Loading view shown while image is being fetched
    private var loadingView: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: size.dimension, height: size.dimension)
            .overlay(
                Group {
                    if showLoadingIndicator {
                        ProgressView()
                    }
                }
            )
    }

    /// Initial letter view - fallback when no image or image fails
    private var initialView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: colors.map { $0.opacity(0.2) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.dimension, height: size.dimension)

            Text(firstLetter)
                .font(size.font)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    /// Extracts the first letter from the username, uppercased
    private var firstLetter: String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "A" // Fallback for Anonymous users
        }
        return String(trimmed.prefix(1)).uppercased()
    }
}

// MARK: - Convenience Initializers

extension UserAvatarView {
    /// Creates a small avatar with brand orange gradient (for national rankings)
    static func nationalRanking(username: String, badgeImageUrl: String? = nil) -> UserAvatarView {
        UserAvatarView(
            username: username,
            badgeImageUrl: badgeImageUrl,
            size: .small,
            colors: [Color("brandOrange"), Color("brandRed")],
            showLoadingIndicator: false // Don't show spinner in rankings
        )
    }

    /// Creates a small avatar with brand blue gradient (for team rankings)
    static func teamRanking(username: String, badgeImageUrl: String? = nil) -> UserAvatarView {
        UserAvatarView(
            username: username,
            badgeImageUrl: badgeImageUrl,
            size: .small,
            colors: [Color("brandMediumBlue"), Color("brandOrange")],
            showLoadingIndicator: false // Don't show spinner in rankings
        )
    }

    /// Creates a medium avatar with accent color (general purpose)
    static func standard(username: String, badgeImageUrl: String? = nil) -> UserAvatarView {
        UserAvatarView(
            username: username,
            badgeImageUrl: badgeImageUrl,
            size: .medium
        )
    }

    /// Creates a profile avatar with accent color and border (for settings/profiles)
    static func profile(username: String, badgeImageUrl: String? = nil, size: AvatarSize = .medium) -> UserAvatarView {
        UserAvatarView(
            username: username,
            badgeImageUrl: badgeImageUrl,
            size: size,
            strokeColor: Color.accentColor,
            strokeWidth: 2
        )
    }
}

// MARK: - Previews

#Preview("Avatar Sizes") {
    VStack(spacing: 20) {
        UserAvatarView(username: "John Doe", size: .small)
        UserAvatarView(username: "Jane Smith", size: .medium)
        UserAvatarView(username: "Bob Wilson", size: .large)
    }
    .padding()
}

#Preview("Avatar Colors") {
    HStack(spacing: 20) {
        UserAvatarView.nationalRanking(username: "Alice")
        UserAvatarView.teamRanking(username: "Bob")
        UserAvatarView.standard(username: "Charlie")
    }
    .padding()
}

#Preview("With Badge Images") {
    VStack(spacing: 20) {
        UserAvatarView(
            username: "Alice",
            badgeImageUrl: "https://example.com/badge1.png",
            size: .medium
        )
        UserAvatarView(
            username: "Bob",
            badgeImageUrl: nil,
            size: .medium
        )
        UserAvatarView.profile(
            username: "Charlie",
            badgeImageUrl: "https://example.com/badge2.png"
        )
    }
    .padding()
}

#Preview("Edge Cases") {
    VStack(spacing: 20) {
        UserAvatarView(username: "")
        UserAvatarView(username: " ")
        UserAvatarView(username: "A")
        UserAvatarView(username: "あ")
        UserAvatarView(username: "Anonymous User")
    }
    .padding()
}
