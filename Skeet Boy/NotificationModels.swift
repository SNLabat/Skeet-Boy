import Foundation

struct NotificationResponse: Codable {
    let notifications: [NotificationItem]
    let cursor: String?
}

struct NotificationItem: Identifiable, Codable {
    let uri: String
    let cid: String
    let author: Author
    let reason: String // like, reply, mention, repost, follow, quote
    let reasonSubject: String?
    let record: NotificationRecord
    let isRead: Bool
    let indexedAt: String
    
    var id: String { uri }
}

struct NotificationRecord: Codable {
    let text: String?
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case text
        case type = "$type"
    }
}

extension NotificationItem {
    var reasonText: String {
        switch reason {
        case "like":
            return "liked your post"
        case "repost":
            return "reposted your post"
        case "follow":
            return "followed you"
        case "mention":
            return "mentioned you"
        case "reply":
            return "replied to your post"
        case "quote":
            return "quoted your post"
        default:
            return "interacted with you"
        }
    }
    
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
