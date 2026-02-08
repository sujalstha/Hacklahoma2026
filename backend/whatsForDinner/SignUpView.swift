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
            ZStack {
                // Background Gradient
                Color.white.ignoresSafeArea()
                
                LinearGradient(
                    colors: [Color.appSecondaryLight.opacity(0.4), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "person.badge.plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .foregroundStyle(Color.primaryGradient)
                            
                            Text("Join What's For Dinner")
                                .font(.system(.title, design: .rounded))
                                .bold()
                                .foregroundStyle(Color.foodGradient)
                        }
                        .padding(.top, 30)
                        
                        // Form Card
                        VStack(spacing: 20) {
                            Text("Create Account")
                                .font(.system(.title2, design: .rounded))
                                .bold()
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 15) {
                                customField(label: "Email", icon: "envelope", placeholder: "your@email.com", text: $email)
                                customField(label: "Password", icon: "lock", placeholder: "6+ characters", text: $password, isSecure: true)
                                customField(label: "Confirm Password", icon: "lock.fill", placeholder: "Repeat password", text: $confirmPassword, isSecure: true)
                            }
                            
                            if let statusMessage {
                                Label(statusMessage, systemImage: "info.circle.fill")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .transition(.opacity)
                            }
                            
                            Button {
                                withAnimation { isLoading = true }
                                Task { await signUp() }
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                            .padding(.trailing, 5)
                                    }
                                    Text(isLoading ? "Creating..." : "Start Cooking")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isFormValid ? AnyShapeStyle(Color.primaryGradient) : AnyShapeStyle(Color.gray.opacity(0.2)))
                                .clipShape(Capsule())
                                .shadow(color: isFormValid ? .appPrimary.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                            }
                            .disabled(isLoading || !isFormValid)
                            
                            Button("Already have an account? Login") {
                                dismiss()
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 10)
                        }
                        .padding(25)
                        .premiumCardStyle()
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
    
    @ViewBuilder
    private func customField(label: String, icon: String, placeholder: String, text: Binding<String>, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(label == "Email" ? .emailAddress : .default)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
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

