//
//  SignUpView.swift
//  whatsForDinner
//
//  Created by Sujal Shrestha on 2/7/26.
//

import SwiftUI
import Supabase

struct SignUpView: View {
    let supabase: SupabaseClient

    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var isLoading = false
    @State private var statusMessage: String?
    @State private var canResend = false

    // Optional: if you’ve set up deep links, put your app scheme here.
    // This must be allowed in Supabase Auth Redirect URLs.
    private let emailRedirectTo = URL(string: "myapp://auth-callback")

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text("Create Account")
                    .font(.largeTitle).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("Password (6+ chars)", text: $password)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await signUp() }
                } label: {
                    HStack {
                        if isLoading { ProgressView() }
                        Text(isLoading ? "Creating..." : "Create Account")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || !isFormValid)

                Button {
                    Task { await resendVerificationEmail() }
                } label: {
                    Text("Resend verification email")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isLoading || !canResend)

                Button("Back to Login") { dismiss() }
                    .font(.footnote)

                Spacer()
            }
            .padding()
            .navigationTitle("Sign Up")
        }
    }

    private var isFormValid: Bool {
        email.contains("@") &&
        email.contains(".") &&
        password.count >= 6 &&
        password == confirmPassword
    }

    private func signUp() async {
        statusMessage = nil
        canResend = false
        guard isFormValid else {
            statusMessage = "Enter a valid email and matching passwords (6+ chars)."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Create the user
            // If email confirmations are enabled, the user must verify via email.
            _ = try await supabase.auth.signUp(
                email: email,
                password: password
            )

            // If confirmations are ON, they’ll receive a verification email.
            // Supabase may not create an active session until verified.
            statusMessage = "Account created. Check your email to verify your account, then return to log in."
            canResend = true

        } catch {
            statusMessage = prettyAuthError(error)
            // If they already attempted sign up, you may still allow resend.
            canResend = true
        }
    }

    private func resendVerificationEmail() async {
        statusMessage = nil
        guard email.contains("@") else {
            statusMessage = "Enter your email above first."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Resend signup confirmation email
            try await supabase.auth.resend(
                email: email,
                type: .signup,
                emailRedirectTo: emailRedirectTo
            )

            statusMessage = "Verification email resent. Please check your inbox (and spam)."
        } catch {
            statusMessage = prettyAuthError(error)
        }
    }

    private func prettyAuthError(_ error: Error) -> String {
        // Keep it simple for UI
        let message = (error as NSError).localizedDescription
        return message.isEmpty ? "Something went wrong. Please try again." : message
    }
}

