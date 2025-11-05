//
//  MissionStateService.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import SwiftUI

/// Global state manager for mission-related data
/// Use via @Environment(\.missionStateService) in SwiftUI views

class MissionStateService {
    /// Current mission data
    var currentMission: Mission?

    /// Current state of today's mission
    var currentMissionState: MissionState {
        currentMission?.status ?? .noMission
    }

    /// Current game mode
    var currentGameMode: GameMode = .default

    /// Singleton instance for non-SwiftUI contexts
    static let shared = MissionStateService()

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
            status: newState,
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
        currentGameMode = .default
    }

    /// Updates the current game mode
    func updateGameMode(_ mode: GameMode) {
        currentGameMode = mode
    }

    /// Get mission title
    var missionTitle: String? {
        currentMission?.title
    }

    /// Get mission overview
    var missionOverview: String? {
        currentMission?.overview
    }
}

// MARK: - Environment Key

private struct MissionStateServiceKey: EnvironmentKey {
    static let defaultValue = MissionStateService.shared
}

extension EnvironmentValues {
    var missionStateService: MissionStateService {
        get { self[MissionStateServiceKey.self] }
        set { self[MissionStateServiceKey.self] = newValue }
    }
}
