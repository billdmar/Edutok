// AuthenticationView.swift
import SwiftUI

enum AuthMode {
    case signIn, signUp
}

enum AuthMethod {
    case email, phone, google
}

struct AuthenticationView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var authMode: AuthMode = .signIn
    @State private var selectedMethod: AuthMethod = .email
    @State private var email = ""
    @State private var password = ""
    @State private var phoneNumber = ""
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isCheckingUsername = false
    @State private var usernameAvailable = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        VStack(spacing: 8) {
                            Text(authMode == .signIn ? "Welcome Back!" : "Join FlashTok")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(authMode == .signIn ?
                                 "Track your progress and compete!" :
                                 "Start your learning journey today")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Auth mode toggle
                    HStack(spacing: 0) {
                        ForEach([AuthMode.signIn, AuthMode.signUp], id: \.self) { mode in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    authMode = mode
                                    clearFields()
                                }
                            }) {
                                Text(mode == .signIn ? "Sign In" : "Sign Up")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(authMode == mode ? .white : .white.opacity(0.6))
                                    .padding(.vertical, 15)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(authMode == mode ?
                                                  LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing) :
                                                  LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing))
                                    )
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal, 40)
                    
                    // Authentication method selection
                    VStack(spacing: 20) {
                        Text("Choose sign \(authMode == .signIn ? "in" : "up") method:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 15) {
                            ForEach([AuthMethod.email, AuthMethod.phone, AuthMethod.google], id: \.self) { method in
                                Button(action: {
                                    selectedMethod = method
                                    clearFields()
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: methodIcon(method))
                                            .font(.title2)
                                            .foregroundColor(selectedMethod == method ? .white : .white.opacity(0.6))
                                        
                                        Text(methodTitle(method))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedMethod == method ? .white : .white.opacity(0.6))
                                    }
                                    .padding(.vertical, 15)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(selectedMethod == method ?
                                                  Color.purple.opacity(0.3) :
                                                  Color.white.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(selectedMethod == method ?
                                                           Color.purple.opacity(0.6) :
                                                           Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Input fields
                    VStack(spacing: 20) {
                        if authMode == .signUp {
                            // Username field for sign up
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    TextField("Choose a username", text: $username)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .onChange(of: username) { newValue in
                                            checkUsernameAvailability(newValue)
                                        }
                                    
                                    if isCheckingUsername {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else if !username.isEmpty {
                                        Image(systemName: usernameAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(usernameAvailable ? .green : .red)
                                    }
                                }
                                
                                if !username.isEmpty && !usernameAvailable {
                                    Text("Username already taken")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        if selectedMethod == .email {
                            TextField("Email", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        } else if selectedMethod == .phone {
                            TextField("Phone Number", text: $phoneNumber)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.phonePad)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Action button
                    Button(action: performAuthentication) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: authMode == .signIn ? "arrow.right.circle.fill" : "person.fill.badge.plus")
                                    .font(.title3)
                            }
                            
                            Text(buttonTitle)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 5)
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    .padding(.horizontal, 30)
                    
                    // Skip option
                    Button(action: {
                        Task {
                            try? await firebaseManager.signInAnonymously()
                            dismiss()
                        }
                    }) {
                        Text("Continue as Guest")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                            .underline()
                    }
                    .padding(.bottom, 30)
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.purple.opacity(0.3),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var buttonTitle: String {
        if selectedMethod == .google {
            return authMode == .signIn ? "Sign in with Google" : "Sign up with Google"
        } else {
            return authMode == .signIn ? "Sign In" : "Create Account"
        }
    }
    
    private var isFormValid: Bool {
        if authMode == .signUp && (username.isEmpty || !usernameAvailable) {
            return false
        }
        
        switch selectedMethod {
        case .email:
            return !email.isEmpty && !password.isEmpty && password.count >= 6
        case .phone:
            return !phoneNumber.isEmpty && phoneNumber.count >= 10
        case .google:
            return true
        }
    }
    
    private func methodIcon(_ method: AuthMethod) -> String {
        switch method {
        case .email: return "envelope.fill"
        case .phone: return "phone.fill"
        case .google: return "globe"
        }
    }
    
    private func methodTitle(_ method: AuthMethod) -> String {
        switch method {
        case .email: return "Email"
        case .phone: return "Phone"
        case .google: return "Google"
        }
    }
    
    private func clearFields() {
        email = ""
        password = ""
        phoneNumber = ""
        if authMode == .signIn {
            username = ""
        }
        errorMessage = ""
    }
    
    private func checkUsernameAvailability(_ username: String) {
        guard !username.isEmpty, username.count >= 3 else {
            usernameAvailable = true
            return
        }
        
        isCheckingUsername = true
        
        // Simulate API call - replace with actual Firebase check
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            
            await MainActor.run {
                // TODO: Implement actual Firebase username check
                usernameAvailable = !["admin", "test", "user", "flashtok"].contains(username.lowercased())
                isCheckingUsername = false
            }
        }
    }
    
    private func performAuthentication() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                switch selectedMethod {
                case .email:
                    if authMode == .signIn {
                        try await firebaseManager.signInWithEmail(email: email, password: password)
                    } else {
                        try await firebaseManager.signUpWithEmail(email: email, password: password, username: username)
                    }
                case .phone:
                    try await firebaseManager.signInWithPhone(phoneNumber: phoneNumber)
                case .google:
                    try await firebaseManager.signInWithGoogle()
                }
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
            .font(.body)
    }
}
