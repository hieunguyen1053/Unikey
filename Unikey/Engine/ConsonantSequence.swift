// Unikey Swift Engine
// Ported from x-unikey-1.0.4/src/ukengine/vnlexi.h
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Jules

import Foundation

public enum ConsonantSequence: Int, CaseIterable {
    case none = -1

    case b, c, ch
    case d, dd, dz
    case g, gh, gi, gin
    case h
    case k, kh
    case l
    case m
    case n, ng, ngh, nh
    case p, ph
    case q, qu
    case r
    case s
    case t, th, tr
    case v
    case x
}

public struct ConsonantSeqInfo {
    public var length: Int
    public var consonants: [VnLexiName]
    public var suffix: Bool  // Can be a suffix

    public init(length: Int, consonants: [VnLexiName], suffix: Bool = false) {
        self.length = length
        self.consonants = consonants
        self.suffix = suffix
    }
}

// Lookup table (simulated)
private let consonantSeqTable: [ConsonantSequence: ConsonantSeqInfo] = [
    .b: ConsonantSeqInfo(length: 1, consonants: [.b], suffix: false),
    .c: ConsonantSeqInfo(length: 1, consonants: [.c], suffix: true),
    .ch: ConsonantSeqInfo(length: 2, consonants: [.c, .h], suffix: true),
    .d: ConsonantSeqInfo(length: 1, consonants: [.d], suffix: false),
    .dd: ConsonantSeqInfo(length: 1, consonants: [.dd], suffix: false),
    .dz: ConsonantSeqInfo(length: 2, consonants: [.d, .z], suffix: false),
    .g: ConsonantSeqInfo(length: 1, consonants: [.g], suffix: false),
    .gh: ConsonantSeqInfo(length: 2, consonants: [.g, .h], suffix: false),
    .gi: ConsonantSeqInfo(length: 2, consonants: [.g, .i], suffix: false),
    .gin: ConsonantSeqInfo(length: 3, consonants: [.g, .i, .n], suffix: false),
    .h: ConsonantSeqInfo(length: 1, consonants: [.h], suffix: false),
    .k: ConsonantSeqInfo(length: 1, consonants: [.k], suffix: false),
    .kh: ConsonantSeqInfo(length: 2, consonants: [.k, .h], suffix: false),
    .l: ConsonantSeqInfo(length: 1, consonants: [.l], suffix: false),
    .m: ConsonantSeqInfo(length: 1, consonants: [.m], suffix: true),
    .n: ConsonantSeqInfo(length: 1, consonants: [.n], suffix: true),
    .ng: ConsonantSeqInfo(length: 2, consonants: [.n, .g], suffix: true),
    .ngh: ConsonantSeqInfo(length: 3, consonants: [.n, .g, .h], suffix: false),
    .nh: ConsonantSeqInfo(length: 2, consonants: [.n, .h], suffix: true),
    .p: ConsonantSeqInfo(length: 1, consonants: [.p], suffix: true),
    .ph: ConsonantSeqInfo(length: 2, consonants: [.p, .h], suffix: false),
    .q: ConsonantSeqInfo(length: 1, consonants: [.q], suffix: false),
    .qu: ConsonantSeqInfo(length: 2, consonants: [.q, .u], suffix: false),
    .r: ConsonantSeqInfo(length: 1, consonants: [.r], suffix: false),
    .s: ConsonantSeqInfo(length: 1, consonants: [.s], suffix: false),
    .t: ConsonantSeqInfo(length: 1, consonants: [.t], suffix: true),
    .th: ConsonantSeqInfo(length: 2, consonants: [.t, .h], suffix: false),
    .tr: ConsonantSeqInfo(length: 2, consonants: [.t, .r], suffix: false),
    .v: ConsonantSeqInfo(length: 1, consonants: [.v], suffix: false),
    .x: ConsonantSeqInfo(length: 1, consonants: [.x], suffix: false),
]

// Note: `consonantSeqList` in UkEngine.swift was used as array.
// We should provide `consonantSeqList` as array indexable by enum rawValue if rawValue starts at 0.
// Our enum starts at -1 (none) then 0, 1...
// But Swift enums are safe.
// We can expose a function or dictionary.

public var consonantSeqList: [ConsonantSeqInfo] {
    // Return array where index matches enum rawValue
    // ConsonantSequence raw values are auto-incrementing from 0 (if none=-1 is manual).
    // Wait, `case none = -1`, `case b` -> 0? No, `b` will be 0.
    // Let's verify.
    // Yes, Swift auto-increments from previous case.

    var list = [ConsonantSeqInfo]()
    // Iterate 0...max
    // Or just map table.
    // The previous code indexed into this list using `prev.cseq.rawValue`.
    // So we need an array.

    // Find max raw value
    let maxRaw = ConsonantSequence.allCases.map { $0.rawValue }.max() ?? 0
    // Fill array
    for i in 0...maxRaw {
        if let seq = ConsonantSequence(rawValue: i),
            let info = consonantSeqTable[seq]
        {
            list.append(info)
        } else {
            // Should not happen if sparse
            list.append(ConsonantSeqInfo(length: 0, consonants: []))
        }
    }
    return list
}

public func getConsonantSeqInfo(_ seq: ConsonantSequence) -> ConsonantSeqInfo? {
    return consonantSeqTable[seq]
}

public func lookupConsonantSeq(
    _ c1: VnLexiName,
    _ c2: VnLexiName = .nonVnChar,
    _ c3: VnLexiName = .nonVnChar
) -> ConsonantSequence {
    let b1 = c1.baseChar
    let b2 = c2.baseChar
    let b3 = c3.baseChar

    if b1 == .nonVnChar { return .none }

    if b2 == .nonVnChar {
        // Single
        for (seq, info) in consonantSeqTable where info.length == 1 {
            if info.consonants[0] == b1 { return seq }
        }
    } else if b3 == .nonVnChar {
        // Double
        for (seq, info) in consonantSeqTable where info.length == 2 {
            if info.consonants[0] == b1 && info.consonants[1] == b2 {
                return seq
            }
        }
    } else {
        // Triple
        for (seq, info) in consonantSeqTable where info.length == 3 {
            if info.consonants[0] == b1 && info.consonants[1] == b2
                && info.consonants[2] == b3
            {
                return seq
            }
        }
    }
    return .none
}
