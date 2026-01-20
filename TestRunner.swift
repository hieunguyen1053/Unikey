// main.swift - Standalone Test Runner for Unikey Engine
// Run: cd Unikey && swiftc -o test_runner Unikey/Engine/*.swift Unikey/Engine/Data/*.swift TestRunner.swift && ./test_runner

import Foundation

// MARK: - Test Functions

func testVnLexiName() {
  print("\n📝 Test 1: VnLexiName Properties")
  print(String(repeating: "-", count: 40))

  // Test isVowel
  let vowelTests: [(VnLexiName, Bool)] = [
    (.a, true), (.e, true), (.i, true), (.o, true), (.u, true), (.y, true),
    (.ar, true), (.er, true), (.or, true), (.oh, true), (.uh, true),
    (.b, false), (.c, false), (.d, false), (.dd, false),
  ]

  var passCount = 0
  var failCount = 0

  for (sym, expected) in vowelTests {
    let result = sym.isVowel
    if result == expected {
      passCount += 1
    } else {
      failCount += 1
      print("  ❌ FAIL: \(sym).isVowel = \(result), expected \(expected)")
    }
  }

  print("  isVowel tests: \(passCount) passed, \(failCount) failed")
}

func testVowelSequenceLookup() {
  print("\n📝 Test 2: Vowel Sequence Lookup")
  print(String(repeating: "-", count: 40))

  let tests: [(VnLexiName, VnLexiName, VnLexiName, VowelSequence)] = [
    // Single vowels
    (.a, .nonVnChar, .nonVnChar, .a),
    (.e, .nonVnChar, .nonVnChar, .e),
    (.i, .nonVnChar, .nonVnChar, .i),
    // Double vowels
    (.i, .e, .nonVnChar, .ie),
    (.i, .er, .nonVnChar, .ier),  // iê
    (.u, .a, .nonVnChar, .ua),
    // Triple vowels
    (.i, .e, .u, .ieu),
    (.u, .o, .i, .uoi),
  ]

  var passCount = 0
  var failCount = 0

  for (v1, v2, v3, expected) in tests {
    let result = lookupVowelSeq(v1, v2, v3)
    if result == expected {
      passCount += 1
      print("  ✅ lookupVowelSeq(\(v1), \(v2), \(v3)) = \(result)")
    } else {
      failCount += 1
      print("  ❌ FAIL: lookupVowelSeq(\(v1), \(v2), \(v3)) = \(result), expected \(expected)")
    }
  }

  print("  Total: \(passCount) passed, \(failCount) failed")
}

func testUkEngine() {
  print("\n📝 Test 3: UkEngine Processing (Verbose)")
  print(String(repeating: "-", count: 40))

  let engine = UkEngine()
  engine.setInputMethod(.telex)

  // Helper to process a string with verbose output
  func processKeys(_ keys: String) -> String {
    engine.reset()
    var output = ""

    print("  Processing: '\(keys)'")
    for char in keys {
      let keyCode = UInt32(char.asciiValue ?? 0)
      let result = engine.process(keyCode: keyCode, char: char)

      print(
        "    '\(char)' → handled=\(result.handled), bs=\(result.backspaceCount), out='\(result.output)'"
      )

      if result.handled {
        if result.backspaceCount > 0 && output.count >= result.backspaceCount {
          output.removeLast(result.backspaceCount)
        }
        output += result.output
      } else {
        output += String(char)
      }
    }

    print("  Result: '\(output)'")
    return output
  }

  // Test cases - basic
  print("\n  --- Basic Tests ---")
  let basicTests: [(String, String)] = [
    ("a", "a"),
    ("as", "á"),
    ("af", "à"),
    ("aa", "â"),
    ("ee", "ê"),
    ("dd", "đ"),
  ]

  var passCount = 0
  var failCount = 0

  for (input, expected) in basicTests {
    let result = processKeys(input)
    if result == expected {
      passCount += 1
      print("  ✅ PASS")
    } else {
      failCount += 1
      print("  ❌ FAIL: expected '\(expected)'")
    }
    print("")
  }

  // Test cases - multi-character words
  print("\n  --- Multi-Character Word Tests ---")
  let wordTests: [(String, String)] = [
    ("viet", "viet"),
    ("vieet", "việt"),
    ("nhieu", "nhiêu"),
    ("nhieuf", "nhiều"),  // <-- The failing case!
    ("nguoi", "nguoi"),
    ("nguowif", "người"),
  ]

  for (input, expected) in wordTests {
    let result = processKeys(input)
    if result == expected {
      passCount += 1
      print("  ✅ PASS")
    } else {
      failCount += 1
      print("  ❌ FAIL: expected '\(expected)'")
    }
    print("")
  }

  print("  Total: \(passCount) passed, \(failCount) failed")
}

// MARK: - Main Entry Point

@main
struct TestRunnerApp {
  static func main() {
    print(String(repeating: "=", count: 50))
    print("🧪 Unikey Swift Engine - Debug Test")
    print(String(repeating: "=", count: 50))

    print("\n🚀 Running tests...\n")

    testVnLexiName()
    testVowelSequenceLookup()
    testUkEngine()

    print("\n" + String(repeating: "=", count: 50))
    print("✅ Test run completed!")
    print(String(repeating: "=", count: 50))
  }
}
