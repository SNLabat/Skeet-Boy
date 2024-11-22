import SwiftUI

final class UserSettings: ObservableObject {
    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "isSoundEnabled")
        }
    }
    @Published var isCRTModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isCRTModeEnabled, forKey: "isCRTModeEnabled")
        }
    }
    
    init() {
        self.isSoundEnabled = UserDefaults.standard.bool(forKey: "isSoundEnabled", defaultValue: true)
        self.isCRTModeEnabled = UserDefaults.standard.bool(forKey: "isCRTModeEnabled", defaultValue: false)
    }
}

extension UserDefaults {
    func bool(forKey defaultName: String, defaultValue: Bool) -> Bool {
        if object(forKey: defaultName) == nil {
            set(defaultValue, forKey: defaultName)
            return defaultValue
        }
        return bool(forKey: defaultName)
    }
} 