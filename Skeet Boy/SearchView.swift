import SwiftUI

struct SearchView: View {
    @ObservedObject var authModel: AuthModel
    @State private var searchText = ""
    @State private var searchResults: [SearchActor] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var cursor: String?
    @State private var showingProfile = false
    @State private var selectedProfile: (did: String, handle: String)?
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed Header and Search Bar
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("VAULT SEARCH")
                        .font(.custom("Courier", size: 20))
                        .foregroundColor(.green)
                        .shadow(color: .green.opacity(0.5), radius: 5)
                    
                    Spacer()
                }
                .padding()
                .background(Color.black)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.green)
                    
                    TextField("search vault dwellers...", text: $searchText)
                        .font(.custom("Courier", size: 16))
                        .foregroundColor(.green)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isSearchFocused)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color.black)
                .overlay(
                    Rectangle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
            }
            .background(Color.black)
            
            // Results
            ScrollView {
                ZStack {
                    if isLoading && searchResults.isEmpty {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                            .scaleEffect(1.5)
                    } else if let error = error {
                        VStack {
                            Text("ERROR: \(error)")
                                .font(.custom("Courier", size: 14))
                                .foregroundColor(.red)
                        }
                    } else if !searchText.isEmpty && searchResults.isEmpty {
                        Text("NO DWELLERS FOUND")
                            .font(.custom("Courier", size: 16))
                            .foregroundColor(.green.opacity(0.7))
                    } else {
                        LazyVStack(spacing: 1) {
                            ForEach(searchResults) { actor in
                                SearchResultView(actor: actor)
                                    .onTapGesture {
                                        selectedProfile = (actor.did, actor.handle)
                                        showingProfile = true
                                    }
                                    .onAppear {
                                        if searchResults.last?.id == actor.id && !isLoading {
                                            Task {
                                                await search()
                                            }
                                        }
                                    }
                            }
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                    .padding()
                            }
                        }
                    }
                }
            }
            .gesture(DragGesture().onChanged { _ in
                isSearchFocused = false
            })
        }
        .background(Color.black)
        .sheet(isPresented: $showingProfile) {
            if let profile = selectedProfile {
                ProfileView(did: profile.did, handle: profile.handle)
            }
        }
        .onChange(of: searchText) { oldText, newText in
            if !newText.isEmpty {
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second debounce
                    await search(refresh: true)
                }
            }
        }
    }
    
    private func search(refresh: Bool = false) async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        if refresh {
            cursor = nil
            searchResults = []
        }
        
        isLoading = true
        error = nil
        
        do {
            let url = URL(string: "https://bsky.social/xrpc/app.bsky.actor.searchActors")!
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            
            components.queryItems = [
                URLQueryItem(name: "term", value: searchText),
                URLQueryItem(name: "limit", value: "25")
            ]
            
            if let cursor = cursor {
                components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor))
            }
            
            var request = URLRequest(url: components.url!)
            request.setValue("Bearer \(authModel.getAccessToken())", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.searchResults.append(contentsOf: searchResponse.actors)
                self.cursor = searchResponse.cursor
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

struct SearchResultView: View {
    let actor: SearchActor
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: actor.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            } placeholder: {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 50, height: 50)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(actor.displayName ?? actor.handle)
                    .font(.custom("Courier", size: 16))
                    .foregroundColor(.green)
                
                Text("@\(actor.handle)")
                    .font(.custom("Courier", size: 14))
                    .foregroundColor(.green.opacity(0.7))
                
                if let description = actor.description, !description.isEmpty {
                    Text(description)
                        .font(.custom("Courier", size: 12))
                        .foregroundColor(.green.opacity(0.7))
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Following Status
            if let viewer = actor.viewer {
                if viewer.following != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
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
    SearchView(authModel: AuthModel())
}
