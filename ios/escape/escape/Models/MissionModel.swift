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
struct Mission: Codable, Identifiable, Equatable {
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
}
