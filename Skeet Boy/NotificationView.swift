import SwiftUI

struct NotificationView: View {
    @ObservedObject var authModel: AuthModel
    @State private var notifications: [NotificationItem] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var cursor: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("VAULT ALERTS")
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
                if isLoading && notifications.isEmpty {
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
                                await fetchNotifications(refresh: true)
                            }
                        }
                        .foregroundColor(.green)
                    }
                } else if notifications.isEmpty {
                    Text("NO ALERTS DETECTED")
                        .font(.custom("Courier", size: 16))
                        .foregroundColor(.green.opacity(0.7))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(notifications) { notification in
                                NotificationItemView(notification: notification)
                                    .onAppear {
                                        if notifications.last?.id == notification.id && !isLoading {
                                            Task {
                                                await fetchNotifications()
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
                    .refreshable {
                        await fetchNotifications(refresh: true)
                    }
                }
            }
        }
        .background(Color.black)
        .task {
            await fetchNotifications()
        }
    }
    
    private func fetchNotifications(refresh: Bool = false) async {
        if refresh {
            cursor = nil
            notifications = []
        }
        
        isLoading = true
        error = nil
        
        do {
            let url = URL(string: "https://bsky.social/xrpc/app.bsky.notification.listNotifications")!
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
            
            let notificationResponse = try JSONDecoder().decode(NotificationResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.notifications.append(contentsOf: notificationResponse.notifications)
                self.cursor = notificationResponse.cursor
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

struct NotificationItemView: View {
    let notification: NotificationItem
    @State private var showingProfile = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author and timestamp
            HStack {
                Button(action: {
                    showingProfile = true
                }) {
                    AsyncImage(url: URL(string: notification.author.avatar ?? "")) { image in
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Text(notification.author.displayName ?? notification.author.handle)
                            .font(.custom("Courier", size: 14))
                            .foregroundColor(.green)
                            .lineLimit(1)
                    }
                    
                    Text(notification.reasonText)
                        .font(.custom("Courier", size: 12))
                        .foregroundColor(.green.opacity(0.7))
                }
                
                Spacer()
                
                Text(notification.formattedDate)
                    .font(.custom("Courier", size: 12))
                    .foregroundColor(.green.opacity(0.7))
            }
            
            if let text = notification.record.text {
                Text(text)
                    .font(.custom("Courier", size: 14))
                    .foregroundColor(.green)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .opacity(notification.isRead ? 0.7 : 1.0)
        .sheet(isPresented: $showingProfile) {
            ProfileView(did: notification.author.did, handle: notification.author.handle)
        }
    }
}

#Preview {
    NotificationView(authModel: AuthModel())
}
