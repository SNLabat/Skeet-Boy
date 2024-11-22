import Foundation

class PostInteractionModel {
    static func like(uri: String, cid: String, accessToken: String) async throws {
        // Use the correct URL
        let url = URL(string: "https://bsky.social/xrpc/com.atproto.repo.createRecord")!
        var request = URLRequest(url: url)
        
        let userDID = UserDefaults.standard.string(forKey: "userDID") ?? ""
        print("Using DID: \(userDID)")
        
        // Format the record exactly as the API expects
        let record: [String: Any] = [
            "collection": "app.bsky.feed.like",
            "repo": userDID,
            "record": [
                "$type": "app.bsky.feed.like",
                "subject": [
                    "uri": uri,
                    "cid": cid
                ],
                "createdAt": ISO8601DateFormatter().string(from: Date())
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: record)
        print("Request Body: \(String(data: jsonData, encoding: .utf8) ?? "")")
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Error response: \(errorJson)")
                if let message = errorJson["message"] as? String {
                    throw NSError(domain: "BlueskyError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
                }
            }
            throw URLError(.badServerResponse)
        }
    }
    
    static func repost(uri: String, cid: String, accessToken: String) async throws {
        let url = URL(string: "https://bsky.social/xrpc/com.atproto.repo.createRecord")!
        var request = URLRequest(url: url)
        
        let userDID = UserDefaults.standard.string(forKey: "userDID") ?? ""
        print("Using DID: \(userDID)")
        
        let record: [String: Any] = [
            "collection": "app.bsky.feed.repost",
            "repo": userDID,
            "record": [
                "$type": "app.bsky.feed.repost",
                "subject": [
                    "uri": uri,
                    "cid": cid
                ],
                "createdAt": ISO8601DateFormatter().string(from: Date())
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: record)
        print("Request Body: \(String(data: jsonData, encoding: .utf8) ?? "")")
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Error response: \(errorJson)")
                if let message = errorJson["message"] as? String {
                    throw NSError(domain: "BlueskyError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
                }
            }
            throw URLError(.badServerResponse)
        }
    }
}
