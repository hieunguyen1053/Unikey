// Unikey Swift Engine - Vowel Sequences
// Ported from x-unikey-1.0.4/src/ukengine/vnlexi.h
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Gemini

import Foundation

/// Vietnamese vowel sequences - all valid combinations of vowels
/// Examples: a, ă, â, ai, ao, au, ay, ươi, uya, etc.
public enum VowelSequence: Int, CaseIterable {
  case none = -1

  // Single vowels
  case a = 0
  case ar  // â
  case ab  // ă
  case e
  case er  // ê
  case i
  case o
  case or  // ô
  case oh  // ơ
  case u
  case uh  // ư
  case y

  // Double vowels (12-47)
  case ai, ao, au, ay
  case aru, ary  // âu, ây
  case eo, eu, eru  // êu
  case ia, ie, ier, iu  // iê
  case oa, oab, oe, oi, ori, ohi  // oă, ôi, ơi
  case ua, uar, ue, uer, ui, uo, uor, uoh, uu, uy  // uâ, uê, uô, uơ
  case uha, uhi, uho, uhoh, uhu  // ưa, ươ
  case ye, yer  // yê

  // Triple vowels (48-70)
  case ieu, ieru  // iêu
  case oai, oay, oeo  // oai, oay
  case uay, uary  // uây
  case uoi, uou, uori, uohi, uohu  // uôi, ươi
  case uya, uye, uyer, uyu  // uyê
  case uhoi, uhou, uhohi, uhohu  // ươi, ươu
  case yeu, yeru  // yêu
}

/// Information about a vowel sequence
public struct VowelSeqInfo {
  /// Number of vowels in sequence (1-3)
  public let length: Int

  /// Whether this is a complete vowel sequence (can end a word)
  public let isComplete: Bool

  /// Whether consonant suffix is allowed (c, m, n, ng, nh, p, t)
  public let allowsConsonantSuffix: Bool

  /// Component vowels (up to 3)
  public let vowels: [VnLexiName]

  /// Subsequences at each position
  public let subsequences: [VowelSequence]

  /// Position where roof (^) can be added (-1 if none)
  public let roofPosition: Int

  /// Result of adding roof
  public let withRoof: VowelSequence

  /// Position where hook (ư, ơ) can be added (-1 if none)
  public let hookPosition: Int

  /// Result of adding hook
  public let withHook: VowelSequence

  public init(
    length: Int,
    isComplete: Bool,
    allowsConsonantSuffix: Bool,
    vowels: [VnLexiName],
    subsequences: [VowelSequence],
    roofPosition: Int = -1,
    withRoof: VowelSequence = .none,
    hookPosition: Int = -1,
    withHook: VowelSequence = .none
  ) {
    self.length = length
    self.isComplete = isComplete
    self.allowsConsonantSuffix = allowsConsonantSuffix
    self.vowels = vowels
    self.subsequences = subsequences
    self.roofPosition = roofPosition
    self.withRoof = withRoof
    self.hookPosition = hookPosition
    self.withHook = withHook
  }
}

// MARK: - Lookup Functions

/// Lookup vowel sequence from 1-3 vowels
public func lookupVowelSeq(
  _ v1: VnLexiName, _ v2: VnLexiName = .nonVnChar, _ v3: VnLexiName = .nonVnChar
) -> VowelSequence {
  // Use pre-sorted binary search for performance
  let key = VowelSeqKey(v1: v1, v2: v2, v3: v3)

  if let index = sortedVSeqList.binarySearch(for: key) {
    return sortedVSeqList[index].sequence
  }
  return .none
}

// MARK: - Internal Key Type

public struct VowelSeqKey: Comparable {
  public let v1: VnLexiName
  public let v2: VnLexiName
  public let v3: VnLexiName
  public let sequence: VowelSequence

  public init(
    v1: VnLexiName, v2: VnLexiName = .nonVnChar, v3: VnLexiName = .nonVnChar,
    sequence: VowelSequence = .none
  ) {
    self.v1 = v1
    self.v2 = v2
    self.v3 = v3
    self.sequence = sequence
  }

  public static func < (lhs: VowelSeqKey, rhs: VowelSeqKey) -> Bool {
    if lhs.v1.rawValue != rhs.v1.rawValue { return lhs.v1.rawValue < rhs.v1.rawValue }
    if lhs.v2.rawValue != rhs.v2.rawValue { return lhs.v2.rawValue < rhs.v2.rawValue }
    return lhs.v3.rawValue < rhs.v3.rawValue
  }

  public static func == (lhs: VowelSeqKey, rhs: VowelSeqKey) -> Bool {
    return lhs.v1 == rhs.v1 && lhs.v2 == rhs.v2 && lhs.v3 == rhs.v3
  }
}

extension Array where Element == VowelSeqKey {
  func binarySearch(for key: VowelSeqKey) -> Int? {
    var low = 0
    var high = count - 1

    while low <= high {
      let mid = (low + high) / 2
      if self[mid] == key {
        return mid
      } else if self[mid] < key {
        low = mid + 1
      } else {
        high = mid - 1
      }
    }
    return nil
  }
}
