import SwiftUI

struct NewChatView: View {
    @ObservedObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [SearchActor] = []
    @State private var isLoading = false
    @State private var error: String?
    @FocusState private var isSearchFocused: Bool
    @State private var showingConversation = false
    @State private var selectedUser: (did: String, handle: String, displayName: String?, avatar: String?)?
    
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
                
                Text("NEW MESSAGE")
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
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.green)
                
                TextField("Search", text: $searchText)
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
            .padding(.vertical, 8)
            
            // Results
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        .scaleEffect(1.5)
                } else if let error = error {
                    Text("ERROR: \(error)")
                        .font(.custom("Courier", size: 14))
                        .foregroundColor(.red)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Text("NO USERS FOUND")
                        .font(.custom("Courier", size: 16))
                        .foregroundColor(.green.opacity(0.7))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(searchResults) { user in
                                SearchResultRow(user: user)
                                    .onTapGesture {
                                        selectedUser = (user.did, user.handle, user.displayName, user.avatar)
                                        showingConversation = true
                                        dismiss()
                                    }
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
        .onChange(of: searchText) { oldText, newText in
            if !newText.isEmpty {
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await searchUsers()
                }
            } else {
                searchResults = []
            }
        }
        .sheet(isPresented: $showingConversation) {
            if let user = selectedUser {
                ConversationView(
                    recipient: Author(
                        did: user.did,
                        handle: user.handle,
                        displayName: user.displayName,
                        avatar: user.avatar
                    ),
                    authModel: authModel
                )
            }
        }
    }
    
    private func searchUsers() async {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        error = nil
        
        do {
            let url = URL(string: "https://bsky.social/xrpc/app.bsky.actor.searchActors")!
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.queryItems = [
                URLQueryItem(name: "term", value: searchText),
                URLQueryItem(name: "limit", value: "25")
            ]
            
            var request = URLRequest(url: components.url!)
            request.setValue("Bearer \(authModel.getAccessToken())", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.searchResults = searchResponse.actors
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

struct SearchResultRow: View {
    let user: SearchActor
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
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
                Text(user.displayName ?? user.handle)
                    .font(.custom("Courier", size: 16))
                    .foregroundColor(.green)
                
                Text("@\(user.handle)")
                    .font(.custom("Courier", size: 14))
                    .foregroundColor(.green.opacity(0.7))
            }
            
            Spacer()
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
    NewChatView(authModel: AuthModel())
}
