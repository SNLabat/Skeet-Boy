import SwiftUI

struct TimelineView: View {
    @ObservedObject var authModel: AuthModel
    @State private var posts: [FeedViewPost] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var cursor: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("WASTELAND FEED")
                    .font(.custom("Courier", size: 20))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.5), radius: 5)
                
                Spacer()
                
                Button(action: { authModel.logout() }) {
                    Text("logout")
                        .font(.custom("Courier", size: 14))
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
        .background(Color.black)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author and timestamp
            HStack {
                Text(post.author.displayName ?? post.author.handle)
                    .font(.custom("Courier", size: 14))
                    .foregroundColor(.green)
                    .lineLimit(1)
                
                Text("@\(post.author.handle)")
                    .font(.custom("Courier", size: 12))
                    .foregroundColor(.green.opacity(0.7))
                    .lineLimit(1)
                
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
            
            // Interaction buttons
            HStack(spacing: 20) {
                InteractionButton(iconName: "bubble.right", count: post.replyCount)
                InteractionButton(iconName: "arrow.2.squarepath", count: post.repostCount)
                InteractionButton(iconName: "heart", count: post.likeCount)
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
}

struct InteractionButton: View {
    let iconName: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .foregroundColor(.green)
            Text("\(count)")
                .font(.custom("Courier", size: 12))
                .foregroundColor(.green.opacity(0.7))
        }
    }
}

#Preview {
    TimelineView(authModel: AuthModel())
}
