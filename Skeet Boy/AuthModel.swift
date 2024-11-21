import Foundation

struct AuthResponse: Codable {
    let accessJwt: String
    let refreshJwt: String
    let handle: String
    let did: String
}

class AuthModel: ObservableObject {
    @Published var isAuthenticated = false
    private let baseURL = "https://bsky.social/xrpc/"
    private var session: AuthResponse?
    
    func login(identifier: String, password: String) async throws {
        let endpoint = "com.atproto.server.createSession"
        guard let url = URL(string: baseURL + endpoint) else {
            throw URLError(.badURL)
        }
        
        let body = [
            "identifier": identifier,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        DispatchQueue.main.async {
            self.session = response
            self.isAuthenticated = true
            // Store tokens in UserDefaults for persistence
            UserDefaults.standard.set(response.accessJwt, forKey: "accessJwt")
            UserDefaults.standard.set(response.refreshJwt, forKey: "refreshJwt")
            UserDefaults.standard.set(response.handle, forKey: "handle")
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "accessJwt")
        UserDefaults.standard.removeObject(forKey: "refreshJwt")
        UserDefaults.standard.removeObject(forKey: "handle")
        DispatchQueue.main.async {
            self.session = nil
            self.isAuthenticated = false
        }
    }
    
    func getStoredCredentials() {
        if let accessJwt = UserDefaults.standard.string(forKey: "accessJwt"),
           let refreshJwt = UserDefaults.standard.string(forKey: "refreshJwt"),
           let handle = UserDefaults.standard.string(forKey: "handle") {
            let storedSession = AuthResponse(
                accessJwt: accessJwt,
                refreshJwt: refreshJwt,
                handle: handle,
                did: "" // We don't need to store the DID for basic functionality
            )
            self.session = storedSession
            self.isAuthenticated = true
        }
    }
    
    func getAccessToken() -> String {
        return session?.accessJwt ?? UserDefaults.standard.string(forKey: "accessJwt") ?? ""
    }
}
