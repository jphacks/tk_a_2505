//
//  InputFieldStyle.swift
//  escape
//
//  Created by Thanasan Kumdee on 27/10/2568 BE.
//

import SwiftUI

// MARK: - Input Field Style

enum InputFieldStyle {
    static let horizontalPadding: CGFloat = 12
    static let verticalPadding: CGFloat = 14
    static let cornerRadius: CGFloat = 8
    static let fontSize: CGFloat = 16
    static let iconSize: CGFloat = 14
    static let iconSpacing: CGFloat = 10
    static let backgroundColor = Color(.systemGray6).opacity(0.8)
    static let iconColor = Color.secondary.opacity(0.7)
}

// MARK: - Reusable Input Field Component

struct IconTextField: View {
    let icon: String
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?

    var body: some View {
        HStack(spacing: InputFieldStyle.iconSpacing) {
            Image(systemName: icon)
                .font(.system(size: InputFieldStyle.iconSize))
                .foregroundColor(InputFieldStyle.iconColor)

            TextField(placeholder, text: $text)
                .font(.system(size: InputFieldStyle.fontSize))
                .textContentType(textContentType)
                .textInputAutocapitalization(textContentType == .emailAddress ? .never : .sentences)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
        }
        .padding(.horizontal, InputFieldStyle.horizontalPadding)
        .padding(.vertical, InputFieldStyle.verticalPadding)
        .background(InputFieldStyle.backgroundColor)
        .cornerRadius(InputFieldStyle.cornerRadius)
    }
}

// MARK: - Reusable Secure Field Component

struct IconSecureField: View {
    let icon: String
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var textContentType: UITextContentType?

    var body: some View {
        HStack(spacing: InputFieldStyle.iconSpacing) {
            Image(systemName: icon)
                .font(.system(size: InputFieldStyle.iconSize))
                .foregroundColor(InputFieldStyle.iconColor)
                .frame(width: 25)

            SecureField(placeholder, text: $text)
                .font(.system(size: InputFieldStyle.fontSize))
                .textContentType(textContentType ?? .password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, InputFieldStyle.horizontalPadding)
        .padding(.vertical, InputFieldStyle.verticalPadding)
        .background(InputFieldStyle.backgroundColor)
        .cornerRadius(InputFieldStyle.cornerRadius)
    }
}
