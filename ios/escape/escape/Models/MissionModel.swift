//
//  MissionModel.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import Foundation

/// Represents the state of today's mission
enum MissionState: String, Codable {
    case noMission = "none"
    case inProgress = "creating"
    case active = "have"
    case completed = "done"
}

/// Represents a mission record from the database
struct Mission: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    let title: String?
    let overview: String?
    let disasterType: DisasterType?
    let evacuationRegion: String?
    let status: MissionState
    let steps: Int64?
    let distances: Double?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case overview
        case disasterType = "disaster_type"
        case evacuationRegion = "evacuation_region"
        case status
        case steps
        case distances
        case createdAt = "created_at"
    }

    // Custom Codable implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)

        // Handle DisasterType decoding safely
        if let disasterTypeString = try container.decodeIfPresent(String.self, forKey: .disasterType) {
            disasterType = DisasterType(rawValue: disasterTypeString)
        } else {
            disasterType = nil
        }

        evacuationRegion = try container.decodeIfPresent(String.self, forKey: .evacuationRegion)
        status = try container.decode(MissionState.self, forKey: .status)
        steps = try container.decodeIfPresent(Int64.self, forKey: .steps)
        distances = try container.decodeIfPresent(Double.self, forKey: .distances)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(overview, forKey: .overview)
        try container.encodeIfPresent(disasterType?.rawValue, forKey: .disasterType)
        try container.encodeIfPresent(evacuationRegion, forKey: .evacuationRegion)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(steps, forKey: .steps)
        try container.encodeIfPresent(distances, forKey: .distances)
        try container.encode(createdAt, forKey: .createdAt)
    }

    // Initializer for programmatic creation
    init(id: UUID, userId: UUID?, title: String?, overview: String?, disasterType: DisasterType?, evacuationRegion: String?, status: MissionState, steps: Int64?, distances: Double?, createdAt: Date) {
        self.id = id
        self.userId = userId
        self.title = title
        self.overview = overview
        self.disasterType = disasterType
        self.evacuationRegion = evacuationRegion
        self.status = status
        self.steps = steps
        self.distances = distances
        self.createdAt = createdAt
    }
}
