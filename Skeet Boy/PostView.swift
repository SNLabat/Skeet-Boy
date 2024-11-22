import SwiftUI

struct PostView: View {
    let post: Post
    @ObservedObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    @State private var replies: [FeedViewPost] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showingReplySheet = false
    @State private var isLiking = false
    @State private var isReposting = false
    @State private var isLiked = false
    @State private var isReposted = false
    @State private var likeCount: Int
    @State private var repostCount: Int
    
    init(post: Post, authModel: AuthModel) {
        self.post = post
        self.authModel = authModel
        _likeCount = State(initialValue: post.likeCount)
        _repostCount = State(initialValue: post.repostCount)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                
                Text("POST")
                    .font(.custom("Courier", size: 20))
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
            
            ScrollView {
                VStack(spacing: 0) {
                    // Main Post
                    VStack(alignment: .leading, spacing: 12) {
                        // Author info
                        HStack {
                            AsyncImage(url: URL(string: post.author.avatar ?? "")) { image in
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
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(post.author.displayName ?? post.author.handle)
                                    .font(.custom("Courier", size: 16))
                                    .foregroundColor(.green)
                                
                                Text("@\(post.author.handle)")
                                    .font(.custom("Courier", size: 14))
                                    .foregroundColor(.green.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Text(post.formattedDate)
                                .font(.custom("Courier", size: 12))
                                .foregroundColor(.green.opacity(0.7))
                        }
                        
                        // Post content
                        Text(post.record.text)
                            .font(.custom("Courier", size: 16))
                            .foregroundColor(.green)
                        
                        // Interaction buttons
                        HStack(spacing: 20) {
                            InteractionButton(
                                iconName: "bubble.right",
                                count: post.replyCount,
                                action: { showingReplySheet = true }
                            )
                            
                            InteractionButton(
                                iconName: "arrow.2.squarepath",
                                count: repostCount,
                                isActive: isReposted,
                                isLoading: isReposting,
                                action: handleRepost
                            )
                            
                            InteractionButton(
                                iconName: "heart",
                                count: likeCount,
                                isActive: isLiked,
                                isLoading: isLiking,
                                action: handleLike
                            )
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color.black)
                    .overlay(
                        Rectangle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Replies
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                            .padding()
                    } else if let error = error {
                        Text("ERROR: \(error)")
                            .font(.custom("Courier", size: 14))
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        ForEach(replies) { reply in
                            TimelinePostView(post: reply.post)
                        }
                    }
                }
            }
        }
        .background(Color.black)
        .task {
            await fetchReplies()
        }
        .sheet(isPresented: $showingReplySheet) {
            ComposeView(authModel: authModel)
        }
    }
    
    private func fetchReplies() async {
        do {
            let url = URL(string: "https://bsky.social/xrpc/app.bsky.feed.getPostThread")!
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.queryItems = [
                URLQueryItem(name: "uri", value: post.uri)
            ]
            
            var request = URLRequest(url: components.url!)
            request.setValue("Bearer \(authModel.getAccessToken())", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let threadResponse = try JSONDecoder().decode(ThreadResponse.self, from: data)
            
            if let replies = threadResponse.thread.replies {
                DispatchQueue.main.async {
                    self.replies = replies.map { FeedViewPost(post: $0.post) }
                    self.isLoading = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription.lowercased()
                self.isLoading = false
            }
        }
    }
    
    private func handleLike() {
        // Existing like handling code
    }
    
    private func handleRepost() {
        // Existing repost handling code
    }
}

// Add these models to handle the thread response
struct ThreadResponse: Codable {
    let thread: ThreadView
}

struct ThreadView: Codable {
    let post: Post
    let replies: [ReplyView]?
}

struct ReplyView: Codable {
    let post: Post
}