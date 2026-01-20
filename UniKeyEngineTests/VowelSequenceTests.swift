// VowelSequenceTests.swift
// Unit tests for vowel sequence lookup and processing
// Unikey Vietnamese Input Method

import XCTest

@testable import Unikey

final class VowelSequenceTests: XCTestCase {

  // MARK: - Single Vowel Lookup Tests

  func testLookupSingleVowel() {
    XCTAssertEqual(lookupVowelSeq(.a), .a)
    XCTAssertEqual(lookupVowelSeq(.e), .e)
    XCTAssertEqual(lookupVowelSeq(.i), .i)
    XCTAssertEqual(lookupVowelSeq(.o), .o)
    XCTAssertEqual(lookupVowelSeq(.u), .u)
    XCTAssertEqual(lookupVowelSeq(.y), .y)
  }

  func testLookupSpecialVowels() {
    XCTAssertEqual(lookupVowelSeq(.ar), .ar)  // â
    XCTAssertEqual(lookupVowelSeq(.ab), .ab)  // ă
    XCTAssertEqual(lookupVowelSeq(.er), .er)  // ê
    XCTAssertEqual(lookupVowelSeq(.or), .or)  // ô
    XCTAssertEqual(lookupVowelSeq(.oh), .oh)  // ơ
    XCTAssertEqual(lookupVowelSeq(.uh), .uh)  // ư
  }

  // MARK: - Double Vowel Lookup Tests

  func testLookupDoubleVowels() {
    XCTAssertEqual(lookupVowelSeq(.a, .i), .ai)
    XCTAssertEqual(lookupVowelSeq(.a, .o), .ao)
    XCTAssertEqual(lookupVowelSeq(.a, .u), .au)
    XCTAssertEqual(lookupVowelSeq(.a, .y), .ay)

    XCTAssertEqual(lookupVowelSeq(.u, .a), .ua)
    XCTAssertEqual(lookupVowelSeq(.u, .o), .uo)
    XCTAssertEqual(lookupVowelSeq(.u, .y), .uy)

    XCTAssertEqual(lookupVowelSeq(.i, .a), .ia)
    XCTAssertEqual(lookupVowelSeq(.i, .e), .ie)
    XCTAssertEqual(lookupVowelSeq(.i, .u), .iu)
  }

  func testLookupDoubleVowelsWithDiacritics() {
    XCTAssertEqual(lookupVowelSeq(.ar, .u), .aru)  // âu
    XCTAssertEqual(lookupVowelSeq(.ar, .y), .ary)  // ây
    XCTAssertEqual(lookupVowelSeq(.er, .u), .eru)  // êu
    XCTAssertEqual(lookupVowelSeq(.i, .er), .ier)  // iê
    XCTAssertEqual(lookupVowelSeq(.u, .or), .uor)  // uô
    XCTAssertEqual(lookupVowelSeq(.uh, .oh), .uhoh)  // ươ
  }

  // MARK: - Triple Vowel Lookup Tests

  func testLookupTripleVowels() {
    XCTAssertEqual(lookupVowelSeq(.o, .a, .i), .oai)
    XCTAssertEqual(lookupVowelSeq(.o, .a, .y), .oay)
    XCTAssertEqual(lookupVowelSeq(.u, .y, .a), .uya)
    XCTAssertEqual(lookupVowelSeq(.i, .er, .u), .ieru)  // iêu
    XCTAssertEqual(lookupVowelSeq(.y, .er, .u), .yeru)  // yêu
    XCTAssertEqual(lookupVowelSeq(.uh, .oh, .i), .uhohi)  // ươi
  }

  // MARK: - Invalid Sequence Tests

  func testInvalidSequences() {
    XCTAssertEqual(lookupVowelSeq(.b), .none)  // consonant
    XCTAssertEqual(lookupVowelSeq(.a, .a), .none)  // aa invalid
    XCTAssertEqual(lookupVowelSeq(.e, .e), .none)  // ee invalid
  }

  // MARK: - VowelSeqInfo Tests

  func testGetVowelSeqInfo() {
    // Single vowel
    let aInfo = getVowelSeqInfo(.a)
    XCTAssertNotNil(aInfo)
    XCTAssertEqual(aInfo?.length, 1)
    XCTAssertTrue(aInfo?.isComplete ?? false)
    XCTAssertEqual(aInfo?.withRoof, .ar)
    XCTAssertEqual(aInfo?.withHook, .ab)

    // Double vowel
    let uoInfo = getVowelSeqInfo(.uo)
    XCTAssertNotNil(uoInfo)
    XCTAssertEqual(uoInfo?.length, 2)
    XCTAssertFalse(uoInfo?.isComplete ?? true)  // incomplete
    XCTAssertEqual(uoInfo?.withRoof, .uor)
    XCTAssertEqual(uoInfo?.withHook, .uho)

    // Triple vowel
    let oaiInfo = getVowelSeqInfo(.oai)
    XCTAssertNotNil(oaiInfo)
    XCTAssertEqual(oaiInfo?.length, 3)
    XCTAssertTrue(oaiInfo?.isComplete ?? false)
  }
}
