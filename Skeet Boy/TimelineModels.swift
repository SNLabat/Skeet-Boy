import Foundation

// MARK: - Timeline Response
struct TimelineResponse: Codable {
    let cursor: String?
    let feed: [FeedViewPost]
}

// MARK: - Feed View Post
struct FeedViewPost: Identifiable, Codable {
    let post: Post
    
    var id: String {
        post.uri
    }
}

// MARK: - Post
struct Post: Codable {
    let uri: String
    let cid: String
    let author: Author
    let record: PostRecord
    let likeCount: Int
    let repostCount: Int
    let replyCount: Int
    let indexedAt: String
}

// MARK: - Author
struct Author: Codable {
    let did: String
    let handle: String
    let displayName: String?
    let avatar: String?
}

// MARK: - Post Record
struct PostRecord: Codable {
    let text: String
    let createdAt: String
}

// MARK: - Helper Extensions
extension Post {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = formatter.date(from: indexedAt) else { return "" }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let minutes = components.minute, minutes < 60 {
            return "\(minutes)m"
        } else if let hours = components.hour, hours < 24 {
            return "\(hours)h"
        } else if let days = components.day {
            return "\(days)d"
        }
        return ""
    }
}
