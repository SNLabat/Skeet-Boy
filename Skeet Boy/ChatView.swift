import SwiftUI

struct ChatView: View {
    @ObservedObject var authModel: AuthModel
    @State private var chats: [ChatMessage] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showingNewChat = false
    @State private var selectedUser: Author?
    @State private var showingConversation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("COMMUNICATIONS")
                    .font(.custom("Courier", size: 20))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.5), radius: 5)
                
                Spacer()
                
                Button(action: {
                    showingNewChat = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.black)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.green.opacity(0.3)),
                alignment: .bottom
            )
            
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        .scaleEffect(1.5)
                } else if let error = error {
                    VStack {
                        Text("ERROR: \(error)")
                            .font(.custom("Courier", size: 14))
                            .foregroundColor(.red)
                        Button("retry") {
                            Task {
                                await fetchChats()
                            }
                        }
                        .foregroundColor(.green)
                    }
                } else if chats.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green.opacity(0.5))
                        
                        Text("Nothing here")
                            .font(.custom("Courier", size: 20))
                            .foregroundColor(.green)
                        
                        Text("You have no conversations yet. Start one!")
                            .font(.custom("Courier", size: 14))
                            .foregroundColor(.green.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingNewChat = true
                        }) {
                            Text("Say hello!")
                                .font(.custom("Courier", size: 16))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .cornerRadius(20)
                        }
                        .padding(.top)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(chats) { chat in
                                if let recipient = chat.recipient {
                                    ChatRowView(chat: chat)
                                        .onTapGesture {
                                            selectedUser = recipient
                                            showingConversation = true
                                        }
                                }
                            }
                        }
                    }
                    .refreshable {
                        await fetchChats()
                    }
                }
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showingNewChat) {
            NewChatView(authModel: authModel)
        }
        .sheet(isPresented: $showingConversation) {
            if let user = selectedUser {
                ConversationView(recipient: user, authModel: authModel)
            }
        }
        .task {
            await fetchChats()
        }
    }
    
    private func fetchChats() async {
        isLoading = true
        error = nil
        
        do {
            let url = URL(string: "https://bsky.social/xrpc/app.bsky.feed.getDirectMessages")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(authModel.getAccessToken())", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard httpResponse.statusCode == 200 else {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorJson["message"] as? String {
                    throw NSError(domain: "BlueskyError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                }
                throw URLError(.badServerResponse)
            }
            
            let chatResponse = try JSONDecoder().decode(ChatListResponse.self, from: data)
            
            DispatchQueue.main.async {
                // Group messages by conversation
                let groupedChats = Dictionary(grouping: chatResponse.messages) { message in
                    message.recipient?.did ?? message.author.did
                }
                
                // Take the most recent message from each conversation
                self.chats = groupedChats.compactMap { $0.value.first }
                    .sorted { $0.createdAt > $1.createdAt }
                
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription.lowercased()
                self.isLoading = false
            }
        }
    }
}

struct ChatRowView: View {
    let chat: ChatMessage
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let recipient = chat.recipient {
                AsyncImage(url: URL(string: recipient.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 50, height: 50)
                }
            }
            
            // Message preview
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.recipient?.displayName ?? chat.recipient?.handle ?? "Unknown")
                        .font(.custom("Courier", size: 16))
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text(chat.formattedDate)
                        .font(.custom("Courier", size: 12))
                        .foregroundColor(.green.opacity(0.7))
                }
                
                Text(chat.text)
                    .font(.custom("Courier", size: 14))
                    .foregroundColor(.green.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ChatView(authModel: AuthModel())
}
