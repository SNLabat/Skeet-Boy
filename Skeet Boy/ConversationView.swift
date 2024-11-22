import SwiftUI

struct ConversationView: View {
    let recipient: Author
    @ObservedObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = true
    @State private var isSending = false
    @State private var error: String?
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                
                AsyncImage(url: URL(string: recipient.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 32, height: 32)
                }
                
                Text(recipient.displayName ?? recipient.handle)
                    .font(.custom("Courier", size: 18))
                    .foregroundColor(.green)
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.green.opacity(0.3)),
                alignment: .bottom
            )
            
            // Messages
            if isLoading && messages.isEmpty {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
                    .scaleEffect(1.5)
                Spacer()
            } else if let error = error {
                Spacer()
                Text("ERROR: \(error)")
                    .font(.custom("Courier", size: 14))
                    .foregroundColor(.red)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { message in
                                MessageBubble(message: message, isFromUser: message.author.did == UserDefaults.standard.string(forKey: "userDID"))
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { oldCount, newCount in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Message Input
            VStack(spacing: 0) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.green.opacity(0.3))
                
                HStack(spacing: 12) {
                    TextField("Write a message", text: $messageText)
                        .font(.custom("Courier", size: 16))
                        .foregroundColor(.green)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                        .focused($isTextFieldFocused)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(messageText.isEmpty ? .green.opacity(0.5) : .green)
                    }
                    .disabled(messageText.isEmpty || isSending)
                }
                .padding(12)
                .background(Color.black)
            }
        }
        .background(Color.black)
        .task {
            await fetchMessages()
        }
    }
    
    private func fetchMessages() async {
        isLoading = true
        error = nil
        
        do {
            let url = URL(string: "https://bsky.social/xrpc/app.bsky.feed.getDirectMessages")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(authModel.getAccessToken())", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let chatResponse = try JSONDecoder().decode(ChatListResponse.self, from: data)
            
            // Filter messages for this conversation
            let conversationMessages = chatResponse.messages.filter { message in
                (message.author.did == recipient.did || message.recipient?.did == recipient.did)
            }
            
            DispatchQueue.main.async {
                self.messages = conversationMessages
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription.lowercased()
                self.isLoading = false
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        guard !isSending else { return }
        
        let message = messageText
        messageText = ""
        isSending = true
        
        Task {
            do {
                let url = URL(string: "https://bsky.social/xrpc/app.bsky.feed.sendDirectMessage")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(authModel.getAccessToken())", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "recipientDid": recipient.did,
                    "text": message
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                
                // Fetch updated messages after sending
                await fetchMessages()
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription.lowercased()
                }
            }
            
            DispatchQueue.main.async {
                isSending = false
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isFromUser: Bool
    
    var body: some View {
        HStack {
            if isFromUser {
                Spacer()
            }
            
            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.custom("Courier", size: 16))
                    .foregroundColor(isFromUser ? .black : .green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isFromUser ? Color.green : Color.black)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.3), lineWidth: isFromUser ? 0 : 1)
                    )
                
                Text(message.formattedDate)
                    .font(.custom("Courier", size: 12))
                    .foregroundColor(.green.opacity(0.7))
            }
            
            if !isFromUser {
                Spacer()
            }
        }
    }
}

#Preview {
    ConversationView(
        recipient: Author(did: "preview", handle: "preview", displayName: "Preview User", avatar: nil),
        authModel: AuthModel()
    )
}
