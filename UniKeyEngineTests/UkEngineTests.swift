// UkEngineTests.swift
// Integration tests for the main Unikey engine
// Unikey Vietnamese Input Method

import XCTest

@testable import Unikey

final class UkEngineTests: XCTestCase {

  var engine: UkEngine!

  override func setUp() {
    super.setUp()
    engine = UkEngine()
    engine.setInputMethod(.telex)
  }

  override func tearDown() {
    engine = nil
    super.tearDown()
  }

  // MARK: - Helper Methods

  /// Process a string of keys through the engine
  private func processKeys(_ keys: String) -> String {
    var output = ""
    for char in keys {
      let result = engine.process(keyCode: UInt32(char.asciiValue ?? 0), char: char)
      if result.handled {
        // Handle backspaces
        if result.backspaceCount > 0 && output.count >= result.backspaceCount {
          output.removeLast(result.backspaceCount)
        }
        output += result.output
      } else {
        output += String(char)
      }
    }
    return output
  }

  // MARK: - Telex Basic Tests

  func testTelexSimpleVowel() {
    XCTAssertEqual(processKeys("a"), "a")
    XCTAssertEqual(processKeys("e"), "e")
    XCTAssertEqual(processKeys("i"), "i")
    XCTAssertEqual(processKeys("o"), "o")
    XCTAssertEqual(processKeys("u"), "u")
    XCTAssertEqual(processKeys("y"), "y")
  }

  func testTelexTones() {
    engine.reset()
    XCTAssertEqual(processKeys("as"), "á")  // sắc

    engine.reset()
    XCTAssertEqual(processKeys("af"), "à")  // huyền

    engine.reset()
    XCTAssertEqual(processKeys("ar"), "ả")  // hỏi

    engine.reset()
    XCTAssertEqual(processKeys("ax"), "ã")  // ngã

    engine.reset()
    XCTAssertEqual(processKeys("aj"), "ạ")  // nặng
  }

  func testTelexRoof() {
    engine.reset()
    XCTAssertEqual(processKeys("aa"), "â")

    engine.reset()
    XCTAssertEqual(processKeys("ee"), "ê")

    engine.reset()
    XCTAssertEqual(processKeys("oo"), "ô")
  }

  func testTelexHook() {
    engine.reset()
    XCTAssertEqual(processKeys("ow"), "ơ")

    engine.reset()
    XCTAssertEqual(processKeys("uw"), "ư")

    engine.reset()
    XCTAssertEqual(processKeys("aw"), "ă")
  }

  func testTelexDd() {
    engine.reset()
    XCTAssertEqual(processKeys("dd"), "đ")

    engine.reset()
    XCTAssertEqual(processKeys("DD"), "Đ")
  }

  // MARK: - Telex Word Tests

  func testTelexVietnameseWords() {
    engine.reset()
    let viet = processKeys("vieetj")  // Việt
    XCTAssertTrue(viet.contains("ệ") || viet.contains("ê"), "Expected 'ệ' but got: \(viet)")

    engine.reset()
    let nam = processKeys("nam")
    XCTAssertEqual(nam, "nam")

    engine.reset()
    let xin = processKeys("xin")
    XCTAssertEqual(xin, "xin")

    engine.reset()
    let chao = processKeys("chaof")  // chào
    XCTAssertTrue(chao.contains("à"), "Expected 'à' but got: \(chao)")
  }

  // MARK: - VNI Input Tests

  func testVNITones() {
    engine.setInputMethod(.vni)

    engine.reset()
    XCTAssertEqual(processKeys("a1"), "á")  // sắc

    engine.reset()
    XCTAssertEqual(processKeys("a2"), "à")  // huyền

    engine.reset()
    XCTAssertEqual(processKeys("a3"), "ả")  // hỏi

    engine.reset()
    XCTAssertEqual(processKeys("a4"), "ã")  // ngã

    engine.reset()
    XCTAssertEqual(processKeys("a5"), "ạ")  // nặng
  }

  func testVNIRoof() {
    engine.setInputMethod(.vni)

    engine.reset()
    XCTAssertEqual(processKeys("a6"), "â")

    engine.reset()
    XCTAssertEqual(processKeys("e6"), "ê")

    engine.reset()
    XCTAssertEqual(processKeys("o6"), "ô")
  }

  func testVNIHook() {
    engine.setInputMethod(.vni)

    engine.reset()
    XCTAssertEqual(processKeys("o7"), "ơ")

    engine.reset()
    XCTAssertEqual(processKeys("u7"), "ư")

    engine.reset()
    XCTAssertEqual(processKeys("a8"), "ă")
  }

  func testVNIDd() {
    engine.setInputMethod(.vni)

    engine.reset()
    XCTAssertEqual(processKeys("d9"), "đ")
  }

  // MARK: - Edge Cases

  func testReset() {
    engine.reset()
    XCTAssertTrue(engine.atWordBeginning())

    _ = processKeys("a")
    XCTAssertFalse(engine.atWordBeginning())

    engine.reset()
    XCTAssertTrue(engine.atWordBeginning())
  }

  func testBackspace() {
    engine.reset()
    _ = processKeys("vie")

    let result = engine.processBackspace()
    XCTAssertTrue(result.handled)
    XCTAssertEqual(result.backspaceCount, 1)
  }
}
