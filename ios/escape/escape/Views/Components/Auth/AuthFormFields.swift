//
//  AuthFormFields.swift
//  escape
//
//  Created by Thanasan Kumdee on 27/10/2568 BE.
//
import SwiftUI

struct AuthFormFields: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    let usePasswordAuth: Bool
    let isSignUp: Bool
    let passwordsMatch: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Email field
            IconTextField(
                icon: "envelope",
                placeholder: "auth.email",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            // Password field (only show when password auth is selected)
            if usePasswordAuth {
                IconSecureField(
                    icon: "lock",
                    placeholder: "auth.password",
                    text: $password,
                    textContentType: isSignUp ? .newPassword : .password
                )

                // Confirm password field (only show for sign up)
                if isSignUp {
                    VStack(alignment: .leading, spacing: 4) {
                        IconSecureField(
                            icon: "lock.fill",
                            placeholder: "auth.confirm_password",
                            text: $confirmPassword,
                            textContentType: .newPassword
                        )

                        // Password match indicator
                        if !password.isEmpty && !confirmPassword.isEmpty {
                            PasswordMatchIndicator(passwordsMatch: passwordsMatch)
                        }
                    }
                }
            }
        }
    }
}
