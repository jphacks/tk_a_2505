//
//  MissionResultModel.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import Foundation

/// Represents a mission result record from the database
struct MissionResult: Codable, Identifiable, Equatable {
    let id: Int64
    let missionId: UUID
    let userId: UUID
    let steps: Int64?
    let distances: Double?
    let shelterId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case missionId = "mission_id"
        case userId = "user_id"
        case steps
        case distances
        case shelterId = "shelter_id"
        case createdAt = "created_at"
    }
}
