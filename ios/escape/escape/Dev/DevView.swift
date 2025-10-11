//
//  DevView.swift
//  escape
//
//  Created for development and testing purposes
//

import SwiftUI

struct DevView: View {
    @State private var controller = BadgeController()
    @State private var locationName = ""
    @State private var locationDescription = ""
    @State private var colorTheme = ""
    @State private var showImagePreview = false

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
