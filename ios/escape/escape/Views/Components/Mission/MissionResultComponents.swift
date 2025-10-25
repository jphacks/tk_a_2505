//
//  MissionResultComponents.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import SwiftUI

// MARK: - Interactive Badge View

/// Interactive badge display with 3D rotation effect
struct InteractiveBadgeView: View {
    let badge: Badge
    @State private var rotationY: Double = 0

    var body: some View {
        VStack(spacing: 8) {
            if let imageUrl = badge.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(color: badge.color.opacity(0.3), radius: 10)
                            .rotation3DEffect(
                                .degrees(rotationY),
                                axis: (x: 0, y: 1, z: 0)
                            )
                            .onAppear {
                                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                                    rotationY = 15
                                }
                            }
                    case .failure:
                        badgePlaceholder
                    case .empty:
                        ProgressView()
                            .frame(width: 120, height: 120)
                    @unknown default:
                        badgePlaceholder
                    }
                }
            } else {
                badgePlaceholder
            }

            Text(badge.name)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }

    private var badgePlaceholder: some View {
        Circle()
            .fill(badge.color.opacity(0.3))
            .frame(width: 120, height: 120)
            .overlay(
                Image(systemName: badge.icon)
                    .font(.system(size: 40))
                    .foregroundColor(badge.color)
            )
    }
}

// MARK: - Stat Card

/// Stat card displaying mission statistics
struct StatCard: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color("brandOrange"))

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Shelter Info Card

/// Shelter information card
struct ShelterInfoCard: View {
    let shelter: Shelter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("result.shelter_info")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "result.shelter_name", value: shelter.name)
                InfoRow(label: "result.address", value: shelter.address)
                InfoRow(label: "result.municipality", value: shelter.municipality ?? "")

                // Disaster types
                if shelter.isEarthquake ?? false {
                    InfoRow(label: "result.earthquake", value: "✓")
                }
                if shelter.isFire ?? false {
                    InfoRow(label: "result.fire", value: "✓")
                }
                if shelter.isFlood ?? false {
                    InfoRow(label: "result.flood", value: "✓")
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Info Row Helper

struct InfoRow: View {
    let label: LocalizedStringKey
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Badge Generation Section

/// Badge generation section with first visitor flow
struct BadgeGenerationSection: View {
    let shelter: Shelter
    @Binding var isGeneratingBadge: Bool
    @Binding var isBadgeGenerated: Bool
    @Binding var isFirstVisitor: Bool
    @Binding var generatedBadgeUrl: String?
    @Binding var errorMessage: String?
    let badgeViewModel: BadgeViewModel
    @Binding var showDescriptionInput: Bool
    @Binding var userDescription: String
    @Binding var acquiredBadge: Badge?
    let onGenerateBadge: () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            if showDescriptionInput {
                VStack(alignment: .leading, spacing: 12) {
                    Text("result.first_visitor_title")
                        .font(.headline)

                    Text("result.first_visitor_description")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("result.description_placeholder", text: $userDescription)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 8)

                    Button {
                        Task {
                            await onGenerateBadge()
                        }
                    } label: {
                        HStack {
                            if isGeneratingBadge {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            }
                            Text("result.generate_badge")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("brandOrange"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isGeneratingBadge)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}
