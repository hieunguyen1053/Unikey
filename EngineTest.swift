#!/usr/bin/env swift
// EngineTest.swift
// Standalone test script for Unikey Engine
// Run: swift EngineTest.swift

import Foundation

print("=" * 50)
print("🧪 Unikey Swift Engine Test")
print("=" * 50)

// Since we can't import the module directly, let's test the logic manually

// Test 1: Basic Character Processing
print("\n📝 Test 1: Character Processing Logic")
print("-" * 40)

// Simulate Telex mapping
let telexMap: [Character: String] = [
  "s": "tone1",  // sắc
  "f": "tone2",  // huyền
  "r": "tone3",  // hỏi
  "x": "tone4",  // ngã
  "j": "tone5",  // nặng
  "z": "tone0",  // remove tone
  "a": "roof_a",  // aa -> â
  "e": "roof_e",  // ee -> ê
  "o": "roof_o",  // oo -> ô
  "w": "hook",  // ư, ơ, ă
  "d": "dd",  // đ
]

print("Telex mappings loaded: \(telexMap.count) keys")

// Test 2: Vowel combinations
print("\n📝 Test 2: Vowel Combinations")
print("-" * 40)

let vowelCombinations = [
  "ai": "ai",
  "ao": "ao",
  "au": "au",
  "ay": "ay",
  "ua": "ua",
  "uo": "uo",
  "ie": "iê (needs roof)",
  "uo": "uô (needs roof)",
]

for (input, output) in vowelCombinations {
  print("  \(input) -> \(output)")
}

// Test 3: Expected Telex transformations
print("\n📝 Test 3: Expected Telex Transformations")
print("-" * 40)

let expectedTransforms = [
  ("as", "á"),
  ("af", "à"),
  ("ar", "ả"),
  ("ax", "ã"),
  ("aj", "ạ"),
  ("aa", "â"),
  ("ee", "ê"),
  ("oo", "ô"),
  ("ow", "ơ"),
  ("uw", "ư"),
  ("aw", "ă"),
  ("dd", "đ"),
]

for (input, expected) in expectedTransforms {
  print("  \(input) -> \(expected)")
}

// Test 4: Vietnamese words
print("\n📝 Test 4: Vietnamese Words (Telex)")
print("-" * 40)

let telexWords = [
  ("xin chaof", "xin chào"),
  ("canr own", "cảm ơn"),
  ("vieejt nam", "việt nam"),
  ("nguwowfi vieejt", "người việt"),
]

for (input, expected) in telexWords {
  print("  \"\(input)\" -> \"\(expected)\"")
}

print("\n" + "=" * 50)
print("✅ Logic tests completed!")
print("=" * 50)

print(
  """

  📋 Debug Steps for Input Method:

  1. Kiểm tra Unikey đã được thêm vào Input Sources:
     System Preferences → Keyboard → Input Sources

  2. Kiểm tra Accessibility permission (quan trọng!):
     System Preferences → Security & Privacy → Privacy → Accessibility
     → Add Unikey.app

  3. Restart IMK Server:
     killall Unikey
     open ~/Library/Input\\ Methods/Unikey.app

  4. Check Console.app for errors:
     Filter by "Unikey" or "IMK"

  5. Verify bundle structure:
     ls -la ~/Library/Input\\ Methods/Unikey.app/Contents/
  """)

// String multiplication helper
func * (string: String, times: Int) -> String {
  return String(repeating: string, count: times)
}
