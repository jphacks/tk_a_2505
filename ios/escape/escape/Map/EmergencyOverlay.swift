//
//  EmergencyOverlay.swift
//  escape
//
//  Created by Claude Code on 12/10/2568 BE.
//

import SwiftUI

struct EmergencyOverlay: View {
    let disasterType: DisasterType
    let evacuationRegion: String?
    let status: MissionState
    let onTap: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(.regularMaterial)
                    .frame(width: 50, height: 50)
                    .shadow(radius: 4)

                Image(systemName: disasterType.emergencyIcon)
                    .font(.system(size: 24))
                    .foregroundStyle(
                        isPulsing ?
                            LinearGradient(colors: [.orange, severityColor], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [severityColor, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .animation(
                        .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }
        }
        .onAppear {
            isPulsing = true
        }
    }

    // MARK: - Computed Properties

    private var severityColor: Color {
        switch disasterType {
        case .earthquake, .tsunami:
            return Color.red
        case .fire:
            return Color.orange
        case .flood, .inlandFlood:
            return Color.blue
        case .stormSurge, .volcano:
            return Color.purple
        case .landslide:
            return Color.brown
        }
    }

    private var disasterTypeLocalizedString: String {
        switch disasterType {
        case .earthquake:
            return String(localized: "home.disaster.earthquake", bundle: .main)
        case .flood:
            return String(localized: "home.disaster.flood", bundle: .main)
        case .fire:
            return String(localized: "home.disaster.fire", bundle: .main)
        case .stormSurge:
            return String(localized: "home.disaster.storm_surge", bundle: .main)
        case .tsunami:
            return String(localized: "home.disaster.tsunami", bundle: .main)
        case .landslide:
            return String(localized: "home.disaster.landslide", bundle: .main)
        case .inlandFlood:
            return String(localized: "home.disaster.inland_flood", bundle: .main)
        case .volcano:
            return String(localized: "home.disaster.volcano", bundle: .main)
        }
    }

    private var statusLocalizedString: String {
        switch status {
        case .noMission:
            return String(localized: "map.emergency.no_mission", bundle: .main)
        case .inProgress:
            return String(localized: "map.emergency.in_progress", bundle: .main)
        case .active:
            return String(localized: "map.emergency.active_mission", bundle: .main)
        case .completed:
            return String(localized: "map.emergency.completed", bundle: .main)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()

        HStack(spacing: 20) {
            EmergencyOverlay(
                disasterType: .earthquake,
                evacuationRegion: "Shibuya Ward, Tokyo",
                status: .active,
                onTap: { print("Earthquake tapped") }
            )

            EmergencyOverlay(
                disasterType: .tsunami,
                evacuationRegion: nil,
                status: .inProgress,
                onTap: { print("Tsunami tapped") }
            )

            EmergencyOverlay(
                disasterType: .fire,
                evacuationRegion: "Downtown Area",
                status: .active,
                onTap: { print("Fire tapped") }
            )
        }
    }
}
