// VnLexiNameTests.swift
// Unit tests for VnLexiName enum
// Unikey Vietnamese Input Method

import XCTest

@testable import Unikey

final class VnLexiNameTests: XCTestCase {

  // MARK: - Basic Properties Tests

  func testIsVowel() {
    // Vowels
    XCTAssertTrue(VnLexiName.a.isVowel)
    XCTAssertTrue(VnLexiName.A.isVowel)
    XCTAssertTrue(VnLexiName.e.isVowel)
    XCTAssertTrue(VnLexiName.i.isVowel)
    XCTAssertTrue(VnLexiName.o.isVowel)
    XCTAssertTrue(VnLexiName.u.isVowel)
    XCTAssertTrue(VnLexiName.y.isVowel)

    // Special vowels
    XCTAssertTrue(VnLexiName.ar.isVowel)  // â
    XCTAssertTrue(VnLexiName.ab.isVowel)  // ă
    XCTAssertTrue(VnLexiName.er.isVowel)  // ê
    XCTAssertTrue(VnLexiName.or.isVowel)  // ô
    XCTAssertTrue(VnLexiName.oh.isVowel)  // ơ
    XCTAssertTrue(VnLexiName.uh.isVowel)  // ư

    // Consonants
    XCTAssertFalse(VnLexiName.b.isVowel)
    XCTAssertFalse(VnLexiName.c.isVowel)
    XCTAssertFalse(VnLexiName.d.isVowel)
    XCTAssertFalse(VnLexiName.dd.isVowel)  // đ
  }

  func testIsUppercase() {
    XCTAssertTrue(VnLexiName.A.isUppercase)
    XCTAssertTrue(VnLexiName.B.isUppercase)
    XCTAssertTrue(VnLexiName.DD.isUppercase)

    XCTAssertFalse(VnLexiName.a.isUppercase)
    XCTAssertFalse(VnLexiName.b.isUppercase)
    XCTAssertFalse(VnLexiName.dd.isUppercase)
  }

  func testTone() {
    XCTAssertEqual(VnLexiName.a.tone, 0)
    XCTAssertEqual(VnLexiName.a1.tone, 1)  // á
    XCTAssertEqual(VnLexiName.a2.tone, 2)  // à
    XCTAssertEqual(VnLexiName.a3.tone, 3)  // ả
    XCTAssertEqual(VnLexiName.a4.tone, 4)  // ã
    XCTAssertEqual(VnLexiName.a5.tone, 5)  // ạ
  }

  func testBaseChar() {
    XCTAssertEqual(VnLexiName.a.baseChar, .a)
    XCTAssertEqual(VnLexiName.a1.baseChar, .a)
    XCTAssertEqual(VnLexiName.a5.baseChar, .a)

    XCTAssertEqual(VnLexiName.ar.baseChar, .ar)  // â
    XCTAssertEqual(VnLexiName.ar1.baseChar, .ar)  // ấ
  }

  // MARK: - Transformation Tests

  func testWithTone() {
    XCTAssertEqual(VnLexiName.a.withTone(1), .a1)
    XCTAssertEqual(VnLexiName.a.withTone(5), .a5)
    XCTAssertEqual(VnLexiName.e.withTone(2), .e2)
  }

  // MARK: - ASCII Mapping Tests

  func testAsciiToVnLexi() {
    XCTAssertEqual(asciiToVnLexi("a"), .a)
    XCTAssertEqual(asciiToVnLexi("A"), .A)
    XCTAssertEqual(asciiToVnLexi("z"), .z)
    XCTAssertEqual(asciiToVnLexi("1"), .nonVnChar)
  }
}
