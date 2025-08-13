// AuthenticationView.swift
import SwiftUI
import FirebaseAuth

struct AuthenticationView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var authMode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var username = ""
    @State private var showingVerification = false
    @State private var showingUsernamePrompt = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var verificationID = ""
    
    enum AuthMode {
        case signIn, signUp
        
        var title: String {
            switch self {
            case .signIn: return "Sign In"
            case .signUp: return "Sign Up"
            }
        }
        
        var alternateText: String {
            switch self {
            case .signIn: return "Don't have an account?"
            case .signUp: return "Already have an account?"
            }
        }
        
        var alternateAction: String {
            switch self {
            case .signIn: return "Sign Up"
            case .signUp: return "Sign In"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
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
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Join FlashTok")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Create an account to compete on leaderboards and track your progress")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 50)
                    
                    // Auth Mode Toggle
                    HStack(spacing: 0) {
                        ForEach([AuthMode.signIn, AuthMode.signUp], id: \.self) { mode in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    authMode = mode
                                    clearFields()
                                }
                            }) {
                                Text(mode.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(authMode == mode ? .white : .white.opacity(0.6))
                                    .padding(.vertical, 15)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(authMode == mode ? Color.purple.opacity(0.6) : Color.clear)
                                    )
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal, 30)
                    
                    // Authentication Methods
                    VStack(spacing: 20) {
                        // Email/Password Section
                        authFieldsSection()
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 15)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 30)
                        
                        // Social Login Buttons
                        socialLoginSection()
                        
                        // Phone Login
                        phoneLoginSection()
                    }
                    
                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 30)
                    }
                    
                    // Auth Mode Switch
                    HStack {
                        Text(authMode.alternateText)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                authMode = authMode == .signIn ? .signUp : .signIn
                                clearFields()
                            }
                        }) {
                            Text(authMode.alternateAction)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingVerification) {
            verificationCodeView()
        }
        .sheet(isPresented: $showingUsernamePrompt) {
            usernamePromptView()
        }
    }
    
    private func authFieldsSection() -> some View {
        VStack(spacing: 15) {
            // Email Field
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
                
                TextField("Email", text: $email)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Password Field
            HStack {
                Image(systemName: "lock")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Email/Password Login Button
            Button(action: emailPasswordAuth) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "envelope.fill")
                            .font(.headline)
                    }
                    
                    Text(authMode.title + " with Email")
                        .fontWeight(.semibold)
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
        }
        .padding(.horizontal, 30)
    }
    
    private func socialLoginSection() -> some View {
        VStack(spacing: 15) {
            // Google Sign In Button
            Button(action: googleSignIn) {
                HStack {
                    Image(systemName: "globe")
                        .font(.headline)
                    
                    Text("Continue with Google")
                        .fontWeight(.semibold)
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.6)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            
            // Anonymous Sign In Button
            Button(action: anonymousSignIn) {
                HStack {
                    Image(systemName: "person.fill.questionmark")
                        .font(.headline)
                    
                    Text("Continue Anonymously")
                        .fontWeight(.semibold)
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.8), Color.black.opacity(0.6)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
        }
        .padding(.horizontal, 30)
    }
    
    private func phoneLoginSection() -> some View {
        VStack(spacing: 15) {
            // Phone Number Field
            HStack {
                Image(systemName: "phone")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
                
                TextField("Phone Number (+1234567890)", text: $phoneNumber)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .keyboardType(.phonePad)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Phone Sign In Button
            Button(action: phoneSignIn) {
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.headline)
                    
                    Text("Sign In with Phone")
                        .fontWeight(.semibold)
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.mint]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .disabled(phoneNumber.isEmpty || isLoading)
            .opacity(phoneNumber.isEmpty ? 0.6 : 1.0)
        }
        .padding(.horizontal, 30)
    }
    
    private func verificationCodeView() -> some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Enter Verification Code")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                TextField("123456", text: $verificationCode)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal, 40)
                
                Button(action: verifyPhoneCode) {
                    Text("Verify")
                        .fontWeight(.semibold)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.green)
                        .cornerRadius(25)
                }
                .disabled(verificationCode.isEmpty)
                
                Spacer()
            }
            .padding(.top, 50)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.purple.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingVerification = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func usernamePromptView() -> some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("Choose Your Username")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("This is how you'll appear on leaderboards")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                TextField("Username", text: $username)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .font(.title3)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 40)
                
                Button(action: saveUsername) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.pink]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                }
                .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Spacer()
            }
            .padding(.top, 50)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.purple.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }
    
    // MARK: - Authentication Methods
    
    private func emailPasswordAuth() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if authMode == .signUp {
                    try await firebaseManager.signUp(email: email, password: password)
                } else {
                    try await firebaseManager.signIn(email: email, password: password)
                }
                
                await MainActor.run {
                    if authMode == .signUp {
                        showingUsernamePrompt = true
                    } else {
                        dismiss()
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func googleSignIn() {
        // TODO: Implement Google Sign-In
        // This requires additional setup with GoogleSignIn SDK
        errorMessage = "Google Sign-In coming soon! Use email or anonymous for now."
    }
    
    private func anonymousSignIn() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await firebaseManager.signInAnonymously()
                await MainActor.run {
                    dismiss()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func phoneSignIn() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                verificationID = try await firebaseManager.signInWithPhone(phoneNumber: phoneNumber)
                await MainActor.run {
                    showingVerification = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Phone authentication error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func verifyPhoneCode() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await firebaseManager.verifyPhoneCode(
                    verificationID: verificationID,
                    verificationCode: verificationCode
                )
                await MainActor.run {
                    showingVerification = false
                    showingUsernamePrompt = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Verification failed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func saveUsername() {
        Task {
            await firebaseManager.updateUsername(username.trimmingCharacters(in: .whitespacesAndNewlines))
            await MainActor.run {
                showingUsernamePrompt = false
                dismiss()
            }
        }
    }
    
    private func clearFields() {
        email = ""
        password = ""
        phoneNumber = ""
        verificationCode = ""
        errorMessage = ""
    }
}

#Preview {
    AuthenticationView()
}
