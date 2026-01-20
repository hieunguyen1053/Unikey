// Unikey Swift Engine - Consonant Sequences
// Ported from x-unikey-1.0.4/src/ukengine/vnlexi.h
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Gemini

import Foundation

/// Vietnamese consonant sequences - all valid consonant combinations
/// Examples: b, c, ch, d, đ, g, gh, gi, k, kh, l, m, n, ng, ngh, nh, etc.
public enum ConsonantSequence: Int, CaseIterable {
  case none = -1

  case b = 0
  case c
  case ch
  case d
  case dd  // đ
  case dz
  case g
  case gh
  case gi
  case gin  // special: gin (as in "gìn")
  case k
  case kh
  case l
  case m
  case n
  case ng
  case ngh
  case nh
  case p
  case ph
  case q
  case qu
  case r
  case s
  case t
  case th
  case tr
  case v
  case x
}

/// Information about a consonant sequence
public struct ConsonantSeqInfo {
  /// Number of consonants in sequence (1-3)
  public let length: Int

  /// Component consonants (up to 3)
  public let consonants: [VnLexiName]

  /// Whether this can be a word suffix (ending consonant)
  public let canBeSuffix: Bool

  public init(length: Int, consonants: [VnLexiName], canBeSuffix: Bool) {
    self.length = length
    self.consonants = consonants
    self.canBeSuffix = canBeSuffix
  }
}

/// Consonant sequence information table (ported from ukengine.cpp CSeqList)
public let consonantSeqList: [ConsonantSeqInfo] = [
  // cs_b
  ConsonantSeqInfo(length: 1, consonants: [.b], canBeSuffix: false),
  // cs_c
  ConsonantSeqInfo(length: 1, consonants: [.c], canBeSuffix: true),
  // cs_ch
  ConsonantSeqInfo(length: 2, consonants: [.c, .h], canBeSuffix: true),
  // cs_d
  ConsonantSeqInfo(length: 1, consonants: [.d], canBeSuffix: false),
  // cs_dd (đ)
  ConsonantSeqInfo(length: 1, consonants: [.dd], canBeSuffix: false),
  // cs_dz
  ConsonantSeqInfo(length: 2, consonants: [.d, .z], canBeSuffix: false),
  // cs_g
  ConsonantSeqInfo(length: 1, consonants: [.g], canBeSuffix: false),
  // cs_gh
  ConsonantSeqInfo(length: 2, consonants: [.g, .h], canBeSuffix: false),
  // cs_gi
  ConsonantSeqInfo(length: 2, consonants: [.g, .i], canBeSuffix: false),
  // cs_gin
  ConsonantSeqInfo(length: 3, consonants: [.g, .i, .n], canBeSuffix: false),
  // cs_k
  ConsonantSeqInfo(length: 1, consonants: [.k], canBeSuffix: false),
  // cs_kh
  ConsonantSeqInfo(length: 2, consonants: [.k, .h], canBeSuffix: false),
  // cs_l
  ConsonantSeqInfo(length: 1, consonants: [.l], canBeSuffix: false),
  // cs_m
  ConsonantSeqInfo(length: 1, consonants: [.m], canBeSuffix: true),
  // cs_n
  ConsonantSeqInfo(length: 1, consonants: [.n], canBeSuffix: true),
  // cs_ng
  ConsonantSeqInfo(length: 2, consonants: [.n, .g], canBeSuffix: true),
  // cs_ngh
  ConsonantSeqInfo(length: 3, consonants: [.n, .g, .h], canBeSuffix: false),
  // cs_nh
  ConsonantSeqInfo(length: 2, consonants: [.n, .h], canBeSuffix: true),
  // cs_p
  ConsonantSeqInfo(length: 1, consonants: [.p], canBeSuffix: true),
  // cs_ph
  ConsonantSeqInfo(length: 2, consonants: [.p, .h], canBeSuffix: false),
  // cs_q
  ConsonantSeqInfo(length: 1, consonants: [.q], canBeSuffix: false),
  // cs_qu
  ConsonantSeqInfo(length: 2, consonants: [.q, .u], canBeSuffix: false),
  // cs_r
  ConsonantSeqInfo(length: 1, consonants: [.r], canBeSuffix: false),
  // cs_s
  ConsonantSeqInfo(length: 1, consonants: [.s], canBeSuffix: false),
  // cs_t
  ConsonantSeqInfo(length: 1, consonants: [.t], canBeSuffix: true),
  // cs_th
  ConsonantSeqInfo(length: 2, consonants: [.t, .h], canBeSuffix: false),
  // cs_tr
  ConsonantSeqInfo(length: 2, consonants: [.t, .r], canBeSuffix: false),
  // cs_v
  ConsonantSeqInfo(length: 1, consonants: [.v], canBeSuffix: false),
  // cs_x
  ConsonantSeqInfo(length: 1, consonants: [.x], canBeSuffix: false),
]

// MARK: - Lookup Functions

/// Lookup consonant sequence from 1-3 consonants
public func lookupConsonantSeq(
  _ c1: VnLexiName, _ c2: VnLexiName = .nonVnChar, _ c3: VnLexiName = .nonVnChar
) -> ConsonantSequence {
  for (index, info) in consonantSeqList.enumerated() {
    let matches: Bool
    switch info.length {
    case 1:
      matches = info.consonants[0] == c1 && c2 == .nonVnChar && c3 == .nonVnChar
    case 2:
      matches = info.consonants[0] == c1 && info.consonants[1] == c2 && c3 == .nonVnChar
    case 3:
      matches = info.consonants[0] == c1 && info.consonants[1] == c2 && info.consonants[2] == c3
    default:
      matches = false
    }
    if matches {
      return ConsonantSequence(rawValue: index) ?? .none
    }
  }
  return .none
}

/// Get info for a consonant sequence
public func getConsonantSeqInfo(_ seq: ConsonantSequence) -> ConsonantSeqInfo? {
  guard seq != .none, seq.rawValue >= 0 && seq.rawValue < consonantSeqList.count else {
    return nil
  }
  return consonantSeqList[seq.rawValue]
}
