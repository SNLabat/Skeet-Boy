import SwiftUI

struct LoginView: View {
    @ObservedObject var authModel: AuthModel
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("SKEET-BOY 3000")
                .font(.custom("Courier", size: 32))
                .foregroundColor(.green)
                .shadow(color: .green.opacity(0.5), radius: 10)
            
            Text("VAULT-TEC SOCIAL INTERFACE")
                .font(.custom("Courier", size: 16))
                .foregroundColor(.green)
                .padding(.bottom, 40)
            
            // Login Fields
            loginField(text: $username, placeholder: "handle", isSecure: false)
            loginField(text: $password, placeholder: "password", isSecure: true)
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.custom("Courier", size: 14))
            }
            
            // Login Button
            Button(action: login) {
                Text(isLoading ? "connecting..." : "login")
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green.opacity(0.5), lineWidth: 1)
                    )
            }
            .disabled(isLoading)
            
            Spacer()
            
            Text("VAULT-TEC INDUSTRIES™")
                .font(.custom("Courier", size: 12))
                .foregroundColor(.green.opacity(0.7))
        }
        .padding(32)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }
    
    private func loginField(text: Binding<String>, placeholder: String, isSecure: Bool) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
            }
        }
        .textFieldStyle(.plain)
        .padding()
        .background(Color.black)
        .foregroundColor(Color.green)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green, lineWidth: 1)
        )
        .font(.custom("Courier", size: 16))
    }
    
    private func login() {
        guard !username.isEmpty, !password.isEmpty else {
            error = "please enter credentials"
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await authModel.login(identifier: username, password: password)
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription.lowercased()
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    LoginView(authModel: AuthModel())
}
