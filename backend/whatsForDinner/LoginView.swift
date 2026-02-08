import SwiftUI
import Supabase

struct LoginView: View {
    let supabase: SupabaseClient

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                Color.white.ignoresSafeArea()
                
                LinearGradient(
                    colors: [Color.appPrimaryLight.opacity(0.5), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
                
                if isLoggedIn {
                    MainTabView()
                } else {
                    ScrollView {
                        VStack(spacing: 30) {
                            // Logo and App Name
                            VStack(spacing: 12) {
                                Image(systemName: "fork.knife.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .foregroundStyle(Color.foodGradient)
                                    .shadow(color: Color.appSecondary.opacity(0.2), radius: 10)
                                
                                Text("What's For Dinner")
                                    .font(.system(.title, design: .rounded))
                                    .bold()
                                    .foregroundStyle(Color.foodGradient)
                            }
                            .padding(.top, 40)
                            
                            // Form Card
                            VStack(spacing: 20) {
                                Text("Welcome Back")
                                    .font(.system(.title2, design: .rounded))
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 15) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Label("Email", systemImage: "envelope")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        TextField("your@email.com", text: $email)
                                            .textInputAutocapitalization(.never)
                                            .keyboardType(.emailAddress)
                                            .autocorrectionDisabled()
                                            .padding()
                                            .background(Color.secondary.opacity(0.05))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Label("Password", systemImage: "lock")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        SecureField("••••••••", text: $password)
                                            .padding()
                                            .background(Color.secondary.opacity(0.05))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                            )
                                    }
                                }
                                
                                if let errorMessage {
                                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                        .font(.footnote)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                                
                                Button {
                                    withAnimation { isLoading = true }
                                    Task { await login() }
                                } label: {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .tint(.white)
                                                .padding(.trailing, 5)
                                        }
                                        Text(isLoading ? "Authenticating..." : "Sign In")
                                            .fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFormValid ? AnyShapeStyle(Color.primaryGradient) : AnyShapeStyle(Color.gray.opacity(0.2)))
                                    .clipShape(Capsule())
                                    .shadow(color: isFormValid ? Color.appPrimary.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                                }
                                .disabled(isLoading || !isFormValid)
                                .scaleEffect(isLoading ? 0.98 : 1.0)
                            }
                            .padding(25)
                            .premiumCardStyle()
                            
                            // Bottom Link
                            HStack {
                                Text("Don't have an account?")
                                    .foregroundStyle(.secondary)
                                
                                NavigationLink {
                                    SignUpView(supabase: supabase)
                                } label: {
                                    Text("Create one")
                                        .bold()
                                        .foregroundStyle(Color.appPrimary)
                                }
                            }
                            .font(.subheadline)
                            .padding(.bottom, 20)
                        }
                        .padding()
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        email.contains("@") &&
        email.contains(".") &&
        password.count >= 6
    }

    // REAL SUPABASE LOGIN
    private func login() async {
        errorMessage = nil

        guard isFormValid else {
            errorMessage = "Enter a valid email and a password (6+ characters)."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

