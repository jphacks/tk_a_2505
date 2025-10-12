//
//  MissionManager.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import Foundation
import SwiftUI

/// Global state manager for mission-related data
/// Use via @Environment(\.missionStateManager) in SwiftUI views
@Observable
class MissionStateManager {
    /// Current mission data
    var currentMission: Mission?

    /// Current state of today's mission
    var currentMissionState: MissionState {
        currentMission?.status ?? .noMission
    }

    /// Singleton instance for non-SwiftUI contexts
    static let shared = MissionStateManager()

    init() {}

    // MARK: - Mission State Management

    /// Updates the current mission with new mission data
    func updateMission(_ mission: Mission) {
        currentMission = mission
    }

    /// Updates only the mission state
    func updateMissionState(_ newState: MissionState) {
        guard let mission = currentMission else {
            // If no mission exists, we can't just update the state
            print("Warning: Attempting to update state without a mission")
            return
        }

        // Create a new mission with updated status
        currentMission = Mission(
            id: mission.id,
            userId: mission.userId,
            title: mission.title,
            overview: mission.overview,
            disasterType: mission.disasterType,
            evacuationRegion: mission.evacuationRegion,
            status: newState,
            steps: mission.steps,
            distances: mission.distances,
            createdAt: mission.createdAt
        )
    }

    /// Updates the current mission
    func updateCurrentMission(_ mission: Mission?) {
        currentMission = mission
    }

    /// Resets mission state to default
    func resetMission() {
        currentMission = nil
    }

    /// Get mission title
    var missionTitle: String? {
        currentMission?.title
    }

    /// Get mission overview
    var missionOverview: String? {
        currentMission?.overview
    }

    /// Get mission steps
    var missionSteps: Int64? {
        currentMission?.steps
    }

    /// Get mission distance
    var missionDistance: Double? {
        currentMission?.distances
    }
}

// MARK: - Environment Key

private struct MissionStateManagerKey: EnvironmentKey {
    static let defaultValue = MissionStateManager.shared
}

extension EnvironmentValues {
    var missionStateManager: MissionStateManager {
        get { self[MissionStateManagerKey.self] }
        set { self[MissionStateManagerKey.self] = newValue }
    }
}
