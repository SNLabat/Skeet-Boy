import SwiftUI

struct ProfileView: View {
    let did: String
    let handle: String
    @Environment(\.dismiss) private var dismiss
    @State private var profile: ProfileData?
    @State private var posts: [FeedViewPost] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var isFollowing = false
    @State private var selectedTab = "posts"
    @State private var replies: [FeedViewPost] = []
    @State private var media: [FeedViewPost] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                
                Text("VAULT DWELLER")
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
            
            if isLoading && profile == nil {
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
            } else if let profile = profile {
                ScrollView {
                    VStack(spacing: 16) {
                        // Profile Header
                        VStack(spacing: 12) {
                            AsyncImage(url: URL(string: profile.avatar ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.green.opacity(0.5), lineWidth: 2)
                                    )
                            } placeholder: {
                                Circle()
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: 80, height: 80)
                            }
                            
                            VStack(spacing: 4) {
                                Text(profile.displayName ?? handle)
                                    .font(.custom("Courier", size: 20))
                                    .foregroundColor(.green)
                                
                                Text("@\(handle)")
                                    .font(.custom("Courier", size: 14))
                                    .foregroundColor(.green.opacity(0.7))
                            }
                            
                            if let description = profile.description {
                                Text(description)
                                    .font(.custom("Courier", size: 14))
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Text("\(profile.followersCount)")
                                        .font(.custom("Courier", size: 16))
                                        .foregroundColor(.green)
                                    Text("followers")
                                        .font(.custom("Courier", size: 12))
                                        .foregroundColor(.green.opacity(0.7))
                                }
                                
                                VStack {
                                    Text("\(profile.followsCount)")
                                        .font(.custom("Courier", size: 16))
                                        .foregroundColor(.green)
                                    Text("following")
                                        .font(.custom("Courier", size: 12))
                                        .foregroundColor(.green.opacity(0.7))
                                }
                                
                                VStack {
                                    Text("\(profile.postsCount)")
                                        .font(.custom("Courier", size: 16))
                                        .foregroundColor(.green)
                                    Text("posts")
                                        .font(.custom("Courier", size: 12))
                                        .foregroundColor(.green.opacity(0.7))
                                }
                            }
                            .padding(.vertical)
                        }
                        .padding()
                        .background(Color.black)
                        .overlay(
                            Rectangle()
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Add Follow Button after stats
                        Button(action: { Task { await toggleFollow() } }) {
                            Text(isFollowing ? "Unfollow" : "Follow")
                                .font(.custom("Courier", size: 16))
                                .foregroundColor(.black)
                                .frame(width: 120, height: 32)
                                .background(Color.green)
                                .cornerRadius(16)
                        }
                        .padding(.bottom)
                        
                        // Add Tab Picker
                        HStack(spacing: 20) {
                            ForEach(["posts", "replies", "media"], id: \.self) { tab in
                                Button(action: { 
                                    selectedTab = tab
                                    if tab == "replies" && replies.isEmpty {
                                        Task { await fetchReplies() }
                                    } else if tab == "media" && media.isEmpty {
                                        Task { await fetchMedia() }
                                    }
                                }) {
                                    Text(tab.capitalized)
                                        .font(.custom("Courier", size: 14))
                                        .foregroundColor(selectedTab == tab ? .green : .green.opacity(0.5))
                                }
                            }
                        }
                        .padding(.vertical)
                        
                        // Modified Posts Section
                        LazyVStack(spacing: 1) {
                            switch selectedTab {
                            case "posts":
                                ForEach(posts) { feedPost in
                                    TimelinePostView(post: feedPost.post)
                                }
                            case "replies":
                                ForEach(replies) { feedPost in
                                    TimelinePostView(post: feedPost.post)
                                }
                            case "media":
                                ForEach(media) { feedPost in
                                    TimelinePostView(post: feedPost.post)
                                }
                            default:
                                EmptyView()
                            }
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .background(Color.black)
        .task {
            await fetchProfile()
            await checkFollowStatus()
        }
    }
    
    private func fetchProfile() async {
        isLoading = true
        error = nil
        
        do {
            async let profileData = fetchProfileData()
            async let postsData = fetchUserPosts()
            
            let (profile, posts) = try await (profileData, postsData)
            
            DispatchQueue.main.async {
                self.profile = profile
                self.posts = posts
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription.lowercased()
                self.isLoading = false
            }
        }
    }
    
    private func fetchProfileData() async throws -> ProfileData {
        let url = URL(string: "https://bsky.social/xrpc/app.bsky.actor.getProfile")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [URLQueryItem(name: "actor", value: did)]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(AuthModel.shared.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ProfileData.self, from: data)
    }
    
    private func fetchUserPosts() async throws -> [FeedViewPost] {
        let url = URL(string: "https://bsky.social/xrpc/app.bsky.feed.getAuthorFeed")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [URLQueryItem(name: "actor", value: did)]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(AuthModel.shared.getAccessToken())", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TimelineResponse.self, from: data)
        return response.feed
    }
    
    private func checkFollowStatus() async {
        do {
            let url = URL(string: "https://bsky.social/xrpc/app.bsky.graph.getFollows")!
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.queryItems = [
                URLQueryItem(name: "actor", value: UserDefaults.standard.string(forKey: "userDID")),
                URLQueryItem(name: "limit", value: "100")
            ]
            
            var request = URLRequest(url: components.url!)
            request.setValue("Bearer \(AuthModel.shared.getAccessToken())", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(FollowsResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.isFollowing = response.follows.contains { $0.did == self.did }
            }
        } catch {
            print("Error checking follow status: \(error)")
        }
    }
    
    private func toggleFollow() async {
        do {
            let url = URL(string: "https://bsky.social/xrpc/app.bsky.graph.\(isFollowing ? "unfollow" : "follow")")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(AuthModel.shared.getAccessToken())", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["subject": did]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                DispatchQueue.main.async {
                    self.isFollowing.toggle()
                    if self.profile != nil {
                        self.profile?.followersCount += self.isFollowing ? 1 : -1
                    }
                }
            }
        } catch {
            print("Error toggling follow: \(error)")
        }
    }
    
    private func fetchReplies() async {
        do {
            let url = URL(string: "https://bsky.social/xrpc/app.bsky.feed.getAuthorFeed")!
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.queryItems = [
                URLQueryItem(name: "actor", value: did),
                URLQueryItem(name: "filter", value: "replies")
            ]
            
            var request = URLRequest(url: components.url!)
            request.setValue("Bearer \(AuthModel.shared.getAccessToken())", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(TimelineResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.replies = response.feed
            }
        } catch {
            print("Error fetching replies: \(error)")
        }
    }
    
    private func fetchMedia() async {
        do {
            let url = URL(string: "https://bsky.social/xrpc/app.bsky.feed.getAuthorFeed")!
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.queryItems = [
                URLQueryItem(name: "actor", value: did),
                URLQueryItem(name: "filter", value: "posts_with_media")
            ]
            
            var request = URLRequest(url: components.url!)
            request.setValue("Bearer \(AuthModel.shared.getAccessToken())", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(TimelineResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.media = response.feed
            }
        } catch {
            print("Error fetching media: \(error)")
        }
    }
}

struct ProfileData: Codable {
    let did: String
    let handle: String
    let displayName: String?
    let description: String?
    let avatar: String?
    var followersCount: Int
    let followsCount: Int
    let postsCount: Int
}

struct FollowsResponse: Codable {
    let follows: [FollowEntry]
}

struct FollowEntry: Codable {
    let did: String
    let handle: String
}