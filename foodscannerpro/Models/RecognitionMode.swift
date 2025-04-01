import Foundation

public enum RecognitionMode: String, CaseIterable {
    case standard = "Standard"
    case enhanced = "Enhanced"
    case api = "API"
    case combined = "Combined"
    
    // UserDefaults key
    private static let userDefaultsKey = "LastSelectedRecognitionMode"
    
    // Save the selected mode
    public static func saveLastSelected(_ mode: RecognitionMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: userDefaultsKey)
    }
    
    // Get the last selected mode, defaulting to standard if none was saved
    public static func getLastSelected() -> RecognitionMode {
        guard let savedMode = UserDefaults.standard.string(forKey: userDefaultsKey),
              let mode = RecognitionMode(rawValue: savedMode) else {
            return .standard
        }
        return mode
    }
} 