import SwiftUI
import Supabase

struct ContentView: View {
    let supabase: SupabaseClient

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoggedIn {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                        Text("Logged in!")
                            .font(.title2)

                        Button("Log out") {
                            Task { await logout() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Text("Welcome Back")
                            .font(.largeTitle).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 12) {
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textContentType(.username)
                                .padding()
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .padding()
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await login() }
                        } label: {
                            HStack {
                                if isLoading { ProgressView() }
                                Text(isLoading ? "Signing in..." : "Sign In")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading || !isFormValid)

                        HStack {
                            Text("No account?")
                                .foregroundStyle(.secondary)

                            NavigationLink {
                                SignUpView(supabase: supabase)
                            } label: {
                                Text("Create one")
                            }
                        }
                        .font(.footnote)

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Login")
        }
    }

    private var isFormValid: Bool {
        email.contains("@") && email.contains(".") && password.count >= 6
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
            _ = try await supabase.auth.signIn(email: email, password: password)
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // REAL SUPABASE LOGOUT
    private func logout() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signOut()
        } catch {
            // optional: show error, but still clear local state
            errorMessage = error.localizedDescription
        }

        email = ""
        password = ""
        isLoggedIn = false
    }
}

