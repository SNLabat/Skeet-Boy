import SwiftUI

struct ComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authModel: AuthModel
    @State private var text = ""
    @State private var isLoading = false
    @State private var error: String?
    
    private let characterLimit = 300
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.custom("Courier", size: 16))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                } else {
                    Button(action: post) {
                        Text("Post")
                            .font(.custom("Courier", size: 16))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(text.isEmpty ? Color.green.opacity(0.5) : Color.green)
                            .cornerRadius(16)
                    }
                    .disabled(text.isEmpty || text.count > characterLimit)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.black)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.green.opacity(0.3))
            
            // Profile and Text Input
            HStack(alignment: .top, spacing: 8) {
                AsyncImage(url: URL(string: authModel.userAvatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                } placeholder: {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 40, height: 40)
                }
                
                TextEditor(text: $text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .font(.custom("Courier", size: 16))
                    .foregroundColor(.green)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("What's up?")
                                .foregroundColor(.green.opacity(0.5))
                                .font(.custom("Courier", size: 16))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer()
            
            VStack(spacing: 0) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.green.opacity(0.3))
                
                // Bottom Buttons and Character Count
                HStack {
                    HStack(spacing: 20) {
                        Button(action: {}) {
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "video")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "camera")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "g.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text("English")
                            .foregroundColor(.green)
                            .font(.custom("Courier", size: 14))
                        
                        Text("\(text.count)")
                            .foregroundColor(text.count > characterLimit ? .red : .green)
                            .font(.custom("Courier", size: 14))
                            + Text(" / \(characterLimit)")
                            .foregroundColor(.green.opacity(0.7))
                            .font(.custom("Courier", size: 14))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.black)
                
                // Bottom Safe Area
                HStack {
                    Button(action: {}) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 24))
                            .foregroundColor(.green.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "mic")
                            .font(.system(size: 24))
                            .foregroundColor(.green.opacity(0.7))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.8))
            }
        }
        .background(Color.black)
    }
    
    private func post() {
        guard !text.isEmpty && text.count <= characterLimit else { 
            error = "post cannot be empty"
            let errorGenerator = UINotificationFeedbackGenerator()
            errorGenerator.notificationOccurred(.error)
            return 
        }
        
        isLoading = true
        error = nil
        
        // Prepare haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.prepare()
        
        Task {
            do {
                try await PostModel.createPost(text: text, accessToken: authModel.getAccessToken())
                DispatchQueue.main.async {
                    // Success haptic
                    impactGenerator.impactOccurred()
                    isLoading = false
                    dismiss()
                }
            } catch let error as URLError {
                DispatchQueue.main.async {
                    self.error = "network error: \(error.localizedDescription.lowercased())"
                    self.isLoading = false
                    // Error haptic
                    let errorGenerator = UINotificationFeedbackGenerator()
                    errorGenerator.notificationOccurred(.error)
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = "error: \(error.localizedDescription.lowercased())"
                    self.isLoading = false
                    // Error haptic
                    let errorGenerator = UINotificationFeedbackGenerator()
                    errorGenerator.notificationOccurred(.error)
                }
            }
        }
    }
}

#Preview {
    ComposeView(authModel: AuthModel())
        .preferredColorScheme(.dark)
}
