// Unikey Swift Engine - Input Methods
// Ported from x-unikey-1.0.4/src/ukengine/inputproc.cpp
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Gemini

import Foundation

/// Vietnamese input methods
public enum InputMethod: Int, CaseIterable {
  case telex = 0
  case vni
  case viqr
  case msVi
  case simpleTelex
  case user
}

/// Key event types - what action a key triggers
public enum KeyEventType: Int {
  // Roof (^) operations
  case roofAll = 0  // Add roof to any vowel
  case roof_a  // a -> â
  case roof_e  // e -> ê
  case roof_o  // o -> ô

  // Hook/Horn operations
  case hookAll  // Add hook to u/o
  case hook_uo  // u/o -> ư/ơ (combined)
  case hook_u  // u -> ư
  case hook_o  // o -> ơ
  case bowl  // a -> ă (breve)

  // Đ operation
  case dd  // d -> đ

  // Tone operations
  case tone0  // Remove tone
  case tone1  // Sắc (´)
  case tone2  // Huyền (`)
  case tone3  // Hỏi (?)
  case tone4  // Ngã (~)
  case tone5  // Nặng (.)

  // Special
  case telex_w  // Telex W key (special handling)
  case mapChar  // Direct character mapping
  case escChar  // Escape character (VIQR)
  case normal  // Normal character input

  case count  // Total count
}

/// Character type classification
public enum CharType: Int {
  case vn  // Vietnamese character
  case wordBreak  // Word break (space, punctuation)
  case nonVn  // Non-Vietnamese
  case reset  // Reset buffer
}

/// Key event structure
public struct KeyEvent {
  public var eventType: KeyEventType
  public var charType: CharType
  public var vnSymbol: VnLexiName  // Meaningful when charType == .vn
  public var keyCode: UInt32
  public var tone: Int  // Meaningful for vowels

  public init(
    eventType: KeyEventType = .normal,
    charType: CharType = .nonVn,
    vnSymbol: VnLexiName = .nonVnChar,
    keyCode: UInt32 = 0,
    tone: Int = 0
  ) {
    self.eventType = eventType
    self.charType = charType
    self.vnSymbol = vnSymbol
    self.keyCode = keyCode
    self.tone = tone
  }
}

/// Key mapping entry
public struct KeyMapping {
  public let key: Character
  public let action: KeyEventType

  public init(_ key: Character, _ action: KeyEventType) {
    self.key = key
    self.action = action
  }
}

// MARK: - Input Method Mappings

/// Telex input method mapping
public let telexMapping: [KeyMapping] = [
  KeyMapping("z", .tone0),
  KeyMapping("s", .tone1),
  KeyMapping("f", .tone2),
  KeyMapping("r", .tone3),
  KeyMapping("x", .tone4),
  KeyMapping("j", .tone5),
  KeyMapping("w", .telex_w),
  KeyMapping("a", .roof_a),
  KeyMapping("e", .roof_e),
  KeyMapping("o", .roof_o),
  KeyMapping("d", .dd),
  KeyMapping("[", .mapChar),  // [ -> ơ
  KeyMapping("]", .mapChar),  // ] -> ư
]

/// Simple Telex mapping (W acts as hookAll)
public let simpleTelexMapping: [KeyMapping] = [
  KeyMapping("z", .tone0),
  KeyMapping("s", .tone1),
  KeyMapping("f", .tone2),
  KeyMapping("r", .tone3),
  KeyMapping("x", .tone4),
  KeyMapping("j", .tone5),
  KeyMapping("w", .hookAll),
  KeyMapping("a", .roof_a),
  KeyMapping("e", .roof_e),
  KeyMapping("o", .roof_o),
  KeyMapping("d", .dd),
]

/// VNI input method mapping
public let vniMapping: [KeyMapping] = [
  KeyMapping("0", .tone0),
  KeyMapping("1", .tone1),
  KeyMapping("2", .tone2),
  KeyMapping("3", .tone3),
  KeyMapping("4", .tone4),
  KeyMapping("5", .tone5),
  KeyMapping("6", .roofAll),
  KeyMapping("7", .hook_uo),
  KeyMapping("8", .bowl),
  KeyMapping("9", .dd),
]

/// VIQR input method mapping
public let viqrMapping: [KeyMapping] = [
  KeyMapping("0", .tone0),
  KeyMapping("'", .tone1),
  KeyMapping("`", .tone2),
  KeyMapping("?", .tone3),
  KeyMapping("~", .tone4),
  KeyMapping(".", .tone5),
  KeyMapping("^", .roofAll),
  KeyMapping("+", .hook_uo),
  KeyMapping("*", .hook_uo),
  KeyMapping("(", .bowl),
  KeyMapping("d", .dd),
  KeyMapping("\\", .escChar),
]

// MARK: - Input Processor

/// Input processor - converts key codes to events
public class InputProcessor {
  private var inputMethod: InputMethod = .telex
  private var keyMap: [Character: KeyEventType] = [:]

  // Character type classification table
  private static let wordBreakSymbols: Set<Character> = [
    ",", ";", ":", ".", "\"", "'", "!", "?", " ",
    "<", ">", "=", "+", "-", "*", "/", "\\",
    "_", "@", "#", "$", "%", "&", "(", ")", "{", "}", "[", "]", "|",
  ]

  public init() {
    setInputMethod(.telex)
  }

  /// Set input method
  public func setInputMethod(_ method: InputMethod) {
    inputMethod = method
    keyMap.removeAll()

    let mapping: [KeyMapping]
    switch method {
    case .telex:
      mapping = telexMapping
    case .simpleTelex:
      mapping = simpleTelexMapping
    case .vni:
      mapping = vniMapping
    case .viqr:
      mapping = viqrMapping
    default:
      mapping = telexMapping
    }

    for entry in mapping {
      keyMap[entry.key] = entry.action
      // Also add uppercase version for most actions
      if entry.action.rawValue < KeyEventType.mapChar.rawValue {
        keyMap[Character(entry.key.uppercased())] = entry.action
      }
    }
  }

  /// Get current input method
  public func getInputMethod() -> InputMethod {
    return inputMethod
  }

  /// Convert key code to key event
  public func keyCodeToEvent(_ keyCode: UInt32, char: Character) -> KeyEvent {
    var event = KeyEvent()
    event.keyCode = keyCode
    event.charType = getCharType(char)

    if let action = keyMap[char] {
      event.eventType = action

      if action.rawValue >= KeyEventType.tone0.rawValue
        && action.rawValue <= KeyEventType.tone5.rawValue
      {
        event.tone = action.rawValue - KeyEventType.tone0.rawValue
      }
    } else {
      event.eventType = .normal
    }

    event.vnSymbol = asciiToVnLexi(char)

    return event
  }

  /// Get character type
  public func getCharType(_ char: Character) -> CharType {
    // Control characters reset
    if let ascii = char.asciiValue, ascii <= 32 {
      if ascii == 32 { return .wordBreak }  // Space
      return .reset
    }

    // Word break symbols
    if Self.wordBreakSymbols.contains(char) {
      return .wordBreak
    }

    // Letters
    if char.isLetter {
      // j, f, w are non-Vietnamese standalone
      let lower = char.lowercased()
      if lower == "j" || lower == "f" || lower == "w" {
        return .nonVn
      }
      return .vn
    }

    return .nonVn
  }
}
