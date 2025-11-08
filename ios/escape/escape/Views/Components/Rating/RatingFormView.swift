//
//  RatingFormView.swift
//  escape
//
//  Created for shelter rating system
//

import SwiftUI

/// Form for submitting or editing a shelter rating
struct RatingFormView: View {
    // MARK: - Properties

    @Bindable var viewModel: RatingViewModel
    let isEditing: Bool

    // MARK: - Initialization

    init(viewModel: RatingViewModel, isEditing: Bool = false) {
        self.viewModel = viewModel
        self.isEditing = isEditing
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            Text(isEditing ? "Edit Your Rating" : "Rate This Shelter")
                .font(.headline)

            // Star rating picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Rating")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                StarRatingView(
                    rating: viewModel.formState.rating,
                    onRatingChanged: { newRating in
                        viewModel.formState.rating = newRating
                    }
                )

                if viewModel.formState.rating == 0 {
                    Text("Tap a star to rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Review text field
            VStack(alignment: .leading, spacing: 8) {
                Text("Review (Optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextEditor(text: $viewModel.formState.review)
                    .frame(minHeight: 100, maxHeight: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                viewModel.formState.isReviewTooLong ? Color.red : Color.clear,
                                lineWidth: 1
                            )
                    )

                // Character counter
                HStack {
                    Spacer()
                    Text("\(viewModel.formState.characterCount) / 500")
                        .font(.caption)
                        .foregroundColor(
                            viewModel.formState.isReviewTooLong ? .red : .secondary
                        )
                }

                if viewModel.formState.isReviewTooLong {
                    Text("Review must be 500 characters or less")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Submit button
            Button(action: {
                Task {
                    await viewModel.submitRating()
                }
            }) {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }

                    Text(viewModel.submitButtonText)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSubmit ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canSubmit)

            // Delete button (only when editing)
            if isEditing {
                Button(role: .destructive, action: {
                    Task {
                        await viewModel.deleteUserRating()
                    }
                }) {
                    HStack {
                        if viewModel.isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                        }

                        Text("Delete Rating")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isDeleting)
            }

            // Error message
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                        .font(.caption)
                }
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            // Success message
            if let success = viewModel.successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(success)
                        .font(.caption)
                }
                .foregroundColor(.green)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .onChange(of: viewModel.successMessage) { oldValue, newValue in
            // Haptic feedback for successful operations
            if newValue != nil && oldValue == nil {
                // Check if this was a delete operation (only shown in edit mode)
                if isEditing && newValue?.contains("deleted") == true || newValue?.contains("Deleted") == true {
                    HapticFeedback.shared.warning()
                } else {
                    // This is a submit/update operation
                    HapticFeedback.shared.success()
                }
            }
        }
    }
}

// MARK: - Compact Form for Inline Display

struct RatingFormCompact: View {
    @Bindable var viewModel: RatingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Star rating
            HStack {
                Text("Your rating:")
                    .font(.subheadline)

                StarRatingView(
                    rating: viewModel.formState.rating,
                    starSize: 24,
                    onRatingChanged: { newRating in
                        viewModel.formState.rating = newRating
                    }
                )
            }

            // Review field
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $viewModel.formState.review)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                HStack {
                    Spacer()
                    Text("\(viewModel.formState.characterCount) / 500")
                        .font(.caption)
                        .foregroundColor(
                            viewModel.formState.isReviewTooLong ? .red : .secondary
                        )
                }
            }

            // Submit button
            Button(action: {
                Task {
                    await viewModel.submitRating()
                }
            }) {
                Text(viewModel.submitButtonText)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(viewModel.canSubmit ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!viewModel.canSubmit)
        }
    }
}

// MARK: - Preview

#Preview("New Rating") {
    struct PreviewWrapper: View {
        @State private var viewModel = RatingViewModel()

        var body: some View {
            ScrollView {
                RatingFormView(viewModel: viewModel, isEditing: false)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("Edit Rating") {
    struct PreviewWrapper: View {
        @State private var viewModel: RatingViewModel = {
            let vm = RatingViewModel()
            // Simulate existing rating
            vm.formState.rating = 4
            vm.formState.review = "This is my existing review that I want to edit."
            return vm
        }()

        var body: some View {
            ScrollView {
                RatingFormView(viewModel: viewModel, isEditing: true)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("Compact Form") {
    struct PreviewWrapper: View {
        @State private var viewModel = RatingViewModel()

        var body: some View {
            RatingFormCompact(viewModel: viewModel)
                .padding()
        }
    }

    return PreviewWrapper()
}
