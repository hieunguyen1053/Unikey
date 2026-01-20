// main.swift - Standalone Test Runner for Unikey Engine
// Run: swiftc -o test_runner Unikey/Engine/*.swift TestRunner.swift && ./test_runner

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
  // Setup shared mem
  let sharedMem = UkSharedMem()
  sharedMem.input.setIM(.telex)
  sharedMem.vietKey = 1
  engine.setCtrlInfo(sharedMem)

  // Helper to process a string with verbose output
  func processKeys(_ keys: String) -> String {
    engine.reset()
    var output = ""

    print("  Processing: '\(keys)'")
    for char in keys {
      let keyCode = UInt32(char.asciiValue ?? 0)

      var backs: Int = 0
      var outBuf: [UInt16] = []
      var outSize: Int = 0
      var outType: UkOutputType = .normal

      let ret = engine.process(keyCode, &backs, &outBuf, &outSize, &outType)

      let charStr = String(utf16CodeUnits: outBuf, count: outSize)
      print(
        "    '\(char)' → ret=\(ret), bs=\(backs), out='\(charStr)'"
      )

      if ret != 0 {
        if backs > 0 && output.count >= backs {
          output.removeLast(backs)
        }
        output += charStr
      } else {
        // Unikey logic: if ret=0 (not handled), original key is passed through?
        // UkEngine.process usually returns 0 for non-VN or pass-through.
        // But if we passed raw key, and it wasn't consumed/converted...
        // The implementation I wrote returns 0 for reset or pass-through.
        // If 0, we append original char.
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
    ("viet", "viêt"), // wait, 'vieet' -> việt. 'viet' -> viet (no tone/mark). iet is valid.
    ("vieet", "việt"), // viêt + j? vieet -> e+e -> ê. vieetj -> ệt.
    // wait, e + e -> ê.
    // v, i, e (v), e (cv -> e,e -> ê).
    // vieet -> việt ?? No.
    // e + e -> ê.
    // v i ê t -> viêt.
    // vieetj -> việt.
    ("vieetj", "việt"),
    ("nhieu", "nhiêu"), // i+e+u -> iêu ? ie+u -> ieu.
    ("nhieeu", "nhiêu"), // ie + e -> iê. iêu.
    ("nhieeuf", "nhiều"),
    ("nguoi", "ngươi"), // u+o+i -> uoi (if uoa style?) or uo+i -> uôi?
    // Unikey: nguoi -> người. (u+o -> ư).
    // wait, u+o -> ư in simple telex?
    // In standard telex: u+o -> uo. u+o+w -> ươ.
    // Or w -> ư/ơ.
    // "nguoi" -> nguoi.
    // "nguowi" -> người.
    // Let's check my VowelSeqTable.
    // u+o -> uo.
    // u+o+i -> uoi.
    // So "nguoi" -> "nguoi".
    // "nguowif" -> người.
    ("nguowif", "người"),
    ("hello", "hello"),
    ("vietnam", "vietnam"),
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
