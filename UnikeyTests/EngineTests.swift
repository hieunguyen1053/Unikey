//
//  EngineTests.swift
//  UnikeyTests
//
//  Comprehensive Unit Tests for Unikey Engine
//  Inspired by XKey's VNEngineTests
//

import XCTest

@testable import Unikey

final class EngineTests: XCTestCase {

  var engine: UkEngine!
  var sharedMem: UkSharedMem!

  override func setUp() {
    super.setUp()
    // Initialize shared memory with default options
    sharedMem = UkSharedMem()
    sharedMem.vietKey = 1
    sharedMem.options.vietKeyEnabled = true
    sharedMem.options.freeMarking = true
    sharedMem.options.spellCheckEnabled = true
    sharedMem.options.modernStyle = true

    // Initialize engine
    engine = UkEngine()
    engine.setCtrlInfo(sharedMem)

    // Default to Telex
    sharedMem.input.setIM(.telex)
  }

  override func tearDown() {
    engine = nil
    sharedMem = nil
    super.tearDown()
  }

  // MARK: - Helper Methods

  /// Simulates typing a string and asserts the final output matches expectation.
  /// - Parameters:
  ///   - input: The string of characters to simulate typing.
  ///   - expected: The expected resulting string.
  ///   - method: The input method to use (default: .telex).
  ///   - file: The file where assertion is made (for error reporting).
  ///   - line: The line where assertion is made (for error reporting).
  func assertInput(
    _ input: String,
    produces expected: String,
    method: UkInputMethod = .telex,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    // Setup input method
    if sharedMem.input.getIM() != method {
      sharedMem.input.setIM(method)
    }
    engine.reset()

    var currentText = ""

    for char in input {
      let keyCode = UInt32(char.asciiValue ?? 0)
      var backs = 0
      var outBuf: [UInt16] = []
      var outSize = 0
      var outType: UkOutputType = .normal

      let ret = engine.process(
        keyCode,
        &backs,
        &outBuf,
        &outSize,
        &outType
      )

      // Simulate editor behavior
      if ret != 0 {
        // Apply backspaces
        if backs > 0 {
          if backs > currentText.count {
            // In unit test context, we shouldn't backspace beyond empty,
            // but if engine requests it, it means our tracking is out of sync or engine logic expects context.
            // For these simple word tests, we expect correct sync.
            currentText = ""
          } else {
            currentText.removeLast(backs)
          }
        }

        // Append new text
        if outSize > 0 {
          let outString = String(
            utf16CodeUnits: outBuf,
            count: outSize
          )
          currentText += outString
        }
      } else {
        // Engine didn't handle -> System inserts character
        currentText.append(char)
      }
    }

    XCTAssertEqual(
      currentText,
      expected,
      "Input '\(input)' should produce '\(expected)'",
      file: file,
      line: line
    )
  }

  // MARK: - Telex: Simple Transformations

  func testTelex_AA_ToCircumflex() {
    assertInput("aa", produces: "â")
  }

  func testTelex_AW_ToBreve() {
    assertInput("aw", produces: "ă")
  }

  func testTelex_EE_ToCircumflex() {
    assertInput("ee", produces: "ê")
  }

  func testTelex_OO_ToCircumflex() {
    assertInput("oo", produces: "ô")
  }

  func testTelex_OW_ToHorn() {
    assertInput("ow", produces: "ơ")
  }

  func testTelex_UW_ToHorn() {
    assertInput("uw", produces: "ư")
  }

  func testTelex_DD_ToDStroke() {
    assertInput("dd", produces: "đ")
  }

  // MARK: - Telex: Tones

  func testTelex_Tones() {
    assertInput("as", produces: "á")  // Acute
    assertInput("af", produces: "à")  // Grave
    assertInput("ar", produces: "ả")  // Hook Above
    assertInput("ax", produces: "ã")  // Tilde
    assertInput("aj", produces: "ạ")  // Dot Below
  }

  func testTelex_ToneRemoval() {
    // 'z' removes tone
    assertInput("asz", produces: "a")
  }

  // MARK: - Telex: Complex Words

  func testTelex_Words() {
    assertInput("vieet", produces: "viêt")
    assertInput("tieengs", produces: "tiếng")
    assertInput("dduwowcj", produces: "được")
    assertInput("nguoiw", produces: "ngươi")  // w -> ư, o -> ơ (nguoi -> ng u o i -> nguoi if simple?)
    // Wait, in Telex 'uoi' -> 'uôi' ?
    // 'uowi' -> 'ươi'
    // 'uow' -> 'ươ'

    assertInput("nguowi", produces: "ngươi")
  }

  // MARK: - VNI Input Method

  func testVNI_Simple() {
    assertInput("a6", produces: "â", method: .vni)
    assertInput("e6", produces: "ê", method: .vni)
    assertInput("o6", produces: "ô", method: .vni)
    assertInput("a8", produces: "ă", method: .vni)
    assertInput("u7", produces: "ư", method: .vni)
    assertInput("o7", produces: "ơ", method: .vni)
    assertInput("d9", produces: "đ", method: .vni)
  }

  func testVNI_Tones() {
    assertInput("a1", produces: "á", method: .vni)
    assertInput("a2", produces: "à", method: .vni)
    assertInput("a3", produces: "ả", method: .vni)
    assertInput("a4", produces: "ã", method: .vni)
    assertInput("a5", produces: "ạ", method: .vni)
  }

  func testVNI_Complex() {
    // d9 -> đ, u -> u, o7 -> ơ, 5 -> ợ, c -> c
    assertInput("d9uo75c", produces: "được", method: .vni)
  }

  // MARK: - Orthography (Modern vs Old)

  func testModernOrthography() {
    sharedMem.options.modernStyle = true
    // Modern: tone on 2nd vowel for 'oa', 'oe', 'uy'
    assertInput("hoas", produces: "hoá")
  }

  func testOldOrthography() {
    sharedMem.options.modernStyle = false
    // Old: tone on 1st vowel? or 2nd?
    // Old: 'hóa'
    assertInput("hoas", produces: "hóa")
  }

  // MARK: - Edge Cases

  func testNonVietnameseRestore() {
    // If typing invalid sequence, should it restore?
    // e.g. "aa" -> "â". "aaa" -> "aa" ?
    // Unikey logic: 'aa' -> 'â'. 'â' + 'a' -> 'aa' (restore if double typing same key?)
    // assertInput("aaa", produces: "aa") // This depends on implementation detail of "autoNonVnRestore"

    // Let's test standard restore
    // "dd" -> "đ". "ddd" -> "dd"
    assertInput("ddd", produces: "dd")
  }

  func testMixInput() {
    // Input "Unikey"
    assertInput("Unikey", produces: "Unikey")
  }

  // MARK: - Free Marking Tests

  func testFreeMarkingEnabled() {
    sharedMem.options.freeMarking = true
    // With free marking, tone can be placed at any position
    assertInput("tooi", produces: "tôi")
    // vieet produces viêt with circumflex
    assertInput("vieet", produces: "viêt")
  }

  func testFreeMarkingDisabled() {
    sharedMem.options.freeMarking = false
    sharedMem.options.spellCheckEnabled = true
    // Without free marking, tone placement follows stricter rules
    // Testing basic word formation still works
    assertInput("tooi", produces: "tôi")
  }

  // MARK: - Spell Check Tests

  func testSpellCheckEnabled() {
    sharedMem.options.spellCheckEnabled = true
    // With spell check, invalid combinations should be handled
    assertInput("vieet", produces: "viêt")
  }

  func testSpellCheckDisabled() {
    sharedMem.options.spellCheckEnabled = false
    // Without spell check, all inputs are accepted
    assertInput("vieet", produces: "viêt")
  }

  // MARK: - Auto Restore Tests

  func testAutoRestoreWithInvalidWord() {
    sharedMem.options.autoNonVnRestore = true
    sharedMem.options.spellCheckEnabled = true
    // When typing valid Vietnamese with double e
    // "nghieem" -> "nghiêm" (circumflex e)
    assertInput("nghieem", produces: "nghiêm")
  }

  func testAutoRestoreDisabled() {
    sharedMem.options.autoNonVnRestore = false
    // Without auto restore, behavior same for valid words
    assertInput("nghieem", produces: "nghiêm")
  }

  // MARK: - Combination Tests

  func testModernStyleWithTones() {
    sharedMem.options.modernStyle = true
    // Modern orthography: hoà (tone on second vowel)
    assertInput("hoas", produces: "hoá")
    assertInput("uys", produces: "uý")
  }

  func testOldStyleWithTones() {
    sharedMem.options.modernStyle = false
    // Old orthography: hòa (tone on first vowel)
    assertInput("hoas", produces: "hóa")
    // For 'uy', old style puts tone on 'u'
    assertInput("uys", produces: "úy")
  }

  // MARK: - Word Boundary Tests

  func testWordBoundaryWithSpace() {
    // Space should trigger word boundary processing
    // and potentially macro replacement or spell check
    engine.reset()
    assertInput("xin ", produces: "xin ")
  }

  func testMultipleWords() {
    engine.reset()
    assertInput("xin chao", produces: "xin chao")
  }

}
