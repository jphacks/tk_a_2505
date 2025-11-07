//
//  PointModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/11.
//

import Foundation

struct Point: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    let point: Int64?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case point
        case createdAt = "created_at"
    }
}

// MARK: - Helper Extensions

extension Point {
    /// Returns the point value or 0 if nil
    var pointValue: Int64 {
        point ?? 0
    }

    /// Returns true if the point has a positive value
    var isPositive: Bool {
        (point ?? 0) > 0
    }

    /// Returns true if the point has a negative value
    var isNegative: Bool {
        (point ?? 0) < 0
    }

    /// Returns formatted point string with sign
    var formattedPoints: String {
        let value = point ?? 0
        if value > 0 {
            return "+\(value)"
        } else {
            return "\(value)"
        }
    }
}

// MARK: - Ranking Models

struct RankingEntry: Identifiable, Equatable {
    let id: UUID
    let rank: Int
    let userId: UUID
    let userName: String?
    let totalPoints: Int64
    let profileBadgeImageUrl: String?

    var displayName: String {
        userName ?? "Anonymous User"
    }

    var formattedPoints: String {
        NumberFormatter.localizedString(from: NSNumber(value: totalPoints), number: .decimal)
    }
}
