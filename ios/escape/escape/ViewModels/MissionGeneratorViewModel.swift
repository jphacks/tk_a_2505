//
//  MissionGeneratorViewModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class MissionGeneratorViewModel {
    var generatedMission: Mission?
    var errorMessage: String?
    var isGenerating = false

    // MARK: - Dependencies

    private let missionGenerator: MissionGenerator

    // MARK: - Initialization

    init(missionGenerator: MissionGenerator = MissionGenerator()) {
        self.missionGenerator = missionGenerator
    }

    func generateMission(
        context: String? = nil,
        disasterTypeHint: DisasterType? = nil
    ) async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            let mission = try await missionGenerator.generateMission(
                context: context,
                disasterTypeHint: disasterTypeHint
            )

            generatedMission = mission

            debugPrint("✅ Mission generated successfully")
            debugPrint("📝 Title: \(mission.title ?? "No title")")
            debugPrint("📝 Disaster Type: \(mission.disasterType?.rawValue ?? "None")")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("❌ Mission generation error: \(error)")
        }
    }

    func generateMissionForDisasterType(_ disasterType: DisasterType) async {
        await generateMission(disasterTypeHint: disasterType)
    }

    func generateRandomMission() async {
        await generateMission()
    }

    func generateMissionWithContext(_ context: String) async {
        await generateMission(context: context)
    }

    func reset() {
        generatedMission = nil
        errorMessage = nil
    }
}
