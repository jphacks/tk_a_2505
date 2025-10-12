//
//  DevView.swift
//  escape
//
//  Created for development and testing purposes
//

import SwiftUI

struct DevView: View {
    @Environment(\.missionStateManager) var missionStateManager
    @State private var controller = BadgeController()
    @State private var missionController = MissionGeneratorController()
    @State private var locationName = ""
    @State private var locationDescription = ""
    @State private var colorTheme = ""
    @State private var showImagePreview = false
    @State private var missionContext = ""
    @State private var selectedDisasterType: DisasterType?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("dev.location_name", text: $locationName)
                        .autocorrectionDisabled()

                    TextField("dev.location_description", text: $locationDescription, axis: .vertical)
                        .lineLimit(3 ... 6)
                        .autocorrectionDisabled()

                    TextField("dev.color_theme", text: $colorTheme)
                        .autocorrectionDisabled()
                } header: {
                    Text("dev.badge_generator_header")
                        .textCase(nil)
                }

                Section {
                    Button(action: generateBadge) {
                        HStack {
                            Spacer()
                            if controller.isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("dev.generate_badge")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(controller.isGenerating || locationName.isEmpty)
                }

                if let errorMessage = controller.errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                }

                if let imageUrl = controller.generatedBadgeUrl {
                    Section {
                        VStack(spacing: 16) {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 200)
                                case let .success(image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(12)
                                        .onTapGesture {
                                            showImagePreview = true
                                        }
                                case .failure:
                                    Image(systemName: "photo.fill")
                                        .foregroundColor(.gray)
                                        .frame(height: 200)
                                @unknown default:
                                    EmptyView()
                                }
                            }

                            Button(action: {
                                UIPasteboard.general.string = imageUrl
                            }) {
                                Label("dev.copy_url", systemImage: "doc.on.doc")
                            }
                        }
                    } header: {
                        Text("dev.generated_badge")
                    }
                }

                Section {
                    Button("dev.test_korakuen") {
                        loadKorakuenPreset()
                    }

                    Button("dev.clear_fields") {
                        clearFields()
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("dev.presets")
                }

                Section {
                    TextField("Mission context (optional)", text: $missionContext, axis: .vertical)
                        .lineLimit(2...4)
                        .autocorrectionDisabled()

                    Picker("Disaster Type (optional)", selection: $selectedDisasterType) {
                        Text("Random").tag(nil as DisasterType?)
                        ForEach(DisasterType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type as DisasterType?)
                        }
                    }
                } header: {
                    Text("Mission Parameters")
                }

                Section {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Current State:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(missionStateManager.currentMissionState.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(stateColor(for: missionStateManager.currentMissionState))
                                .cornerRadius(6)
                        }

                        Button(action: generateMission) {
                            HStack {
                                Spacer()
                                if missionController.isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Text("Generate Mission")
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .disabled(missionController.isGenerating)

                        Button("Reset Mission") {
                            missionStateManager.resetMission()
                            missionController.reset()
                            missionContext = ""
                            selectedDisasterType = nil
                        }
                        .foregroundColor(.orange)
                    }

                    if let errorMessage = missionController.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Text("Mission Generator")
                }

                // Current Mission Details
                if let mission = missionStateManager.currentMission {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            // Title
                            if let title = mission.title {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Title:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(title)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                }
                            }

                            // Overview
                            if let overview = mission.overview {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Overview:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(overview)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }

                            Divider()

                            // Disaster Type
                            HStack {
                                Text("Disaster Type:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if let disasterType = mission.disasterType {
                                    HStack(spacing: 4) {
                                        Image(systemName: disasterType.iconName)
                                            .font(.caption)
                                        Text(disasterType.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.orange)
                                } else {
                                    Text("None")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            // Status
                            HStack {
                                Text("Status:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(mission.status.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(stateColor(for: mission.status))
                                    .cornerRadius(4)
                            }

                            // Region
                            if let region = mission.evacuationRegion {
                                HStack {
                                    Text("Region:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(region)
                                        .font(.caption)
                                }
                            }

                            Divider()

                            // Stats
                            HStack(spacing: 20) {
                                if let steps = mission.steps {
                                    VStack(spacing: 2) {
                                        Text("\(steps)")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                        Text("Steps")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                if let distances = mission.distances {
                                    VStack(spacing: 2) {
                                        Text(String(format: "%.1f km", distances / 1000))
                                            .font(.body)
                                            .fontWeight(.semibold)
                                        Text("Distance")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)

                            Divider()

                            // Metadata
                            VStack(spacing: 4) {
                                HStack {
                                    Text("ID:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(mission.id.uuidString)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text("Created:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(mission.createdAt, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Current Mission Details")
                    }
                }
            }
            .navigationTitle("dev.title")
            .sheet(isPresented: $showImagePreview) {
                if let imageUrl = controller.generatedBadgeUrl {
                    ImagePreviewView(imageUrl: imageUrl)
                }
            }
        }
    }

    private func generateBadge() {
        let finalColorTheme = colorTheme.isEmpty ? nil : colorTheme
        let finalDescription = locationDescription.isEmpty ? "A notable location" : locationDescription

        Task {
            await controller.generateBadge(
                locationName: locationName,
                locationDescription: finalDescription,
                colorTheme: finalColorTheme
            )
        }
    }

    private func loadKorakuenPreset() {
        locationName = "後楽園"
        locationDescription = "Features the iconic Tokyo Dome stadium, Kōrakuen Garden with traditional Japanese elements like bridges and ginkgo trees, and amusement park rides including Ferris wheels and roller coasters"
        colorTheme = "modern urban blues and greys for the Dome, traditional greens, reds, and golds for the garden elements"
    }

    private func clearFields() {
        locationName = ""
        locationDescription = ""
        colorTheme = ""
        controller.reset()
    }

    private func generateMission() {
        Task {
            // Generate the mission using the edge function
            let context = missionContext.isEmpty ? nil : missionContext
            await missionController.generateMission(
                context: context,
                disasterTypeHint: selectedDisasterType
            )

            // If successful, update the mission state manager
            if let mission = missionController.generatedMission {
                missionStateManager.updateMission(mission)
            }
        }
    }

    private func stateColor(for state: MissionState) -> Color {
        switch state {
        case .noMission:
            return .gray.opacity(0.2)
        case .inProgress:
            return .blue.opacity(0.2)
        case .active:
            return .green.opacity(0.2)
        case .completed:
            return .purple.opacity(0.2)
        }
    }
}

struct ImagePreviewView: View {
    let imageUrl: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: "photo.fill")
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("dev.close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DevView()
}
