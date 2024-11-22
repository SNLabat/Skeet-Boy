import Foundation

struct ChatListResponse: Codable {
    let messages: [ChatMessage]
    let cursor: String?
}

struct ChatMessage: Identifiable, Codable {
    let uri: String
    let author: Author
    let recipient: Author?
    let text: String
    let createdAt: String
    
    var id: String { uri }
}

struct NewChatUser: Identifiable {
    let author: Author
    let canMessage: Bool
    
    var id: String { author.did }
}

extension ChatMessage {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = formatter.date(from: createdAt) else { return "" }
        
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
