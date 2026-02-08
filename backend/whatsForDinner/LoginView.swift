// LoginView.swift
import SwiftUI

struct LoginView: View {
    @State private var isLoggedIn = false
    
    var body: some View {
        NavigationStack {
            if isLoggedIn {
                // Show main app
                MainTabView()
                    .navigationBarBackButtonHidden()
            } else {
                // Testing login screen
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.green)
                        
                        Text("What's for Dinner?")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Your personalized meal planner")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Testing Mode")
                                .font(.headline)
                            
                            Text("Click below to test the app without authentication. Make sure your FastAPI backend is running on http://localhost:8000")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Button {
                            isLoggedIn = true
                        } label: {
                            Label("Start Testing", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Features:")
                                .font(.caption)
                                .bold()
                            
                            FeatureRow(icon: "fork.knife", text: "Daily recipe suggestions")
                            FeatureRow(icon: "brain", text: "AI-simplified cooking steps")
                            FeatureRow(icon: "chart.bar", text: "Macro nutrition tracking")
                            FeatureRow(icon: "shippingbox", text: "Inventory management")
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Welcome")
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 20)
            Text(text)
                .font(.caption)
        }
    }
}

#Preview {
    LoginView()
}
