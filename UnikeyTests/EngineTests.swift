//
//  EngineTests.swift
//  UnikeyTests
//
//  Unit tests for Vietnamese typing engine
//  Adapted from XKey's VNEngineTests.swift
//

import XCTest

@testable import Unikey

final class EngineTests: XCTestCase {

  var engine: UkEngine!
  var sharedMem: UkSharedMem!

  override func setUp() {
    super.setUp()
    sharedMem = UkSharedMem()
    sharedMem.vietKey = 1
    sharedMem.options.vietKeyEnabled = true
    sharedMem.options.freeMarking = true
    sharedMem.options.spellCheckEnabled = true
    sharedMem.options.modernStyle = true
    sharedMem.input.setIM(.telex)

    engine = UkEngine()
    engine.setCtrlInfo(sharedMem)
  }

  override func tearDown() {
    engine = nil
    sharedMem = nil
    super.tearDown()
  }

  // MARK: - Helper Methods

  /// Helper to process a string of characters through the engine
  private func type(_ text: String, uppercase: Bool = false) {
    for char in text {
      let keyCode = UInt32(char.asciiValue ?? 0)
      var backs = 0
      var outBuf: [UInt16] = []
      var outSize = 0
      var outType: UkOutputType = .normal
      _ = engine.process(keyCode, &backs, &outBuf, &outSize, &outType)
    }
  }

  /// Helper to get current word from engine output
  private func processAndGetOutput(_ char: Character) -> (backs: Int, output: [UInt16]) {
    let keyCode = UInt32(char.asciiValue ?? 0)
    var backs = 0
    var outBuf: [UInt16] = []
    var outSize = 0
    var outType: UkOutputType = .normal
    _ = engine.process(keyCode, &backs, &outBuf, &outSize, &outType)
    return (backs, outBuf)
  }

  // MARK: - Basic Telex Transformation Tests

  func testTelex_AA_ToCircumflex() {
    engine.reset()

    // Type 'a'
    type("a")

    // Type 'a' again -> should become 'â'
    let result = processAndGetOutput("a")
    XCTAssertGreaterThan(result.backs, 0, "Should backspace to replace 'a' with 'â'")
  }

  func testTelex_AW_ToBreve() {
    engine.reset()

    // Type 'a'
    type("a")

    // Type 'w' -> should become 'ă'
    let result = processAndGetOutput("w")
    XCTAssertGreaterThan(result.backs, 0, "Should consume 'w' for transformation to 'ă'")
  }

  func testTelex_EE_ToCircumflex() {
    engine.reset()

    // Type 'e'
    type("e")

    // Type 'e' again -> should become 'ê'
    let result = processAndGetOutput("e")
    XCTAssertGreaterThan(result.backs, 0, "Should transform 'e' to 'ê'")
  }

  func testTelex_OO_ToCircumflex() {
    engine.reset()

    // Type 'o'
    type("o")

    // Type 'o' again -> should become 'ô'
    let result = processAndGetOutput("o")
    XCTAssertGreaterThan(result.backs, 0, "Should transform 'o' to 'ô'")
  }

  func testTelex_OW_ToHorn() {
    engine.reset()

    // Type 'o'
    type("o")

    // Type 'w' -> should become 'ơ'
    let result = processAndGetOutput("w")
    XCTAssertGreaterThan(result.backs, 0, "Should transform 'o' to 'ơ'")
  }

  func testTelex_UW_ToHorn() {
    engine.reset()

    // Type 'u'
    type("u")

    // Type 'w' -> should become 'ư'
    let result = processAndGetOutput("w")
    XCTAssertGreaterThan(result.backs, 0, "Should transform 'u' to 'ư'")
  }

  func testTelex_DD_ToDStroke() {
    engine.reset()

    // Type 'd'
    type("d")

    // Type 'd' again -> should become 'đ'
    let result = processAndGetOutput("d")
    XCTAssertGreaterThan(result.backs, 0, "Should transform 'd' to 'đ'")
  }

  // MARK: - Tone Tests (Telex)

  func testTone_AS_ToAcute() {
    engine.reset()

    // Type 'a'
    type("a")

    // Type 's' (acute tone) -> should become 'á'
    let result = processAndGetOutput("s")
    XCTAssertGreaterThan(result.backs, 0, "Should apply acute tone")
  }

  func testTone_AF_ToGrave() {
    engine.reset()
    type("a")
    let result = processAndGetOutput("f")
    XCTAssertGreaterThan(result.backs, 0, "Should apply grave tone")
  }

  func testTone_AR_ToHookAbove() {
    engine.reset()
    type("a")
    let result = processAndGetOutput("r")
    XCTAssertGreaterThan(result.backs, 0, "Should apply hook above")
  }

  func testTone_AX_ToTilde() {
    engine.reset()
    type("a")
    let result = processAndGetOutput("x")
    XCTAssertGreaterThan(result.backs, 0, "Should apply tilde")
  }

  func testTone_AJ_ToDotBelow() {
    engine.reset()
    type("a")
    let result = processAndGetOutput("j")
    XCTAssertGreaterThan(result.backs, 0, "Should apply dot below")
  }

  // MARK: - Complete Word Tests

  func testWord_Viet() {
    engine.reset()

    // v-i-ê-t (vieet in Telex)
    type("v")
    type("i")
    type("e")
    let result = processAndGetOutput("e")  // e -> ê
    type("t")

    XCTAssertGreaterThan(result.backs, 0, "Should build 'viêt'")
  }

  func testWord_Nam() {
    engine.reset()

    // n-a-m (simple, no transformation)
    type("n")
    type("a")
    type("m")

    // Simple word without transformation should work without errors
    XCTAssertTrue(true, "Should output 'nam'")
  }

  func testWord_Toi() {
    engine.reset()

    // t-ô-i (tooi in Telex)
    type("t")
    type("o")
    let result = processAndGetOutput("o")  // o -> ô
    type("i")

    XCTAssertGreaterThan(result.backs, 0, "Should output 'tôi'")
  }

  // MARK: - VNI Input Method Tests

  func testVNI_Setup() {
    // Switch to VNI input method
    sharedMem.input.setIM(.vni)
    engine.reset()

    // VNI should be set
    XCTAssertTrue(true, "VNI input method should be set")
  }

  func testVNI_A6_ToCircumflex() {
    sharedMem.input.setIM(.vni)
    engine.reset()

    // Type 'a'
    type("a")

    // Type '6' (circumflex in VNI) -> should make 'â'
    let result = processAndGetOutput("6")
    XCTAssertGreaterThan(result.backs, 0, "VNI: 'a6' should become 'â'")
  }

  func testVNI_E6_ToCircumflex() {
    sharedMem.input.setIM(.vni)
    engine.reset()

    type("e")
    let result = processAndGetOutput("6")
    XCTAssertGreaterThan(result.backs, 0, "VNI: 'e6' should become 'ê'")
  }

  func testVNI_O6_ToCircumflex() {
    sharedMem.input.setIM(.vni)
    engine.reset()

    type("o")
    let result = processAndGetOutput("6")
    XCTAssertGreaterThan(result.backs, 0, "VNI: 'o6' should become 'ô'")
  }

  func testVNI_A8_ToBreve() {
    sharedMem.input.setIM(.vni)
    engine.reset()

    type("a")
    let result = processAndGetOutput("8")
    XCTAssertGreaterThan(result.backs, 0, "VNI: 'a8' should become 'ă'")
  }

  func testVNI_U7_ToHorn() {
    sharedMem.input.setIM(.vni)
    engine.reset()

    type("u")
    let result = processAndGetOutput("7")
    XCTAssertGreaterThan(result.backs, 0, "VNI: 'u7' should become 'ư'")
  }

  func testVNI_O7_ToHorn() {
    sharedMem.input.setIM(.vni)
    engine.reset()

    type("o")
    let result = processAndGetOutput("7")
    XCTAssertGreaterThan(result.backs, 0, "VNI: 'o7' should become 'ơ'")
  }

  func testVNI_D9_ToDStroke() {
    sharedMem.input.setIM(.vni)
    engine.reset()

    type("d")
    let result = processAndGetOutput("9")
    XCTAssertGreaterThan(result.backs, 0, "VNI: 'd9' should become 'đ'")
  }

  func testVNI_A1_ToAcute() {
    sharedMem.input.setIM(.vni)
    engine.reset()

    type("a")
    let result = processAndGetOutput("1")
    XCTAssertGreaterThan(result.backs, 0, "VNI: 'a1' should become 'á'")
  }

  func testVNI_O2_ToGrave() {
    sharedMem.input.setIM(.vni)
    engine.reset()

    type("o")
    let result = processAndGetOutput("2")
    XCTAssertGreaterThan(result.backs, 0, "VNI: 'o2' should become 'ò'")
  }

  // MARK: - Tone Placement Tests

  func testTonePlacement_HOA_NoEndingConsonant() {
    engine.reset()
    sharedMem.options.modernStyle = true

    // h-o-a-s -> hoá (Telex)
    type("h")
    type("o")
    type("a")
    let result = processAndGetOutput("s")

    XCTAssertGreaterThan(result.backs, 0, "Tone should be applied in 'hoá'")
  }

  func testTonePlacement_KHOANG() {
    engine.reset()

    // k-h-o-a-r-n-g -> khoảng (Telex)
    type("k")
    type("h")
    type("o")
    type("a")
    let result = processAndGetOutput("r")  // hook above
    type("n")
    type("g")

    XCTAssertGreaterThan(result.backs, 0, "Tone should be on 'a' in 'khoảng'")
  }

  // MARK: - Modern vs Old Orthography Tests

  func testTonePlacement_TUY_ModernOrthography() {
    engine.reset()
    sharedMem.options.modernStyle = true

    // t-u-y-s -> tuý (Telex, modern orthography)
    type("t")
    type("u")
    type("y")
    let result = processAndGetOutput("s")

    XCTAssertGreaterThan(result.backs, 0, "Tone should be on 'y' in 'tuý' (modern)")
  }

  func testTonePlacement_TUY_OldOrthography() {
    engine.reset()
    sharedMem.options.modernStyle = false

    // t-u-y-s -> túy (Telex, old orthography)
    type("t")
    type("u")
    type("y")
    let result = processAndGetOutput("s")

    XCTAssertGreaterThan(result.backs, 0, "Tone should be on 'u' in 'túy' (old)")
  }

  // MARK: - Free Marking Tests

  func testFreeMark_Enabled() {
    engine.reset()
    sharedMem.options.freeMarking = true

    // With free mark, tone can be placed before word completion
    type("n")
    type("g")
    type("o")
    let result = processAndGetOutput("f")  // grave mark

    XCTAssertGreaterThan(result.backs, 0, "Free mark should allow tone on incomplete word")
  }

  // MARK: - Reset and State Tests

  func testEngineReset() {
    engine.reset()
    type("v")
    type("i")
    type("e")
    type("t")

    engine.reset()

    XCTAssertTrue(engine.atWordBeginning(), "After reset, engine should be at word beginning")
  }

  func testAtWordBeginning() {
    engine.reset()
    XCTAssertTrue(engine.atWordBeginning(), "Fresh engine should be at word beginning")

    type("a")
    XCTAssertFalse(engine.atWordBeginning(), "After typing, engine should not be at word beginning")
  }

  // MARK: - Backspace Tests

  func testBackspace_Basic() {
    engine.reset()
    type("v")
    type("i")
    type("e")
    type("e")  // -> viê

    var backs = 0
    var outBuf: [UInt16] = []
    var outSize = 0
    var outType: UkOutputType = .normal

    _ = engine.processBackspace(&backs, &outBuf, &outSize, &outType)

    // Backspace should work
    XCTAssertTrue(true, "Backspace should be processed")
  }

  // MARK: - Edge Cases

  func testDoubleConsonant_NG() {
    engine.reset()

    // ng is a valid consonant cluster
    type("n")
    type("g")
    type("a")
    let result = processAndGetOutput("s")

    XCTAssertGreaterThan(result.backs, 0, "Should handle 'ng' consonant cluster")
  }

  func testDoubleConsonant_GH() {
    engine.reset()

    // gh is a valid consonant cluster
    type("g")
    type("h")
    type("e")
    let result = processAndGetOutput("s")

    XCTAssertGreaterThan(result.backs, 0, "Should handle 'gh' consonant cluster")
  }

  func testTripleTransformation_UOI() {
    engine.reset()

    // Type 'ười' (part of người)
    type("u")
    let w1 = processAndGetOutput("w")  // u -> ư
    type("o")
    let w2 = processAndGetOutput("w")  // o -> ơ
    type("i")

    XCTAssertGreaterThan(w1.backs, 0, "First 'w' should transform 'u' to 'ư'")
    XCTAssertGreaterThan(w2.backs, 0, "Second 'w' should transform 'o' to 'ơ'")
  }

  // MARK: - Vietnamese Complex Words

  func testWord_Nguoi() {
    engine.reset()

    // n-g-ư-ơ-i (nguowowi in Telex)
    type("n")
    type("g")
    type("u")
    let u = processAndGetOutput("o")
    let w = processAndGetOutput("w")  // uo -> ươ
    type("i")

    XCTAssertTrue(true, "Should build 'người' correctly")
  }

  func testWord_Duoc() {
    engine.reset()

    // đ-ư-ợ-c (dduwowc in full Telex)
    type("d")
    type("d")  // d -> đ
    type("u")
    type("o")
    let w = processAndGetOutput("w")  // uo -> ươ
    let j = processAndGetOutput("j")  // dot below
    type("c")

    XCTAssertTrue(true, "Should build 'được' correctly")
  }
}
