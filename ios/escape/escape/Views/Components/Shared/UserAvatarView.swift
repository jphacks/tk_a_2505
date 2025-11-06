//
//  UserAvatarView.swift
//  escape
//
//  A reusable component that displays a user's avatar as their first initial
//  in a circular background. Used across rankings and other list views.
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
    let size: AvatarSize
    let colors: [Color]
    let strokeColor: Color?
    let strokeWidth: CGFloat

    /// Creates a user avatar showing the first letter of the username
    /// - Parameters:
    ///   - username: The user's display name
    ///   - size: The size variant (small, medium, large)
    ///   - colors: Gradient colors for the background (defaults to accent color)
    ///   - strokeColor: Optional border color
    ///   - strokeWidth: Border width (default: 0)
    init(
        username: String,
        size: AvatarSize = .small,
        colors: [Color]? = nil,
        strokeColor: Color? = nil,
        strokeWidth: CGFloat = 0
    ) {
        self.username = username
        self.size = size
        self.colors = colors ?? [Color.accentColor]
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }

    var body: some View {
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
        .overlay(
            Circle()
                .stroke(
                    strokeColor ?? Color.clear,
                    lineWidth: strokeWidth
                )
        )
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
    static func nationalRanking(username: String) -> UserAvatarView {
        UserAvatarView(
            username: username,
            size: .small,
            colors: [Color("brandOrange"), Color("brandRed")]
        )
    }

    /// Creates a small avatar with brand blue gradient (for team rankings)
    static func teamRanking(username: String) -> UserAvatarView {
        UserAvatarView(
            username: username,
            size: .small,
            colors: [Color("brandMediumBlue"), Color("brandOrange")]
        )
    }

    /// Creates a medium avatar with accent color (general purpose)
    static func standard(username: String) -> UserAvatarView {
        UserAvatarView(
            username: username,
            size: .medium
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
