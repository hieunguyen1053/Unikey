// Unikey Swift Engine
// Ported from x-unikey-1.0.4/src/ukengine/vnlexi.h
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Jules

import Foundation

public enum VowelSequence: Int, CaseIterable {
  case none = -1  // vs_nil

  // Single vowels
  case a, ar, ab, e, er, i, o, or, oh, u, uh, y

  // Double vowels
  case ai, ao, au, ay
  case aru, ary
  case eo, eu, eru
  case ia, ie, ier, iu
  case oa, oab, oe, oi, ori, ohi
  case ua, uar, ue, uer, ui, uo, uor, uoh, uu, uy
  case uha, uhi, uho, uhoh, uhu
  case ye, yer

  // Triple vowels
  case ieu, ieru
  case oai, oay, oeo
  case uay, uary, uoi, uou, uori, uohi, uohu
  case uya, uye, uyer, uyu
  case uhoi, uhou, uhohi, uhohu
  case yeu, yeru
}

public struct VowelSeqInfo {
  public var length: Int
  public var complete: Bool
  public var conSuffix: Bool  // allow consonant suffix
  public var vowels: [VnLexiName]
  public var subsequences: [VowelSequence]
  public var withRoof: VowelSequence
  public var withHook: VowelSequence
  public var roofPosition: Int
  public var hookPosition: Int

  public init(
    length: Int,
    complete: Bool,
    conSuffix: Bool,
    vowels: [VnLexiName],
    subsequences: [VowelSequence],
    withRoof: VowelSequence = .none,
    withHook: VowelSequence = .none,
    roofPosition: Int = -1,
    hookPosition: Int = -1
  ) {
    self.length = length
    self.complete = complete
    self.conSuffix = conSuffix
    self.vowels = vowels
    self.subsequences = subsequences
    self.withRoof = withRoof
    self.withHook = withHook
    self.roofPosition = roofPosition
    self.hookPosition = hookPosition
  }
}

// Global lookup table (simulated)
private let vowelSeqTable: [VowelSequence: VowelSeqInfo] = [
  // Single - complete=true, conSuffix=true for most
  .a: VowelSeqInfo(
    length: 1,
    complete: true,
    conSuffix: true,
    vowels: [.a],
    subsequences: [.a],
    withRoof: .ar,
    withHook: .ab,
    roofPosition: 0,
    hookPosition: 0
  ),
  .ar: VowelSeqInfo(
    length: 1,
    complete: true,
    conSuffix: true,
    vowels: [.ar],
    subsequences: [.ar],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: -1
  ),
  .ab: VowelSeqInfo(
    length: 1,
    complete: true,
    conSuffix: true,
    vowels: [.ab],
    subsequences: [.ab],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: 0
  ),
  .e: VowelSeqInfo(
    length: 1,
    complete: true,
    conSuffix: true,
    vowels: [.e],
    subsequences: [.e],
    withRoof: .er,
    withHook: .none,
    roofPosition: 0,
    hookPosition: -1
  ),
  .er: VowelSeqInfo(
    length: 1,
    complete: true,
    conSuffix: true,
    vowels: [.er],
    subsequences: [.er],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: -1
  ),
  .i: VowelSeqInfo(
    length: 1,
    complete: true,
    conSuffix: true,
    vowels: [.i],
    subsequences: [.i],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: -1
  ),
  .o: VowelSeqInfo(
    length: 1,
    complete: true,
    conSuffix: true,
    vowels: [.o],
    subsequences: [.o],
    withRoof: .or,
    withHook: .oh,
    roofPosition: 0,
    hookPosition: 0
  ),
  .or: VowelSeqInfo(
    length: 1,
    complete: true,
    conSuffix: true,
    vowels: [.or],
    subsequences: [.or],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: -1
  ),
  .oh: VowelSeqInfo(
    length: 1,
    complete: true,
    conSuffix: true,
    vowels: [.oh],
    subsequences: [.oh],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: 0
  ),
  .u: VowelSeqInfo(
    length: 1,
    complete: true,
    conSuffix: true,
    vowels: [.u],
    subsequences: [.u],
    withRoof: .none,
    withHook: .uh,
    roofPosition: -1,
    hookPosition: 0
  ),
  .uh: VowelSeqInfo(
    length: 1,
    complete: true,
    conSuffix: true,
    vowels: [.uh],
    subsequences: [.uh],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: 0
  ),
  .y: VowelSeqInfo(
    length: 1,
    complete: true,
    conSuffix: true,
    vowels: [.y],
    subsequences: [.y],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: -1
  ),

  // Double
  .ai: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.a, .i],
    subsequences: [.a, .ai],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: 0
  ),
  .ao: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.a, .o],
    subsequences: [.a, .ao],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: 0
  ),
  .au: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.a, .u],
    subsequences: [.a, .au],
    withRoof: .aru,
    withHook: .none,
    roofPosition: 0,
    hookPosition: 0
  ),
  .ay: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.a, .y],
    subsequences: [.a, .ay],
    withRoof: .ary,
    withHook: .none,
    roofPosition: 0,
    hookPosition: 0
  ),

  .aru: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.ar, .u],
    subsequences: [.ar, .aru],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: -1
  ),
  .ary: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.ar, .y],
    subsequences: [.ar, .ary],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: -1
  ),

  .eo: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.e, .o],
    subsequences: [.e, .eo],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: -1
  ),
  .eu: VowelSeqInfo(
    length: 2,
    complete: false,
    conSuffix: false,
    vowels: [.e, .u],
    subsequences: [.e, .eu],
    withRoof: .eru,
    withHook: .none,
    roofPosition: 0,
    hookPosition: -1
  ),
  .eru: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.er, .u],
    subsequences: [.er, .eru],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: -1
  ),

  .ia: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.i, .a],
    subsequences: [.i, .ia],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: -1
  ),
  .ie: VowelSeqInfo(
    length: 2,
    complete: false,
    conSuffix: true,
    vowels: [.i, .e],
    subsequences: [.i, .ie],
    withRoof: .ier,
    withHook: .none,
    roofPosition: 1,
    hookPosition: -1
  ),
  .ier: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: true,
    vowels: [.i, .er],
    subsequences: [.i, .ier],
    withRoof: .none,
    withHook: .none,
    roofPosition: 1,
    hookPosition: -1
  ),
  .iu: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.i, .u],
    subsequences: [.i, .iu],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: -1
  ),

  .oa: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: true,
    vowels: [.o, .a],
    subsequences: [.o, .oa],
    withRoof: .none,
    withHook: .oab,
    roofPosition: -1,
    hookPosition: -1
  ),
  .oab: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: true,
    vowels: [.o, .ab],
    subsequences: [.o, .oab],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: 1
  ),
  .oe: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: true,
    vowels: [.o, .e],
    subsequences: [.o, .oe],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: -1
  ),
  .oi: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.o, .i],
    subsequences: [.o, .oi],
    withRoof: .ori,
    withHook: .ohi,
    roofPosition: 0,
    hookPosition: 0
  ),
  .ori: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.or, .i],
    subsequences: [.or, .ori],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: -1
  ),
  .ohi: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.oh, .i],
    subsequences: [.oh, .ohi],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: 0
  ),

  .ua: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: true,
    vowels: [.u, .a],
    subsequences: [.u, .ua],
    withRoof: .uar,
    withHook: .uha,
    roofPosition: 1,
    hookPosition: 0
  ),
  .uar: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: true,
    vowels: [.u, .ar],
    subsequences: [.u, .uar],
    withRoof: .none,
    withHook: .none,
    roofPosition: 1,
    hookPosition: 0
  ),
  .ue: VowelSeqInfo(
    length: 2,
    complete: false,
    conSuffix: true,
    vowels: [.u, .e],
    subsequences: [.u, .ue],
    withRoof: .uer,
    withHook: .none,
    roofPosition: 1,
    hookPosition: -1
  ),
  .uer: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: true,
    vowels: [.u, .er],
    subsequences: [.u, .uer],
    withRoof: .none,
    withHook: .none,
    roofPosition: 1,
    hookPosition: -1
  ),
  .ui: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.u, .i],
    subsequences: [.u, .ui],
    withRoof: .none,
    withHook: .uhi,
    roofPosition: -1,
    hookPosition: 0
  ),
  .uo: VowelSeqInfo(
    length: 2,
    complete: false,
    conSuffix: true,
    vowels: [.u, .o],
    subsequences: [.u, .uo],
    withRoof: .uor,
    withHook: .uho,
    roofPosition: 1,
    hookPosition: 1
  ),
  .uor: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: true,
    vowels: [.u, .or],
    subsequences: [.u, .uor],
    withRoof: .none,
    withHook: .none,
    roofPosition: 1,
    hookPosition: -1
  ),
  .uoh: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: true,
    vowels: [.u, .oh],
    subsequences: [.u, .uoh],
    withRoof: .none,
    withHook: .uhoh,
    roofPosition: -1,
    hookPosition: 1
  ),
  .uu: VowelSeqInfo(
    length: 2,
    complete: false,
    conSuffix: false,
    vowels: [.u, .u],
    subsequences: [.u, .uu],
    withRoof: .none,
    withHook: .uhu,
    roofPosition: -1,
    hookPosition: 0
  ),
  .uy: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: true,
    vowels: [.u, .y],
    subsequences: [.u, .uy],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: -1
  ),

  .uha: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.uh, .a],
    subsequences: [.uh, .uha],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: 0
  ),
  .uhi: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.uh, .i],
    subsequences: [.uh, .uhi],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: 0
  ),
  .uho: VowelSeqInfo(
    length: 2,
    complete: false,
    conSuffix: true,
    vowels: [.uh, .o],
    subsequences: [.uh, .uho],
    withRoof: .none,
    withHook: .uhoh,
    roofPosition: -1,
    hookPosition: 0
  ),
  .uhoh: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: true,
    vowels: [.uh, .oh],
    subsequences: [.uh, .uhoh],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: 0
  ),
  .uhu: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: false,
    vowels: [.uh, .u],
    subsequences: [.uh, .uhu],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: 0
  ),

  .ye: VowelSeqInfo(
    length: 2,
    complete: false,
    conSuffix: true,
    vowels: [.y, .e],
    subsequences: [.y, .ye],
    withRoof: .yer,
    withHook: .none,
    roofPosition: 1,
    hookPosition: -1
  ),
  .yer: VowelSeqInfo(
    length: 2,
    complete: true,
    conSuffix: true,
    vowels: [.y, .er],
    subsequences: [.y, .yer],
    withRoof: .none,
    withHook: .none,
    roofPosition: 1,
    hookPosition: -1
  ),

  // Triple
  .ieu: VowelSeqInfo(
    length: 3,
    complete: false,
    conSuffix: false,
    vowels: [.i, .e, .u],
    subsequences: [.i, .ie, .ieu],
    withRoof: .ieru,
    withHook: .none,
    roofPosition: 1,
    hookPosition: -1
  ),
  .ieru: VowelSeqInfo(
    length: 3,
    complete: true,
    conSuffix: false,
    vowels: [.i, .er, .u],
    subsequences: [.i, .ier, .ieru],
    withRoof: .none,
    withHook: .none,
    roofPosition: 1,
    hookPosition: -1
  ),

  .oai: VowelSeqInfo(
    length: 3,
    complete: true,
    conSuffix: false,
    vowels: [.o, .a, .i],
    subsequences: [.o, .oa, .oai],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: 1
  ),
  .oay: VowelSeqInfo(
    length: 3,
    complete: true,
    conSuffix: false,
    vowels: [.o, .a, .y],
    subsequences: [.o, .oa, .oay],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: 1
  ),
  .oeo: VowelSeqInfo(
    length: 3,
    complete: true,
    conSuffix: false,
    vowels: [.o, .e, .o],
    subsequences: [.o, .oe, .oeo],
    withRoof: .none,
    withHook: .none,
    roofPosition: 0,
    hookPosition: -1
  ),

  .uay: VowelSeqInfo(
    length: 3,
    complete: false,
    conSuffix: false,
    vowels: [.u, .a, .y],
    subsequences: [.u, .ua, .uay],
    withRoof: .uary,
    withHook: .none,
    roofPosition: 1,
    hookPosition: 0
  ),
  .uary: VowelSeqInfo(
    length: 3,
    complete: true,
    conSuffix: false,
    vowels: [.u, .ar, .y],
    subsequences: [.u, .uar, .uary],
    withRoof: .none,
    withHook: .none,
    roofPosition: 1,
    hookPosition: 0
  ),
  .uoi: VowelSeqInfo(
    length: 3,
    complete: false,
    conSuffix: false,
    vowels: [.u, .o, .i],
    subsequences: [.u, .uo, .uoi],
    withRoof: .uori,
    withHook: .uohi,
    roofPosition: 1,
    hookPosition: 1
  ),
  .uou: VowelSeqInfo(
    length: 3,
    complete: false,
    conSuffix: false,
    vowels: [.u, .o, .u],
    subsequences: [.u, .uo, .uou],
    withRoof: .none,
    withHook: .uohu,
    roofPosition: 1,
    hookPosition: 1
  ),
  .uori: VowelSeqInfo(
    length: 3,
    complete: true,
    conSuffix: false,
    vowels: [.u, .or, .i],
    subsequences: [.u, .uor, .uori],
    withRoof: .none,
    withHook: .none,
    roofPosition: 1,
    hookPosition: -1
  ),
  .uohi: VowelSeqInfo(
    length: 3,
    complete: false,
    conSuffix: false,
    vowels: [.u, .oh, .i],
    subsequences: [.u, .uoh, .uohi],
    withRoof: .none,
    withHook: .uhohi,
    roofPosition: -1,
    hookPosition: 1
  ),
  .uohu: VowelSeqInfo(
    length: 3,
    complete: false,
    conSuffix: false,
    vowels: [.u, .oh, .u],
    subsequences: [.u, .uoh, .uohu],
    withRoof: .none,
    withHook: .uhohu,
    roofPosition: -1,
    hookPosition: 1
  ),

  .uya: VowelSeqInfo(
    length: 3,
    complete: true,
    conSuffix: false,
    vowels: [.u, .y, .a],
    subsequences: [.u, .uy, .uya],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: 0
  ),
  .uye: VowelSeqInfo(
    length: 3,
    complete: false,
    conSuffix: true,
    vowels: [.u, .y, .e],
    subsequences: [.u, .uy, .uye],
    withRoof: .uyer,
    withHook: .none,
    roofPosition: 2,
    hookPosition: -1
  ),
  .uyer: VowelSeqInfo(
    length: 3,
    complete: true,
    conSuffix: true,
    vowels: [.u, .y, .er],
    subsequences: [.u, .uy, .uyer],
    withRoof: .none,
    withHook: .none,
    roofPosition: 2,
    hookPosition: -1
  ),
  .uyu: VowelSeqInfo(
    length: 3,
    complete: true,
    conSuffix: false,
    vowels: [.u, .y, .u],
    subsequences: [.u, .uy, .uyu],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: 0
  ),

  .uhoi: VowelSeqInfo(
    length: 3,
    complete: false,
    conSuffix: false,
    vowels: [.uh, .o, .i],
    subsequences: [.uh, .uho, .uhoi],
    withRoof: .none,
    withHook: .uhohi,
    roofPosition: -1,
    hookPosition: 0
  ),
  .uhou: VowelSeqInfo(
    length: 3,
    complete: false,
    conSuffix: false,
    vowels: [.uh, .o, .u],
    subsequences: [.uh, .uho, .uhou],
    withRoof: .none,
    withHook: .uhohu,
    roofPosition: -1,
    hookPosition: 0
  ),
  .uhohi: VowelSeqInfo(
    length: 3,
    complete: true,
    conSuffix: false,
    vowels: [.uh, .oh, .i],
    subsequences: [.uh, .uhoh, .uhohi],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: 0
  ),
  .uhohu: VowelSeqInfo(
    length: 3,
    complete: true,
    conSuffix: false,
    vowels: [.uh, .oh, .u],
    subsequences: [.uh, .uhoh, .uhohu],
    withRoof: .none,
    withHook: .none,
    roofPosition: -1,
    hookPosition: 0
  ),

  .yeu: VowelSeqInfo(
    length: 3,
    complete: false,
    conSuffix: false,
    vowels: [.y, .e, .u],
    subsequences: [.y, .ye, .yeu],
    withRoof: .yeru,
    withHook: .none,
    roofPosition: 1,
    hookPosition: -1
  ),
  .yeru: VowelSeqInfo(
    length: 3,
    complete: true,
    conSuffix: false,
    vowels: [.y, .er, .u],
    subsequences: [.y, .yer, .yeru],
    withRoof: .none,
    withHook: .none,
    roofPosition: 1,
    hookPosition: -1
  ),
]

// MARK: - Helper Functions

public func getVowelSeqInfo(_ seq: VowelSequence) -> VowelSeqInfo? {
  return vowelSeqTable[seq]
}

public func lookupVowelSeq(
  _ v1: VnLexiName,
  _ v2: VnLexiName = .nonVnChar,
  _ v3: VnLexiName = .nonVnChar
) -> VowelSequence {
  // Normalize input to base char
  let b1 = v1.baseChar
  let b2 = v2.baseChar
  let b3 = v3.baseChar

  if b1 == .nonVnChar { return .none }

  if b2 == .nonVnChar {
    // Single
    for (seq, info) in vowelSeqTable where info.length == 1 {
      if info.vowels[0] == b1 { return seq }
    }
  } else if b3 == .nonVnChar {
    // Double
    for (seq, info) in vowelSeqTable where info.length == 2 {
      if info.vowels[0] == b1 && info.vowels[1] == b2 { return seq }
    }
  } else {
    // Triple
    for (seq, info) in vowelSeqTable where info.length == 3 {
      if info.vowels[0] == b1 && info.vowels[1] == b2
        && info.vowels[2] == b3
      {
        return seq
      }
    }
  }

  return .none
}
