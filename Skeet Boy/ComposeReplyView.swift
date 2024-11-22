import SwiftUI

struct ComposeReplyView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authModel: AuthModel
    let replyTo: Post
    @State private var text = ""
    @State private var isLoading = false
    @State private var error: String?
    
    private let characterLimit = 300
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
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
                    Button(action: reply) {
                        Text("Reply")
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
            
            // Original Post
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    AsyncImage(url: URL(string: replyTo.author.avatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 40, height: 40)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(replyTo.author.displayName ?? replyTo.author.handle)
                            .font(.custom("Courier", size: 14))
                            .foregroundColor(.green)
                        Text("@\(replyTo.author.handle)")
                            .font(.custom("Courier", size: 12))
                            .foregroundColor(.green.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text(replyTo.formattedDate)
                        .font(.custom("Courier", size: 12))
                        .foregroundColor(.green.opacity(0.7))
                }
                
                Text(replyTo.record.text)
                    .font(.custom("Courier", size: 14))
                    .foregroundColor(.green.opacity(0.7))
            }
            .padding()
            .background(Color.black)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.green.opacity(0.3))
            
            // Reply Text Area
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
                            Text("Write your reply...")
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
            
            if let error = error {
                Text(error)
                    .font(.custom("Courier", size: 14))
                    .foregroundColor(.red)
                    .padding()
            }
            
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
                                .foregroundColor(.green.opacity(0.7))
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "link")
                                .font(.system(size: 20))
                                .foregroundColor(.green.opacity(0.7))
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
    
    private func reply() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.prepare()
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await createReply()
                DispatchQueue.main.async {
                    impactGenerator.impactOccurred()
                    isLoading = false
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = "error: \(error.localizedDescription.lowercased())"
                    self.isLoading = false
                    let errorGenerator = UINotificationFeedbackGenerator()
                    errorGenerator.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func createReply() async throws {
        let url = URL(string: "https://bsky.social/xrpc/com.atproto.repo.createRecord")!
        var request = URLRequest(url: url)
        
        let now = ISO8601DateFormatter().string(from: Date())
        
        let replyRecord: [String: Any] = [
            "repo": try AuthModel.getDid(),
            "collection": "app.bsky.feed.post",
            "record": [
                "$type": "app.bsky.feed.post",
                "text": text,
                "createdAt": now,
                "reply": [
                    "root": [
                        "uri": replyTo.uri,
                        "cid": replyTo.cid
                    ],
                    "parent": [
                        "uri": replyTo.uri,
                        "cid": replyTo.cid
                    ]
                ]
            ]
        ]
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(authModel.getAccessToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: replyRecord)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}

#Preview {
    ComposeReplyView(
        authModel: AuthModel(),
        replyTo: Post(
            uri: "preview",
            cid: "preview",
            author: Author(
                did: "preview",
                handle: "preview",
                displayName: "Preview User",
                avatar: nil
            ),
            record: PostRecord(
                text: "This is a preview post",
                createdAt: "2024-03-21T12:00:00Z"
            ),
            likeCount: 0,
            repostCount: 0,
            replyCount: 0,
            indexedAt: "2024-03-21T12:00:00Z"
        )
    )
}