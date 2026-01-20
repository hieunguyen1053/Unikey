// Unikey Swift Engine
// Ported from x-unikey-1.0.4/src/ukengine/vnlexi.h
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Gemini

import Foundation

/// Vietnamese lexical names - all possible Vietnamese characters with diacritics
/// Naming convention:
/// - Base letter (A, a, E, e, etc.)
/// - "r" suffix = roof/circumflex (^): Â, â, Ê, ê, Ô, ô
/// - "b" suffix = breve/bowl (˘): Ă, ă
/// - "h" suffix = hook/horn (ư, ơ): Ư, ư, Ơ, ơ
/// - Number suffix = tone: 1=sắc, 2=huyền, 3=hỏi, 4=ngã, 5=nặng
public enum VnLexiName: Int, CaseIterable {
    case nonVnChar = -1
    
    // A and variants (with tones 0-5)
    case A = 0, a, A1, a1, A2, a2, A3, a3, A4, a4, A5, a5
    // Â (A with circumflex)
    case Ar, ar, Ar1, ar1, Ar2, ar2, Ar3, ar3, Ar4, ar4, Ar5, ar5
    // Ă (A with breve)
    case Ab, ab, Ab1, ab1, Ab2, ab2, Ab3, ab3, Ab4, ab4, Ab5, ab5
    
    // B, C
    case B, b, C, c
    
    // D and Đ
    case D, d, DD, dd
    
    // E and variants
    case E, e, E1, e1, E2, e2, E3, e3, E4, e4, E5, e5
    // Ê (E with circumflex)
    case Er, er, Er1, er1, Er2, er2, Er3, er3, Er4, er4, Er5, er5
    
    // F, G, H
    case F, f, G, g, H, h
    
    // I and variants
    case I, i, I1, i1, I2, i2, I3, i3, I4, i4, I5, i5
    
    // J, K, L, M, N
    case J, j, K, k, L, l, M, m, N, n
    
    // O and variants
    case O, o, O1, o1, O2, o2, O3, o3, O4, o4, O5, o5
    // Ô (O with circumflex)
    case Or, or, Or1, or1, Or2, or2, Or3, or3, Or4, or4, Or5, or5
    // Ơ (O with horn)
    case Oh, oh, Oh1, oh1, Oh2, oh2, Oh3, oh3, Oh4, oh4, Oh5, oh5
    
    // P, Q, R, S, T
    case P, p, Q, q, R, r, S, s, T, t
    
    // U and variants
    case U, u, U1, u1, U2, u2, U3, u3, U4, u4, U5, u5
    // Ư (U with horn)
    case Uh, uh, Uh1, uh1, Uh2, uh2, Uh3, uh3, Uh4, uh4, Uh5, uh5
    
    // V, W, X
    case V, v, W, w, X, x
    
    // Y and variants
    case Y, y, Y1, y1, Y2, y2, Y3, y3, Y4, y4, Y5, y5
    
    // Z
    case Z, z
    
    case lastChar
    
    // MARK: - Properties
    
    /// Check if this is a vowel
    public var isVowel: Bool {
        switch baseChar {
        case .A, .a, .Ar, .ar, .Ab, .ab,
             .E, .e, .Er, .er,
             .I, .i,
             .O, .o, .Or, .or, .Oh, .oh,
             .U, .u, .Uh, .uh,
             .Y, .y:
            return true
        default:
            return false
        }
    }
    
    /// Get the base character without tone
    public var baseChar: VnLexiName {
        guard self.rawValue >= 0 else { return self }
        
        // Group: base + 5 tones = 12 values per base vowel
        // For vowels with tones: base is at index 0, 12, 24... in each group
        switch self {
        case .A, .A1, .A2, .A3, .A4, .A5: return .A
        case .a, .a1, .a2, .a3, .a4, .a5: return .a
        case .Ar, .Ar1, .Ar2, .Ar3, .Ar4, .Ar5: return .Ar
        case .ar, .ar1, .ar2, .ar3, .ar4, .ar5: return .ar
        case .Ab, .Ab1, .Ab2, .Ab3, .Ab4, .Ab5: return .Ab
        case .ab, .ab1, .ab2, .ab3, .ab4, .ab5: return .ab
        case .E, .E1, .E2, .E3, .E4, .E5: return .E
        case .e, .e1, .e2, .e3, .e4, .e5: return .e
        case .Er, .Er1, .Er2, .Er3, .Er4, .Er5: return .Er
        case .er, .er1, .er2, .er3, .er4, .er5: return .er
        case .I, .I1, .I2, .I3, .I4, .I5: return .I
        case .i, .i1, .i2, .i3, .i4, .i5: return .i
        case .O, .O1, .O2, .O3, .O4, .O5: return .O
        case .o, .o1, .o2, .o3, .o4, .o5: return .o
        case .Or, .Or1, .Or2, .Or3, .Or4, .Or5: return .Or
        case .or, .or1, .or2, .or3, .or4, .or5: return .or
        case .Oh, .Oh1, .Oh2, .Oh3, .Oh4, .Oh5: return .Oh
        case .oh, .oh1, .oh2, .oh3, .oh4, .oh5: return .oh
        case .U, .U1, .U2, .U3, .U4, .U5: return .U
        case .u, .u1, .u2, .u3, .u4, .u5: return .u
        case .Uh, .Uh1, .Uh2, .Uh3, .Uh4, .Uh5: return .Uh
        case .uh, .uh1, .uh2, .uh3, .uh4, .uh5: return .uh
        case .Y, .Y1, .Y2, .Y3, .Y4, .Y5: return .Y
        case .y, .y1, .y2, .y3, .y4, .y5: return .y
        default: return self
        }
    }
    
    /// Get tone (0-5, where 0 = no tone)
    public var tone: Int {
        guard self.rawValue >= 0 else { return 0 }
        
        switch self {
        case .A1, .a1, .Ar1, .ar1, .Ab1, .ab1,
             .E1, .e1, .Er1, .er1, .I1, .i1,
             .O1, .o1, .Or1, .or1, .Oh1, .oh1,
             .U1, .u1, .Uh1, .uh1, .Y1, .y1:
            return 1  // sắc
        case .A2, .a2, .Ar2, .ar2, .Ab2, .ab2,
             .E2, .e2, .Er2, .er2, .I2, .i2,
             .O2, .o2, .Or2, .or2, .Oh2, .oh2,
             .U2, .u2, .Uh2, .uh2, .Y2, .y2:
            return 2  // huyền
        case .A3, .a3, .Ar3, .ar3, .Ab3, .ab3,
             .E3, .e3, .Er3, .er3, .I3, .i3,
             .O3, .o3, .Or3, .or3, .Oh3, .oh3,
             .U3, .u3, .Uh3, .uh3, .Y3, .y3:
            return 3  // hỏi
        case .A4, .a4, .Ar4, .ar4, .Ab4, .ab4,
             .E4, .e4, .Er4, .er4, .I4, .i4,
             .O4, .o4, .Or4, .or4, .Oh4, .oh4,
             .U4, .u4, .Uh4, .uh4, .Y4, .y4:
            return 4  // ngã
        case .A5, .a5, .Ar5, .ar5, .Ab5, .ab5,
             .E5, .e5, .Er5, .er5, .I5, .i5,
             .O5, .o5, .Or5, .or5, .Oh5, .oh5,
             .U5, .u5, .Uh5, .uh5, .Y5, .y5:
            return 5  // nặng
        default:
            return 0  // no tone
        }
    }
    
    /// Check if uppercase
    public var isUppercase: Bool {
        guard self.rawValue >= 0 else { return false }
        
        switch self {
        case .A, .A1, .A2, .A3, .A4, .A5,
             .Ar, .Ar1, .Ar2, .Ar3, .Ar4, .Ar5,
             .Ab, .Ab1, .Ab2, .Ab3, .Ab4, .Ab5,
             .B, .C, .D, .DD,
             .E, .E1, .E2, .E3, .E4, .E5,
             .Er, .Er1, .Er2, .Er3, .Er4, .Er5,
             .F, .G, .H,
             .I, .I1, .I2, .I3, .I4, .I5,
             .J, .K, .L, .M, .N,
             .O, .O1, .O2, .O3, .O4, .O5,
             .Or, .Or1, .Or2, .Or3, .Or4, .Or5,
             .Oh, .Oh1, .Oh2, .Oh3, .Oh4, .Oh5,
             .P, .Q, .R, .S, .T,
             .U, .U1, .U2, .U3, .U4, .U5,
             .Uh, .Uh1, .Uh2, .Uh3, .Uh4, .Uh5,
             .V, .W, .X,
             .Y, .Y1, .Y2, .Y3, .Y4, .Y5,
             .Z:
            return true
        default:
            return false
        }
    }
    
    /// Apply a tone (0-5) to this character
    public func withTone(_ tone: Int) -> VnLexiName {
        guard tone >= 0 && tone <= 5, self.isVowel else { return self }
        let base = self.baseChar
        guard let toned = VnLexiName(rawValue: base.rawValue + tone * 2) else { return self }
        return toned
    }
}

// MARK: - Character Mapping

/// Map ASCII character to VnLexiName
public func asciiToVnLexi(_ char: Character) -> VnLexiName {
    guard let ascii = char.asciiValue else { return .nonVnChar }
    
    if ascii >= 65 && ascii <= 90 { // A-Z
        return VnLexiName.azLexiUpper[Int(ascii - 65)]
    } else if ascii >= 97 && ascii <= 122 { // a-z
        return VnLexiName.azLexiLower[Int(ascii - 97)]
    }
    return .nonVnChar
}

extension VnLexiName {
    /// A-Z mapping to VnLexiName
    static let azLexiUpper: [VnLexiName] = [
        .A, .B, .C, .D, .E, .F, .G, .H, .I, .J,
        .K, .L, .M, .N, .O, .P, .Q, .R, .S, .T,
        .U, .V, .W, .X, .Y, .Z
    ]
    
    /// a-z mapping to VnLexiName
    static let azLexiLower: [VnLexiName] = [
        .a, .b, .c, .d, .e, .f, .g, .h, .i, .j,
        .k, .l, .m, .n, .o, .p, .q, .r, .s, .t,
        .u, .v, .w, .x, .y, .z
    ]
}
