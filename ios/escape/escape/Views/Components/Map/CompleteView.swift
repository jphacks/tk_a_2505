//
//  CompleteView.swift
//  escape
//
//  Created by Claude Code on 12/10/2568 BE.
//

import MapKit
import SwiftUI

struct CompleteView: View {
    let shelter: Shelter
    let missionResult: MissionResult?
    @Environment(\.dismiss) var dismiss
    @Environment(\.missionStateService) var missionStateService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Header
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)

                        Text("mission.complete.title", tableName: "Localizable")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("mission.complete.subtitle", tableName: "Localizable")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Shelter Information Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("mission.complete.shelter_info", tableName: "Localizable")
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 12) {
                            // Shelter Name
                            HStack(spacing: 12) {
                                Image(systemName: shelter.isShelter == true ? "building.2.fill" : "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(shelter.isShelter == true ? Color("brandRed") : Color("brandOrange"))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(shelter.name)
                                        .font(.title3)
                                        .fontWeight(.semibold)

                                    Text(shelter.isShelter == true ?
                                        String(localized: "map.pin_details.hinanjo.subtitle", bundle: .main) :
                                        String(localized: "map.pin_details.hinanbasho.subtitle", bundle: .main))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Divider()

                            // Address
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.secondary)

                                Text(shelter.address)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }

                            // Supported Disasters
                            if !shelter.supportedDisasterTypes.isEmpty {
                                Divider()

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "shield.fill")
                                            .foregroundColor(.secondary)
                                        Text(String(localized: "badge.supported_disasters", bundle: .main))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }

                                    FlowLayout(spacing: 8) {
                                        ForEach(shelter.supportedDisasterTypes, id: \.self) { type in
                                            Text(type)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Mission Stats (if available)
                    if let mission = missionStateService.currentMission {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("mission.complete.mission_summary", tableName: "Localizable")
                                .font(.headline)
                                .fontWeight(.semibold)

                            VStack(spacing: 12) {
                                if let disasterType = mission.disasterType {
                                    HStack {
                                        Image(systemName: disasterType.emergencyIcon)
                                            .foregroundColor(disasterType.color)
                                        Text("mission.complete.disaster_type", tableName: "Localizable")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(disasterType.localizedName)
                                            .fontWeight(.medium)
                                    }
                                }

                                if let result = missionResult {
                                    if let steps = result.steps {
                                        HStack {
                                            Image(systemName: "figure.walk")
                                                .foregroundColor(.orange)
                                            Text("mission.complete.steps", tableName: "Localizable")
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("\(steps)")
                                                .fontWeight(.medium)
                                        }
                                    }

                                    if let distance = result.actualDistanceMeters {
                                        HStack {
                                            Image(systemName: "map")
                                                .foregroundColor(.blue)
                                            Text("mission.complete.distance", tableName: "Localizable")
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text(String(format: "%.2f km", distance / 1000))
                                                .fontWeight(.medium)
                                        }
                                    }

                                    if let points = result.finalPoints {
                                        HStack {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                            Text("mission.complete.points_earned", tableName: "Localizable")
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("\(points)")
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("mission.complete.return_to_map", tableName: "Localizable")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }

                        Button(action: {
                            // TODO: Share or save mission report
                            print("Share mission report")
                        }) {
                            Text("mission.complete.share_results", tableName: "Localizable")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth, currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    CompleteView(
        shelter: Shelter(
            id: "1",
            number: 1,
            commonId: "test",
            name: "Tokyo Community Center",
            address: "1-1-1 Shibuya, Tokyo",
            municipality: "Shibuya",
            isShelter: true,
            isFlood: true,
            isLandslide: false,
            isStormSurge: false,
            isEarthquake: true,
            isTsunami: false,
            isFire: true,
            isInlandFlood: false,
            isVolcano: false,
            isSameAddressAsShelter: false,
            otherMunicipalNotes: nil,
            acceptedPeople: nil,
            latitude: 35.6586,
            longitude: 139.7454,
            remarks: nil,
            lastUpdated: Date()
        ),
        missionResult: nil
    )
}
