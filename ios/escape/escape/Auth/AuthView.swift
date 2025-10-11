//
//  AuthView.swift
//  escape
//
//  Created by Thanasan Kumdee on 8/10/2568 BE.
//

import Supabase
import SwiftUI

struct AuthView: View {
    @State var email = ""
    @State var isLoading = false
    @State var result: Result<Void, Error>?

    var body: some View {
        Form {
            Section {
                TextField("auth.email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section {
                Button("auth.sign_in") {
                    signInButtonTapped()
                }

                if isLoading {
                    ProgressView()
                }
            }

            if let result {
                Section {
                    switch result {
                    case .success:
                        Text("auth.check_inbox")
                    case let .failure(error):
                        Text(error.localizedDescription).foregroundStyle(.red)
                    }
                }
            }
        }
        .onOpenURL(perform: { url in
            Task {
                do {
                    try await supabase.auth.session(from: url)
                } catch {
                    self.result = .failure(error)
                }
            }
        })
    }

    func signInButtonTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                try await supabase.auth.signInWithOTP(
                    email: email,
                    redirectTo: URL(string: "io.supabase.user-management://login-callback")
                )
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }
}

#Preview("AuthView - English") {
    AuthView().environment(\.locale, .init(identifier: "en"))
}

#Preview("AuthView - Japanese") {
    AuthView().environment(\.locale, .init(identifier: "ja"))
}
