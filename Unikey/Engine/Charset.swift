// Unikey Swift Engine
// Helper for Charset operations
// Ported/Adapted from charset.h
// Swift port by Jules

import Foundation

public struct Charset {
    public static func isUpper(_ char: Character) -> Bool {
        return char.isUppercase
    }

    public static func isLower(_ char: Character) -> Bool {
        return char.isLowercase
    }

    public static func toUpper(_ char: Character) -> Character {
        return Character(char.uppercased())
    }

    public static func toLower(_ char: Character) -> Character {
        return Character(char.lowercased())
    }
}
