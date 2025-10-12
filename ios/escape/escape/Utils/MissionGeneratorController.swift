//
//  MissionGeneratorController.swift
//  escape
//
//  Created for mission generation management
//

import Foundation
import SwiftUI

@MainActor
@Observable
class MissionGeneratorController {
    var generatedMission: Mission?
    var errorMessage: String?
    var isGenerating = false

    private let missionGenerator = MissionGenerator()

    func generateMission(
        context: String? = nil,
        disasterTypeHint: DisasterType? = nil,
        steps: Int64? = nil,
        distances: Double? = nil
    ) async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            let mission = try await missionGenerator.generateMission(
                context: context,
                disasterTypeHint: disasterTypeHint,
                steps: steps,
                distances: distances
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

    func generateMissionWithActivityData(
        context: String,
        steps: Int64,
        distances: Double
    ) async {
        await generateMission(
            context: context,
            steps: steps,
            distances: distances
        )
    }

    func reset() {
        generatedMission = nil
        errorMessage = nil
    }
}
