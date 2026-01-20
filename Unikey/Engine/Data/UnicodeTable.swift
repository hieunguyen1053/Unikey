// Unikey Swift Engine - Unicode Character Mapping
// Ported from x-unikey-1.0.4/src/vnconv/data.cpp
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Gemini

import Foundation

/// Maps VnLexiName to Unicode characters
/// Order matches VnLexiName enum (0 = A, 1 = a, etc.)
public let vnLexiToUnicode: [Character] = [
  // A, a (0, 1)
  "A", "a",
  // A with tones (2-11): A1=Á, a1=á, A2=À, a2=à, A3=Ả, a3=ả, A4=Ã, a4=ã, A5=Ạ, a5=ạ
  "Á", "á", "À", "à", "Ả", "ả", "Ã", "ã", "Ạ", "ạ",

  // Ar = Â (12, 13)
  "Â", "â",
  // Â with tones (14-23): Ấ, ấ, Ầ, ầ, Ẩ, ẩ, Ẫ, ẫ, Ậ, ậ
  "Ấ", "ấ", "Ầ", "ầ", "Ẩ", "ẩ", "Ẫ", "ẫ", "Ậ", "ậ",

  // Ab = Ă (24, 25)
  "Ă", "ă",
  // Ă with tones (26-35): Ắ, ắ, Ằ, ằ, Ẳ, ẳ, Ẵ, ẵ, Ặ, ặ
  "Ắ", "ắ", "Ằ", "ằ", "Ẳ", "ẳ", "Ẵ", "ẵ", "Ặ", "ặ",

  // B, b, C, c (36-39)
  "B", "b", "C", "c",

  // D, d, DD=Đ, dd=đ (40-43)
  "D", "d", "Đ", "đ",

  // E, e (44, 45)
  "E", "e",
  // E with tones (46-55): É, é, È, è, Ẻ, ẻ, Ẽ, ẽ, Ẹ, ẹ
  "É", "é", "È", "è", "Ẻ", "ẻ", "Ẽ", "ẽ", "Ẹ", "ẹ",

  // Er = Ê (56, 57)
  "Ê", "ê",
  // Ê with tones (58-67): Ế, ế, Ề, ề, Ể, ể, Ễ, ễ, Ệ, ệ
  "Ế", "ế", "Ề", "ề", "Ể", "ể", "Ễ", "ễ", "Ệ", "ệ",

  // F, f, G, g, H, h (68-73)
  "F", "f", "G", "g", "H", "h",

  // I, i (74, 75)
  "I", "i",
  // I with tones (76-85): Í, í, Ì, ì, Ỉ, ỉ, Ĩ, ĩ, Ị, ị
  "Í", "í", "Ì", "ì", "Ỉ", "ỉ", "Ĩ", "ĩ", "Ị", "ị",

  // J, j, K, k, L, l, M, m, N, n (86-95)
  "J", "j", "K", "k", "L", "l", "M", "m", "N", "n",

  // O, o (96, 97)
  "O", "o",
  // O with tones (98-107): Ó, ó, Ò, ò, Ỏ, ỏ, Õ, õ, Ọ, ọ
  "Ó", "ó", "Ò", "ò", "Ỏ", "ỏ", "Õ", "õ", "Ọ", "ọ",

  // Or = Ô (108, 109)
  "Ô", "ô",
  // Ô with tones (110-119): Ố, ố, Ồ, ồ, Ổ, ổ, Ỗ, ỗ, Ộ, ộ
  "Ố", "ố", "Ồ", "ồ", "Ổ", "ổ", "Ỗ", "ỗ", "Ộ", "ộ",

  // Oh = Ơ (120, 121)
  "Ơ", "ơ",
  // Ơ with tones (122-131): Ớ, ớ, Ờ, ờ, Ở, ở, Ỡ, ỡ, Ợ, ợ
  "Ớ", "ớ", "Ờ", "ờ", "Ở", "ở", "Ỡ", "ỡ", "Ợ", "ợ",

  // P, p, Q, q, R, r, S, s, T, t (132-141)
  "P", "p", "Q", "q", "R", "r", "S", "s", "T", "t",

  // U, u (142, 143)
  "U", "u",
  // U with tones (144-153): Ú, ú, Ù, ù, Ủ, ủ, Ũ, ũ, Ụ, ụ
  "Ú", "ú", "Ù", "ù", "Ủ", "ủ", "Ũ", "ũ", "Ụ", "ụ",

  // Uh = Ư (154, 155)
  "Ư", "ư",
  // Ư with tones (156-165): Ứ, ứ, Ừ, ừ, Ử, ử, Ữ, ữ, Ự, ự
  "Ứ", "ứ", "Ừ", "ừ", "Ử", "ử", "Ữ", "ữ", "Ự", "ự",

  // V, v, W, w, X, x (166-171)
  "V", "v", "W", "w", "X", "x",

  // Y, y (172, 173)
  "Y", "y",
  // Y with tones (174-183): Ý, ý, Ỳ, ỳ, Ỷ, ỷ, Ỹ, ỹ, Ỵ, ỵ
  "Ý", "ý", "Ỳ", "ỳ", "Ỷ", "ỷ", "Ỹ", "ỹ", "Ỵ", "ỵ",

  // Z, z (184, 185)
  "Z", "z",
]

extension VnLexiName {
  /// Convert to Unicode character
  public var toUnicode: Character {
    guard self.rawValue >= 0 && self.rawValue < vnLexiToUnicode.count else {
      return "?"
    }
    return vnLexiToUnicode[self.rawValue]
  }

  /// Get lowercase version
  public var lowercase: VnLexiName {
    guard isUppercase else { return self }
    // Each uppercase/lowercase pair: Upper at even index, lower at odd
    guard let lower = VnLexiName(rawValue: self.rawValue + 1) else { return self }
    return lower
  }

  /// Get uppercase version
  public var uppercase: VnLexiName {
    guard !isUppercase else { return self }
    // Each uppercase/lowercase pair: Upper at even index, lower at odd
    guard self.rawValue > 0 else { return self }
    guard let upper = VnLexiName(rawValue: self.rawValue - 1) else { return self }
    return upper
  }

  /// Check if this can have a roof (^) added
  public var canHaveRoof: Bool {
    switch baseChar {
    case .A, .a, .E, .e, .O, .o: return true
    default: return false
    }
  }

  /// Add roof (^) to this character
  public var withRoof: VnLexiName {
    let tone = self.tone
    let upper = self.isUppercase

    switch baseChar {
    case .A, .a:
      let base: VnLexiName = upper ? .Ar : .ar
      return base.withTone(tone)
    case .E, .e:
      let base: VnLexiName = upper ? .Er : .er
      return base.withTone(tone)
    case .O, .o:
      let base: VnLexiName = upper ? .Or : .or
      return base.withTone(tone)
    default:
      return self
    }
  }

  /// Check if this can have a hook/horn added
  public var canHaveHook: Bool {
    switch baseChar {
    case .U, .u, .O, .o, .A, .a: return true
    default: return false
    }
  }

  /// Add hook/horn to this character (ư, ơ, ă)
  public var withHook: VnLexiName {
    let tone = self.tone
    let upper = self.isUppercase

    switch baseChar {
    case .U, .u:
      let base: VnLexiName = upper ? .Uh : .uh
      return base.withTone(tone)
    case .O, .o:
      let base: VnLexiName = upper ? .Oh : .oh
      return base.withTone(tone)
    case .A, .a:
      let base: VnLexiName = upper ? .Ab : .ab
      return base.withTone(tone)
    default:
      return self
    }
  }

  /// Remove roof from this character
  public var withoutRoof: VnLexiName {
    let tone = self.tone
    let upper = self.isUppercase

    switch baseChar {
    case .Ar, .ar:
      let base: VnLexiName = upper ? .A : .a
      return base.withTone(tone)
    case .Er, .er:
      let base: VnLexiName = upper ? .E : .e
      return base.withTone(tone)
    case .Or, .or:
      let base: VnLexiName = upper ? .O : .o
      return base.withTone(tone)
    default:
      return self
    }
  }

  /// Remove hook from this character
  public var withoutHook: VnLexiName {
    let tone = self.tone
    let upper = self.isUppercase

    switch baseChar {
    case .Uh, .uh:
      let base: VnLexiName = upper ? .U : .u
      return base.withTone(tone)
    case .Oh, .oh:
      let base: VnLexiName = upper ? .O : .o
      return base.withTone(tone)
    case .Ab, .ab:
      let base: VnLexiName = upper ? .A : .a
      return base.withTone(tone)
    default:
      return self
    }
  }
}
