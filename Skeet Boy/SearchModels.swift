import Foundation

struct SearchResponse: Codable {
    let actors: [SearchActor]
    let cursor: String?
}

struct SearchActor: Identifiable, Codable {
    let did: String
    let handle: String
    let displayName: String?
    let description: String?
    let avatar: String?
    let indexedAt: String
    let viewer: ViewerState?
    
    var id: String { did }
}

struct ViewerState: Codable {
    let muted: Bool?
    let blockedBy: Bool?
    let following: String? // DID of the follow record
    let followedBy: String? // DID of the follow record
}
