import SwiftUI

struct TimelineView: View {
    @ObservedObject var authModel: AuthModel
    @State private var posts: [FeedViewPost] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var cursor: String?
    @State private var showingComposeSheet = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("WASTELAND FEED")
                        .font(.custom("Courier", size: 20))
                        .foregroundColor(.green)
                        .shadow(color: .green.opacity(0.5), radius: 5)
                    
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
                
                // Content
                ZStack {
                    if isLoading && posts.isEmpty {
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
                                    await fetchPosts(refresh: true)
                                }
                            }
                            .foregroundColor(.green)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 1) {
                                ForEach(posts) { feedPost in
                                    TimelinePostView(post: feedPost.post)
                                }
                                
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                        .padding()
                                }
                            }
                        }
                        .refreshable {
                            await fetchPosts(refresh: true)
                        }
                    }
                }
            }
            
            // Compose Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ComposeButton(action: {
                        showingComposeSheet = true
                    })
                }
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showingComposeSheet) {
            // Refresh timeline when compose sheet is dismissed
            Task {
                await fetchPosts(refresh: true)
            }
        } content: {
            ComposeView(authModel: authModel)
        }
        .task {
            await fetchPosts()
        }
    }
    
    private func fetchPosts(refresh: Bool = false) async {
        if refresh {
            cursor = nil
            posts = []
        }
        
        isLoading = true
        error = nil
        
        do {
            let url = URL(string: "https://bsky.social/xrpc/app.bsky.feed.getTimeline")!
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            
            if let cursor = cursor {
                components.queryItems = [URLQueryItem(name: "cursor", value: cursor)]
            }
            
            var request = URLRequest(url: components.url!)
            request.setValue("Bearer \(authModel.getAccessToken())", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let timelineResponse = try JSONDecoder().decode(TimelineResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.posts.append(contentsOf: timelineResponse.feed)
                self.cursor = timelineResponse.cursor
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

struct TimelinePostView: View {
    let post: Post
    @State private var showingPostView = false
    @State private var showingProfile = false
    @State private var showingReplySheet = false
    @State private var isReposting = false
    @State private var isLiking = false
    @State private var error: String?
    @State private var isLiked = false
    @State private var isReposted = false
    @State private var likeCount: Int
    @State private var repostCount: Int
    
    init(post: Post) {
        self.post = post
        _likeCount = State(initialValue: post.likeCount)
        _repostCount = State(initialValue: post.repostCount)
    }
    
    var body: some View {
        Button(action: { showingPostView = true }) {
            VStack(alignment: .leading, spacing: 8) {
                // Author and timestamp
                HStack {
                    Button(action: {
                        showingProfile = true
                    }) {
                        AsyncImage(url: URL(string: post.author.avatar ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .fill(Color.green.opacity(0.2))
                                )
                        } placeholder: {
                            Circle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(.trailing, 8)
                    
                    Button(action: {
                        showingProfile = true
                    }) {
                        VStack(alignment: .leading) {
                            Text(post.author.displayName ?? post.author.handle)
                                .font(.custom("Courier", size: 14))
                                .foregroundColor(.green)
                                .lineLimit(1)
                            
                            Text("@\(post.author.handle)")
                                .font(.custom("Courier", size: 12))
                                .foregroundColor(.green.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Text(post.formattedDate)
                        .font(.custom("Courier", size: 12))
                        .foregroundColor(.green.opacity(0.7))
                }
                
                // Content
                Text(post.record.text)
                    .font(.custom("Courier", size: 16))
                    .foregroundColor(.green)
                    .multilineTextAlignment(.leading)
                
                // Add error display
                if let error = error {
                    Text(error)
                        .font(.custom("Courier", size: 12))
                        .foregroundColor(.red)
                        .padding(.vertical, 4)
                }
                
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
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.black)
            .overlay(
                Rectangle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(did: post.author.did, handle: post.author.handle)
        }
        .sheet(isPresented: $showingReplySheet) {
            ComposeReplyView(authModel: AuthModel.shared, replyTo: post)
        }
        .sheet(isPresented: $showingPostView) {
            PostView(post: post, authModel: AuthModel.shared)
        }
    }
    
    private func handleLike() {
        guard !isLiking else { return }
        
        guard let accessToken = UserDefaults.standard.string(forKey: "accessJwt"),
              !accessToken.isEmpty else {
            self.error = "not logged in"
            return
        }
        
        isLiking = true
        error = nil
        
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.prepare()
        
        Task {
            do {
                try await PostInteractionModel.like(
                    uri: post.uri,
                    cid: post.cid,
                    accessToken: accessToken
                )
                DispatchQueue.main.async {
                    self.isLiked = true
                    self.likeCount += 1
                    impactGenerator.impactOccurred()
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    if error.domain == "BlueskyError" {
                        self.error = error.localizedDescription
                    } else {
                        self.error = "like failed: network error"
                    }
                    let errorGenerator = UINotificationFeedbackGenerator()
                    errorGenerator.notificationOccurred(.error)
                }
            }
            
            DispatchQueue.main.async {
                isLiking = false
            }
        }
    }
    
    private func handleRepost() {
        guard !isReposting else { return }
        
        guard let accessToken = UserDefaults.standard.string(forKey: "accessJwt"),
              !accessToken.isEmpty else {
            self.error = "not logged in"
            return
        }
        
        isReposting = true
        error = nil
        
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.prepare()
        
        Task {
            do {
                try await PostInteractionModel.repost(
                    uri: post.uri,
                    cid: post.cid,
                    accessToken: accessToken
                )
                DispatchQueue.main.async {
                    self.isReposted = true
                    self.repostCount += 1
                    impactGenerator.impactOccurred()
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    if error.domain == "BlueskyError" {
                        self.error = error.localizedDescription
                    } else {
                        self.error = "repost failed: network error"
                    }
                    let errorGenerator = UINotificationFeedbackGenerator()
                    errorGenerator.notificationOccurred(.error)
                }
            }
            
            DispatchQueue.main.async {
                isReposting = false
            }
        }
    }
}

struct InteractionButton: View {
    let iconName: String
    let count: Int
    var isActive: Bool = false
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: iconName == "heart" && isActive ? "heart.fill" : iconName)
                        .foregroundColor(.green)
                        .fontWeight(isActive && iconName != "heart" ? .bold : .regular)
                }
                Text("\(count)")
                    .font(.custom("Courier", size: 12))
                    .foregroundColor(.green.opacity(0.7))
            }
        }
    }
}

#Preview {
    TimelineView(authModel: AuthModel())
}