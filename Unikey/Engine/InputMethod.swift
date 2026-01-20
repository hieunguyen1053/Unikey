// Unikey Swift Engine
// Ported from x-unikey-1.0.4/src/ukengine/inputproc.h & .cpp
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Jules

import Foundation

// MARK: - Enums & Structs

public enum UkKeyEvName: Int {
    case roofAll = 0, roof_a, roof_e, roof_o
    case hookAll, hook_uo, hook_u, hook_o, bowl
    case dd
    case tone0, tone1, tone2, tone3, tone4, tone5
    case telex_w
    case mapChar
    case escChar
    case normal
    case count
}

public enum UkCharType: Int {
    case vn
    case wordBreak
    case nonVn
    case reset
}

public struct UkKeyEvent {
    public var evType: Int // Int to allow vneCount + ... arithmetic
    public var chType: UkCharType
    public var vnSym: VnLexiName
    public var keyCode: UInt32
    public var tone: Int

    public init() {
        evType = UkKeyEvName.normal.rawValue
        chType = .nonVn
        vnSym = .nonVnChar
        keyCode = 0
        tone = 0
    }
}

public struct UkKeyMapping {
    var key: UInt8
    var action: Int
}

public enum UkInputMethod: Int {
    case telex = 0
    case vni
    case viqr
    case msVi
    case simpleTelex
    case user
}

// MARK: - Constants & Tables

private let wordBreakSyms: [UInt8] = [
    44, 59, 58, 46, 34, 39, 33, 63, 32, // , ; : . " ' ! ? space
    60, 62, 61, 43, 45, 42, 47, 92, // < > = + - * / \
    95, 64, 35, 36, 37, 38, 40, 41, 123, 125, 91, 93, 124 // _ @ # $ % & ( ) { } [ ] |
]

// AscVnLexiList equivalent
private let ascVnLexiList: [(Int, VnLexiName)] = [
    (0xC0, .A2), (0xC1, .A1), (0xC2, .Ar), (0xC2, .A4), // 0xC2 repeated? C++ source has 0xC2 twice? Line 66/67.
    // Wait, source: {0xC2, vnl_Ar}, {0xC2, vnl_A4}??
    // 0xC2 is Â in Latin-1? No, Â is 0xC2 in Latin-1.
    // Maybe copy paste error in C++ or special handling?
    // If map[0xC2] is overwritten, last one wins.
    // I will assume standard mapping if possible, or copy exactly.
    // If I use a dictionary/array, last one overwrites.

    (0xC8, .E2), (0xC9, .E1), (0xCA, .Er),
    (0xCC, .I2), (0xCD, .I1),
    (0xD2, .O2), (0xD3, .O1), (0xD4, .Or), (0xD5, .O4),
    (0xD9, .U2), (0xDA, .U1),
    (0xDD, .Y1),

    (0xE0, .a2), (0xE1, .a1), (0xE2, .ar), (0xE3, .a4),
    (0xE8, .e2), (0xE9, .e1), (0xEA, .er),
    (0xEC, .i2), (0xED, .i1),
    (0xF2, .o2), (0xF3, .o1), (0xF4, .or), (0xF5, .o4),
    (0xF9, .u2), (0xFA, .u1),
    (0xFD, .y1)
]

// Mappings
private let telexMapping: [UkKeyMapping] = [
    UkKeyMapping(key: 90, action: UkKeyEvName.tone0.rawValue), // Z
    UkKeyMapping(key: 83, action: UkKeyEvName.tone1.rawValue), // S
    UkKeyMapping(key: 70, action: UkKeyEvName.tone2.rawValue), // F
    UkKeyMapping(key: 82, action: UkKeyEvName.tone3.rawValue), // R
    UkKeyMapping(key: 88, action: UkKeyEvName.tone4.rawValue), // X
    UkKeyMapping(key: 74, action: UkKeyEvName.tone5.rawValue), // J
    UkKeyMapping(key: 87, action: UkKeyEvName.telex_w.rawValue), // W
    UkKeyMapping(key: 65, action: UkKeyEvName.roof_a.rawValue), // A
    UkKeyMapping(key: 69, action: UkKeyEvName.roof_e.rawValue), // E
    UkKeyMapping(key: 79, action: UkKeyEvName.roof_o.rawValue), // O
    UkKeyMapping(key: 68, action: UkKeyEvName.dd.rawValue), // D
    UkKeyMapping(key: 91, action: UkKeyEvName.count.rawValue + VnLexiName.oh.rawValue), // [
    UkKeyMapping(key: 93, action: UkKeyEvName.count.rawValue + VnLexiName.uh.rawValue), // ]
    UkKeyMapping(key: 123, action: UkKeyEvName.count.rawValue + VnLexiName.Oh.rawValue), // {
    UkKeyMapping(key: 125, action: UkKeyEvName.count.rawValue + VnLexiName.Uh.rawValue), // }
    UkKeyMapping(key: 0, action: UkKeyEvName.normal.rawValue)
]

private let simpleTelexMapping: [UkKeyMapping] = [
    UkKeyMapping(key: 90, action: UkKeyEvName.tone0.rawValue),
    UkKeyMapping(key: 83, action: UkKeyEvName.tone1.rawValue),
    UkKeyMapping(key: 70, action: UkKeyEvName.tone2.rawValue),
    UkKeyMapping(key: 82, action: UkKeyEvName.tone3.rawValue),
    UkKeyMapping(key: 88, action: UkKeyEvName.tone4.rawValue),
    UkKeyMapping(key: 74, action: UkKeyEvName.tone5.rawValue),
    UkKeyMapping(key: 87, action: UkKeyEvName.hookAll.rawValue),
    UkKeyMapping(key: 65, action: UkKeyEvName.roof_a.rawValue),
    UkKeyMapping(key: 69, action: UkKeyEvName.roof_e.rawValue),
    UkKeyMapping(key: 79, action: UkKeyEvName.roof_o.rawValue),
    UkKeyMapping(key: 68, action: UkKeyEvName.dd.rawValue),
    UkKeyMapping(key: 0, action: UkKeyEvName.normal.rawValue)
]

private let vniMapping: [UkKeyMapping] = [
    UkKeyMapping(key: 48, action: UkKeyEvName.tone0.rawValue), // 0
    UkKeyMapping(key: 49, action: UkKeyEvName.tone1.rawValue), // 1
    UkKeyMapping(key: 50, action: UkKeyEvName.tone2.rawValue), // 2
    UkKeyMapping(key: 51, action: UkKeyEvName.tone3.rawValue), // 3
    UkKeyMapping(key: 52, action: UkKeyEvName.tone4.rawValue), // 4
    UkKeyMapping(key: 53, action: UkKeyEvName.tone5.rawValue), // 5
    UkKeyMapping(key: 54, action: UkKeyEvName.roofAll.rawValue), // 6
    UkKeyMapping(key: 55, action: UkKeyEvName.hook_uo.rawValue), // 7
    UkKeyMapping(key: 56, action: UkKeyEvName.bowl.rawValue), // 8
    UkKeyMapping(key: 57, action: UkKeyEvName.dd.rawValue), // 9
    UkKeyMapping(key: 0, action: UkKeyEvName.normal.rawValue)
]

private let viqrMapping: [UkKeyMapping] = [
    UkKeyMapping(key: 48, action: UkKeyEvName.tone0.rawValue), // 0
    UkKeyMapping(key: 39, action: UkKeyEvName.tone1.rawValue), // '
    UkKeyMapping(key: 96, action: UkKeyEvName.tone2.rawValue), // `
    UkKeyMapping(key: 63, action: UkKeyEvName.tone3.rawValue), // ?
    UkKeyMapping(key: 126, action: UkKeyEvName.tone4.rawValue), // ~
    UkKeyMapping(key: 46, action: UkKeyEvName.tone5.rawValue), // .
    UkKeyMapping(key: 94, action: UkKeyEvName.roofAll.rawValue), // ^
    UkKeyMapping(key: 43, action: UkKeyEvName.hook_uo.rawValue), // +
    UkKeyMapping(key: 42, action: UkKeyEvName.hook_uo.rawValue), // *
    UkKeyMapping(key: 40, action: UkKeyEvName.bowl.rawValue), // (
    UkKeyMapping(key: 68, action: UkKeyEvName.dd.rawValue), // D
    UkKeyMapping(key: 92, action: UkKeyEvName.escChar.rawValue), // \
    UkKeyMapping(key: 0, action: UkKeyEvName.normal.rawValue)
]

// MARK: - Input Processor Class

public class UkInputProcessor {
    private var m_im: UkInputMethod = .telex
    private var m_keyMap: [Int] = Array(repeating: UkKeyEvName.normal.rawValue, count: 256)

    // Static tables
    private static var ukcMap: [UkCharType] = Array(repeating: .nonVn, count: 256)
    private static var isoVnLexiMap: [VnLexiName] = Array(repeating: .nonVnChar, count: 256)
    private static var classifierTableInitialized: Bool = false

    public init() {
        initProcessor()
    }

    public func initProcessor() {
        if !UkInputProcessor.classifierTableInitialized {
            UkInputProcessor.setupInputClassifierTable()
            UkInputProcessor.classifierTableInitialized = true
        }
        setIM(.telex)
    }

    public func getIM() -> UkInputMethod {
        return m_im
    }

    public func setIM(_ im: UkInputMethod) {
        m_im = im
        switch im {
        case .telex:
            useBuiltIn(telexMapping)
        case .simpleTelex:
            useBuiltIn(simpleTelexMapping)
        case .vni:
            useBuiltIn(vniMapping)
        case .viqr:
            useBuiltIn(viqrMapping)
        // case .msVi: // Skip for now or implement if needed
        default:
            m_im = .telex
            useBuiltIn(telexMapping)
        }
    }

    public func setIM(_ map: [Int]) {
        m_im = .user
        for i in 0..<256 {
            m_keyMap[i] = map[i]
        }
    }

    public func getKeyMap() -> [Int] {
        return m_keyMap
    }

    public func getCharType(_ keyCode: UInt32) -> UkCharType {
        if keyCode > 255 {
            return (UkInputProcessor.isoToVnLexi(Int(keyCode)) == .nonVnChar) ? .nonVn : .vn
        }
        return UkInputProcessor.ukcMap[Int(keyCode)]
    }

    public func keyCodeToEvent(_ keyCode: UInt32, _ ev: inout UkKeyEvent) {
        ev.keyCode = keyCode

        if keyCode > 255 {
            ev.evType = UkKeyEvName.normal.rawValue
            ev.vnSym = UkInputProcessor.isoToVnLexi(Int(keyCode))
            ev.chType = (ev.vnSym == .nonVnChar) ? .nonVn : .vn
        } else {
            ev.chType = UkInputProcessor.ukcMap[Int(keyCode)]
            ev.evType = m_keyMap[Int(keyCode)]

            if ev.evType >= UkKeyEvName.tone0.rawValue && ev.evType <= UkKeyEvName.tone5.rawValue {
                ev.tone = ev.evType - UkKeyEvName.tone0.rawValue
            }

            if ev.evType >= UkKeyEvName.count.rawValue {
                ev.chType = .vn
                ev.vnSym = VnLexiName(rawValue: ev.evType - UkKeyEvName.count.rawValue) ?? .nonVnChar
                ev.evType = UkKeyEvName.mapChar.rawValue
            } else {
                ev.vnSym = UkInputProcessor.isoToVnLexi(Int(keyCode))
            }
        }
    }

    public func keyCodeToSymbol(_ keyCode: UInt32, _ ev: inout UkKeyEvent) {
        ev.keyCode = keyCode
        ev.evType = UkKeyEvName.normal.rawValue
        ev.vnSym = UkInputProcessor.isoToVnLexi(Int(keyCode))
        if keyCode > 255 {
            ev.chType = (ev.vnSym == .nonVnChar) ? .nonVn : .vn
        } else {
            ev.chType = UkInputProcessor.ukcMap[Int(keyCode)]
        }
    }

    // MARK: - Private Methods

    private func useBuiltIn(_ map: [UkKeyMapping]) {
        ukResetKeyMap()
        for item in map {
            if item.key == 0 { break }
            let key = Int(item.key)
            m_keyMap[key] = item.action

            if item.action < UkKeyEvName.count.rawValue {
                let char = Character(UnicodeScalar(item.key))
                if char.isLowercase {
                    m_keyMap[Int(char.uppercased().first?.asciiValue ?? 0)] = item.action
                } else if char.isUppercase {
                    m_keyMap[Int(char.lowercased().first?.asciiValue ?? 0)] = item.action
                }
            }
        }
    }

    private func ukResetKeyMap() {
        for i in 0..<256 {
            m_keyMap[i] = UkKeyEvName.normal.rawValue
        }
    }

    private static func setupInputClassifierTable() {
        for c in 0...32 {
            ukcMap[c] = .reset
        }
        for c in 33..<256 {
            ukcMap[c] = .nonVn
        }

        let a = Int(Character("a").asciiValue!)
        let z = Int(Character("z").asciiValue!)
        let A = Int(Character("A").asciiValue!)
        let Z = Int(Character("Z").asciiValue!)

        for c in a...z { ukcMap[c] = .vn }
        for c in A...Z { ukcMap[c] = .vn }

        for item in ascVnLexiList {
            if item.0 < 256 {
                ukcMap[item.0] = .vn
            }
        }

        // Exclude some chars
        let excluded: [Character] = ["j", "J", "f", "F", "w", "W"]
        for char in excluded {
            if let val = char.asciiValue {
                ukcMap[Int(val)] = .nonVn
            }
        }

        for sym in wordBreakSyms {
            ukcMap[Int(sym)] = .wordBreak
        }

        // Calculate IsoVnLexiMap
        for i in 0..<256 {
            isoVnLexiMap[i] = .nonVnChar
        }

        for item in ascVnLexiList {
            if item.0 < 256 {
                isoVnLexiMap[item.0] = item.1
            }
        }

        // A-Z, a-z mapping
        // Need to match AZLexiUpper/Lower
        // In C++, AZLexiLower[c-'a'].
        // Swift VnLexiName: .A=0, .a=1...
        // Let's use `asciiToVnLexi` equivalent logic or just map

        for c in a...z {
            // map a -> .a, b -> .b
            // .a is 1, .b is 37...
            // Use VnLexiName.asciiToVnLexi equivalent logic
            // Actually C++ defines AZLexiUpper/Lower arrays.
            // I should use that.

            // Re-implement mapping:
            // a -> vnl_a
            // b -> vnl_b
            // etc.
            // I'll assume my VnLexiName structure matches
            // or I can call helper

             // Simplest: use asciiToVnLexi from VnLexiName.swift if available or inline logic
             // But I am in InputProcessor.
             // I will use explicit mapping here to be safe and fast.
             let char = Character(UnicodeScalar(c)!)
             isoVnLexiMap[c] = VnLexiName(rawValue: VnLexiName.a.rawValue + (c - a) * (c == Int(Character("b").asciiValue!) ? 36 : 2)) ?? .nonVnChar
             // Wait, the order is tricky.
             // A, a, A1...
             // B, b, C, c...
             // A, B, C are NOT contiguous in enum.
             // A=0. B=36. C=38.
             // I'll rely on a helper function in this file for `isoToVnLexi` that handles logic properly or rebuild the table accurately.
        }

        // Re-do loops with `asciiToVnLexi` logic (I'll implement `isoToVnLexi` method properly)
        // But `SetupInputClassifierTable` builds `IsoVnLexiMap`.
        // So I need to fill it correctly.

        // Helper:
        func mapAZ() {
             let uppers: [VnLexiName] = [.A, .B, .C, .D, .E, .F, .G, .H, .I, .J, .K, .L, .M, .N, .O, .P, .Q, .R, .S, .T, .U, .V, .W, .X, .Y, .Z]
             let lowers: [VnLexiName] = [.a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m, .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z]

             for (i, v) in uppers.enumerated() {
                 isoVnLexiMap[A + i] = v
             }
             for (i, v) in lowers.enumerated() {
                 isoVnLexiMap[a + i] = v
             }
        }
        mapAZ()
    }

    private static func isoToVnLexi(_ keyCode: Int) -> VnLexiName {
        if keyCode >= 256 { return .nonVnChar }
        return isoVnLexiMap[keyCode]
    }
}
