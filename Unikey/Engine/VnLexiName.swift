// Unikey Swift Engine
// Ported from x-unikey-1.0.4/src/ukengine/vnlexi.h
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Jules

import Foundation

public enum VnLexiName: Int, CaseIterable {
    case nonVnChar = -1

    case A = 0
    case a, A1, a1, A2, a2, A3, a3, A4, a4, A5, a5
    case Ar, ar, Ar1, ar1, Ar2, ar2, Ar3, ar3, Ar4, ar4, Ar5, ar5
    case Ab, ab, Ab1, ab1, Ab2, ab2, Ab3, ab3, Ab4, ab4, Ab5, ab5

    case B, b, C, c

    case D, d, DD, dd

    case E, e, E1, e1, E2, e2, E3, e3, E4, e4, E5, e5
    case Er, er, Er1, er1, Er2, er2, Er3, er3, Er4, er4, Er5, er5

    case F, f, G, g, H, h

    case I, i, I1, i1, I2, i2, I3, i3, I4, i4, I5, i5

    case J, j, K, k, L, l, M, m, N, n

    case O, o, O1, o1, O2, o2, O3, o3, O4, o4, O5, o5
    case Or, or, Or1, or1, Or2, or2, Or3, or3, Or4, or4, Or5, or5
    case Oh, oh, Oh1, oh1, Oh2, oh2, Oh3, oh3, Oh4, oh4, Oh5, oh5

    case P, p, Q, q, R, r, S, s, T, t

    case U, u, U1, u1, U2, u2, U3, u3, U4, u4, U5, u5
    case Uh, uh, Uh1, uh1, Uh2, uh2, Uh3, uh3, Uh4, uh4, Uh5, uh5

    case V, v, W, w, X, x

    case Y, y, Y1, y1, Y2, y2, Y3, y3, Y4, y4, Y5, y5

    case Z, z

    case lastChar
}

// MARK: - Helper Properties & Methods

extension VnLexiName {
    public var isVowel: Bool {
        let base = self.baseChar
        switch base {
        case .A, .Ar, .Ab, .E, .Er, .I, .O, .Or, .Oh, .U, .Uh, .Y:
            return true
        case .a, .ar, .ab, .e, .er, .i, .o, .or, .oh, .u, .uh, .y:
            return true
        default:
            return false
        }
    }

    public var isUpper: Bool {
        // Simple heuristic based on enum definition
        // Base chars A, Ar, Ab, B, C, D, DD, E, Er, F, G, H, I, J, K, L, M, N, O, Or, Oh, P, Q, R, S, T, U, Uh, V, W, X, Y, Z
        // are Upper.
        // Also their toned variants.
        // Logic: even rawValue is Upper (start of pair), odd is Lower?
        // Let's check: A=0 (Upper), a=1 (Lower). A1=2 (Upper), a1=3 (Lower).
        // Exceptions: B=36 (Upper), b=37 (Lower).
        // It seems consistent that Upper is even, Lower is odd for letters.
        // But check range.
        if self == .nonVnChar || self == .lastChar { return false }
        return (self.rawValue % 2) == 0
    }

    public var toLower: VnLexiName {
        if !isUpper { return self }
        return VnLexiName(rawValue: self.rawValue + 1) ?? self
    }

    public var toUpper: VnLexiName {
        if isUpper { return self }
        return VnLexiName(rawValue: self.rawValue - 1) ?? self
    }

    public var baseChar: VnLexiName {
        // Normalize to base char (remove tone)
        // Groups of 12 for vowels with tones
        // A=0...a5=11.
        // Ar=12...ar5=23.
        // etc.
        let val = self.rawValue

        // Ranges
        if val >= VnLexiName.A.rawValue && val <= VnLexiName.a5.rawValue {
            return isUpper ? .A : .a
        }
        if val >= VnLexiName.Ar.rawValue && val <= VnLexiName.ar5.rawValue {
            return isUpper ? .Ar : .ar
        }
        if val >= VnLexiName.Ab.rawValue && val <= VnLexiName.ab5.rawValue {
            return isUpper ? .Ab : .ab
        }
        // B..dd (not toned in this enum, except DD)
        // E..e5
        if val >= VnLexiName.E.rawValue && val <= VnLexiName.e5.rawValue {
            return isUpper ? .E : .e
        }
        if val >= VnLexiName.Er.rawValue && val <= VnLexiName.er5.rawValue {
            return isUpper ? .Er : .er
        }
        // I..i5
        if val >= VnLexiName.I.rawValue && val <= VnLexiName.i5.rawValue {
            return isUpper ? .I : .i
        }
        // O..o5
        if val >= VnLexiName.O.rawValue && val <= VnLexiName.o5.rawValue {
            return isUpper ? .O : .o
        }
        if val >= VnLexiName.Or.rawValue && val <= VnLexiName.or5.rawValue {
            return isUpper ? .Or : .or
        }
        if val >= VnLexiName.Oh.rawValue && val <= VnLexiName.oh5.rawValue {
            return isUpper ? .Oh : .oh
        }
        // U..u5
        if val >= VnLexiName.U.rawValue && val <= VnLexiName.u5.rawValue {
            return isUpper ? .U : .u
        }
        if val >= VnLexiName.Uh.rawValue && val <= VnLexiName.uh5.rawValue {
            return isUpper ? .Uh : .uh
        }
        // Y..y5
        if val >= VnLexiName.Y.rawValue && val <= VnLexiName.y5.rawValue {
            return isUpper ? .Y : .y
        }

        return self
    }

    public var tone: Int {
        // Return 0-5
        let base = self.baseChar
        // If not vowel, return 0 (except maybe implicit logic?)
        // Calculate offset
        let diff = self.rawValue - base.rawValue
        // A=0, A1=2, A2=4...
        // diff is 2 * tone
        if diff < 0 { return 0 }  // Should not happen
        return diff / 2
    }

    public func withTone(_ tone: Int) -> VnLexiName {
        if tone < 0 || tone > 5 { return self }
        let base = self.baseChar
        // Check if this char supports tone (is in one of the ranges)
        if !base.isVowel { return self }

        // Calculate new value
        let newVal = base.rawValue + (tone * 2)
        return VnLexiName(rawValue: newVal) ?? self
    }

    // Helpers for UkEngine logic

    public var withRoof: VnLexiName {
        let tone = self.tone
        let isUp = self.isUpper
        let root = self.baseChar

        // A -> Ar, E -> Er, O -> Or
        var targetRoot: VnLexiName?

        switch root {
        case .A, .a: targetRoot = isUp ? .Ar : .ar
        case .E, .e: targetRoot = isUp ? .Er : .er
        case .O, .o: targetRoot = isUp ? .Or : .or
        default: return self
        }

        if let target = targetRoot {
            return target.withTone(tone)
        }
        return self
    }

    public var withoutRoof: VnLexiName {
        let tone = self.tone
        let isUp = self.isUpper
        let root = self.baseChar

        // Ar -> A, Er -> E, Or -> O
        var targetRoot: VnLexiName?

        switch root {
        case .Ar, .ar: targetRoot = isUp ? .A : .a
        case .Er, .er: targetRoot = isUp ? .E : .e
        case .Or, .or: targetRoot = isUp ? .O : .o
        default: return self
        }

        if let target = targetRoot {
            return target.withTone(tone)
        }
        return self
    }

    public var withHook: VnLexiName {
        let tone = self.tone
        let isUp = self.isUpper
        let root = self.baseChar

        // U -> Uh, O -> Oh
        // Note: A -> Ab (Breve is conceptually similar to hook in unikey internal logic sometimes, but Ab is bowl)
        // In UkEngine.cpp processHook:
        // if (vInfo.withHook != vs_nil) ...
        // This relies on VowelSequence info, not VnLexiName direct mapping usually.
        // But for single chars?

        var targetRoot: VnLexiName?
        switch root {
        case .U, .u: targetRoot = isUp ? .Uh : .uh
        case .O, .o: targetRoot = isUp ? .Oh : .oh
        default: return self
        }

        if let target = targetRoot {
            return target.withTone(tone)
        }
        return self
    }

    public var withoutHook: VnLexiName {
        let tone = self.tone
        let isUp = self.isUpper
        let root = self.baseChar

        var targetRoot: VnLexiName?
        switch root {
        case .Uh, .uh: targetRoot = isUp ? .U : .u
        case .Oh, .oh: targetRoot = isUp ? .O : .o
        default: return self
        }

        if let target = targetRoot {
            return target.withTone(tone)
        }
        return self
    }

    public var withBreve: VnLexiName {
        let tone = self.tone
        let isUp = self.isUpper
        let root = self.baseChar

        // A -> Ab
        if root == .A || root == .a {
            let targetRoot: VnLexiName = isUp ? .Ab : .ab
            return targetRoot.withTone(tone)
        }
        return self
    }

    public var withoutBreve: VnLexiName {
        let tone = self.tone
        let isUp = self.isUpper
        let root = self.baseChar

        // Ab -> A
        if root == .Ab || root == .ab {
            let targetRoot: VnLexiName = isUp ? .A : .a
            return targetRoot.withTone(tone)
        }
        return self
    }
}
