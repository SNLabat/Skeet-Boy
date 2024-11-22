import Foundation

class PostModel {
    static func createPost(text: String, accessToken: String) async throws {
        let url = URL(string: "https://bsky.social/xrpc/com.atproto.repo.createRecord")!
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let now = ISO8601DateFormatter().string(from: Date())
        
        let postRecord: [String: Any] = [
            "repo": try AuthModel.getDid(),
            "collection": "app.bsky.feed.post",
            "record": [
                "$type": "app.bsky.feed.post",
                "text": text,
                "createdAt": now,
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: postRecord)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}

// Extension to get DID from UserDefaults
extension AuthModel {
    static func getDid() throws -> String {
        guard let did = UserDefaults.standard.string(forKey: "userDID") else {
            throw URLError(.userAuthenticationRequired)
        }
        return did
    }
}