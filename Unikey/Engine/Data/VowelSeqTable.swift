// Unikey Swift Engine - Vowel Sequence Lookup Table
// Ported from x-unikey-1.0.4/src/ukengine/ukengine.cpp VSeqList (lines 77-148)
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Gemini

import Foundation

/// Full vowel sequence information table (73 entries)
/// Ported exactly from ukengine.cpp VSeqList
public let vowelSeqList: [VowelSeqInfo] = [
    // vs_a (0)
    VowelSeqInfo(length: 1, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.a], subsequences: [.a],
                 roofPosition: -1, withRoof: .ar, hookPosition: -1, withHook: .ab),
    // vs_ar (1) - â
    VowelSeqInfo(length: 1, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.ar], subsequences: [.ar],
                 roofPosition: 0, withRoof: .none, hookPosition: -1, withHook: .ab),
    // vs_ab (2) - ă
    VowelSeqInfo(length: 1, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.ab], subsequences: [.ab],
                 roofPosition: -1, withRoof: .ar, hookPosition: 0, withHook: .none),
    // vs_e (3)
    VowelSeqInfo(length: 1, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.e], subsequences: [.e],
                 roofPosition: -1, withRoof: .er, hookPosition: -1, withHook: .none),
    // vs_er (4) - ê
    VowelSeqInfo(length: 1, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.er], subsequences: [.er],
                 roofPosition: 0, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_i (5)
    VowelSeqInfo(length: 1, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.i], subsequences: [.i],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_o (6)
    VowelSeqInfo(length: 1, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.o], subsequences: [.o],
                 roofPosition: -1, withRoof: .or, hookPosition: -1, withHook: .oh),
    // vs_or (7) - ô
    VowelSeqInfo(length: 1, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.or], subsequences: [.or],
                 roofPosition: 0, withRoof: .none, hookPosition: -1, withHook: .oh),
    // vs_oh (8) - ơ
    VowelSeqInfo(length: 1, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.oh], subsequences: [.oh],
                 roofPosition: -1, withRoof: .or, hookPosition: 0, withHook: .none),
    // vs_u (9)
    VowelSeqInfo(length: 1, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.u], subsequences: [.u],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .uh),
    // vs_uh (10) - ư
    VowelSeqInfo(length: 1, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.uh], subsequences: [.uh],
                 roofPosition: -1, withRoof: .none, hookPosition: 0, withHook: .none),
    // vs_y (11)
    VowelSeqInfo(length: 1, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.y], subsequences: [.y],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    
    // Double vowels (12-47)
    // vs_ai (12)
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.a, .i], subsequences: [.a, .ai],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_ao (13)
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.a, .o], subsequences: [.a, .ao],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_au (14)
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.a, .u], subsequences: [.a, .au],
                 roofPosition: -1, withRoof: .aru, hookPosition: -1, withHook: .none),
    // vs_ay (15)
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.a, .y], subsequences: [.a, .ay],
                 roofPosition: -1, withRoof: .ary, hookPosition: -1, withHook: .none),
    // vs_aru (16) - âu
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.ar, .u], subsequences: [.ar, .aru],
                 roofPosition: 0, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_ary (17) - ây
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.ar, .y], subsequences: [.ar, .ary],
                 roofPosition: 0, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_eo (18)
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.e, .o], subsequences: [.e, .eo],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_eu (19)
    VowelSeqInfo(length: 2, isComplete: false, allowsConsonantSuffix: false,
                 vowels: [.e, .u], subsequences: [.e, .eu],
                 roofPosition: -1, withRoof: .eru, hookPosition: -1, withHook: .none),
    // vs_eru (20) - êu
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.er, .u], subsequences: [.er, .eru],
                 roofPosition: 0, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_ia (21) - ia
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.i, .a], subsequences: [.i, .ia],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_ie (22)
    VowelSeqInfo(length: 2, isComplete: false, allowsConsonantSuffix: true,
                 vowels: [.i, .e], subsequences: [.i, .ie],
                 roofPosition: -1, withRoof: .ier, hookPosition: -1, withHook: .none),
    // vs_ier (23) - iê
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.i, .er], subsequences: [.i, .ier],
                 roofPosition: 1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_iu (24)
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.i, .u], subsequences: [.i, .iu],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_oa (25)
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.o, .a], subsequences: [.o, .oa],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .oab),
    // vs_oab (26) - oă
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.o, .ab], subsequences: [.o, .oab],
                 roofPosition: -1, withRoof: .none, hookPosition: 1, withHook: .none),
    // vs_oe (27)
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.o, .e], subsequences: [.o, .oe],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_oi (28)
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.o, .i], subsequences: [.o, .oi],
                 roofPosition: -1, withRoof: .ori, hookPosition: -1, withHook: .ohi),
    // vs_ori (29) - ôi
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.or, .i], subsequences: [.or, .ori],
                 roofPosition: 0, withRoof: .none, hookPosition: -1, withHook: .ohi),
    // vs_ohi (30) - ơi
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.oh, .i], subsequences: [.oh, .ohi],
                 roofPosition: -1, withRoof: .ori, hookPosition: 0, withHook: .none),
    // vs_ua (31)
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.u, .a], subsequences: [.u, .ua],
                 roofPosition: -1, withRoof: .uar, hookPosition: -1, withHook: .uha),
    // vs_uar (32) - uâ
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.u, .ar], subsequences: [.u, .uar],
                 roofPosition: 1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_ue (33)
    VowelSeqInfo(length: 2, isComplete: false, allowsConsonantSuffix: true,
                 vowels: [.u, .e], subsequences: [.u, .ue],
                 roofPosition: -1, withRoof: .uer, hookPosition: -1, withHook: .none),
    // vs_uer (34) - uê
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.u, .er], subsequences: [.u, .uer],
                 roofPosition: 1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_ui (35)
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.u, .i], subsequences: [.u, .ui],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .uhi),
    // vs_uo (36)
    VowelSeqInfo(length: 2, isComplete: false, allowsConsonantSuffix: true,
                 vowels: [.u, .o], subsequences: [.u, .uo],
                 roofPosition: -1, withRoof: .uor, hookPosition: -1, withHook: .uho),
    // vs_uor (37) - uô
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.u, .or], subsequences: [.u, .uor],
                 roofPosition: 1, withRoof: .none, hookPosition: -1, withHook: .uoh),
    // vs_uoh (38) - uơ
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.u, .oh], subsequences: [.u, .uoh],
                 roofPosition: -1, withRoof: .uor, hookPosition: 1, withHook: .uhoh),
    // vs_uu (39)
    VowelSeqInfo(length: 2, isComplete: false, allowsConsonantSuffix: false,
                 vowels: [.u, .u], subsequences: [.u, .uu],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .uhu),
    // vs_uy (40)
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.u, .y], subsequences: [.u, .uy],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_uha (41) - ưa
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.uh, .a], subsequences: [.uh, .uha],
                 roofPosition: -1, withRoof: .none, hookPosition: 0, withHook: .none),
    // vs_uhi (42) - ưi
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.uh, .i], subsequences: [.uh, .uhi],
                 roofPosition: -1, withRoof: .none, hookPosition: 0, withHook: .none),
    // vs_uho (43) - ưo
    VowelSeqInfo(length: 2, isComplete: false, allowsConsonantSuffix: true,
                 vowels: [.uh, .o], subsequences: [.uh, .uho],
                 roofPosition: -1, withRoof: .none, hookPosition: 0, withHook: .uhoh),
    // vs_uhoh (44) - ươ
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.uh, .oh], subsequences: [.uh, .uhoh],
                 roofPosition: -1, withRoof: .none, hookPosition: 0, withHook: .none),
    // vs_uhu (45) - ưu
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.uh, .u], subsequences: [.uh, .uhu],
                 roofPosition: -1, withRoof: .none, hookPosition: 0, withHook: .none),
    // vs_ye (46)
    VowelSeqInfo(length: 2, isComplete: false, allowsConsonantSuffix: true,
                 vowels: [.y, .e], subsequences: [.y, .ye],
                 roofPosition: -1, withRoof: .yer, hookPosition: -1, withHook: .none),
    // vs_yer (47) - yê
    VowelSeqInfo(length: 2, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.y, .er], subsequences: [.y, .yer],
                 roofPosition: 1, withRoof: .none, hookPosition: -1, withHook: .none),
    
    // Triple vowels (48-70)
    // vs_ieu (48)
    VowelSeqInfo(length: 3, isComplete: false, allowsConsonantSuffix: false,
                 vowels: [.i, .e, .u], subsequences: [.i, .ie, .ieu],
                 roofPosition: -1, withRoof: .ieru, hookPosition: -1, withHook: .none),
    // vs_ieru (49) - iêu
    VowelSeqInfo(length: 3, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.i, .er, .u], subsequences: [.i, .ier, .ieru],
                 roofPosition: 1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_oai (50)
    VowelSeqInfo(length: 3, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.o, .a, .i], subsequences: [.o, .oa, .oai],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_oay (51)
    VowelSeqInfo(length: 3, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.o, .a, .y], subsequences: [.o, .oa, .oay],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_oeo (52)
    VowelSeqInfo(length: 3, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.o, .e, .o], subsequences: [.o, .oe, .oeo],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_uay (53)
    VowelSeqInfo(length: 3, isComplete: false, allowsConsonantSuffix: false,
                 vowels: [.u, .a, .y], subsequences: [.u, .ua, .uay],
                 roofPosition: -1, withRoof: .uary, hookPosition: -1, withHook: .none),
    // vs_uary (54) - uây
    VowelSeqInfo(length: 3, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.u, .ar, .y], subsequences: [.u, .uar, .uary],
                 roofPosition: 1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_uoi (55)
    VowelSeqInfo(length: 3, isComplete: false, allowsConsonantSuffix: false,
                 vowels: [.u, .o, .i], subsequences: [.u, .uo, .uoi],
                 roofPosition: -1, withRoof: .uori, hookPosition: -1, withHook: .uhoi),
    // vs_uou (56)
    VowelSeqInfo(length: 3, isComplete: false, allowsConsonantSuffix: false,
                 vowels: [.u, .o, .u], subsequences: [.u, .uo, .uou],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .uhou),
    // vs_uori (57) - uôi
    VowelSeqInfo(length: 3, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.u, .or, .i], subsequences: [.u, .uor, .uori],
                 roofPosition: 1, withRoof: .none, hookPosition: -1, withHook: .uohi),
    // vs_uohi (58) - uơi
    VowelSeqInfo(length: 3, isComplete: false, allowsConsonantSuffix: false,
                 vowels: [.u, .oh, .i], subsequences: [.u, .uoh, .uohi],
                 roofPosition: -1, withRoof: .uori, hookPosition: 1, withHook: .uhohi),
    // vs_uohu (59) - uơu
    VowelSeqInfo(length: 3, isComplete: false, allowsConsonantSuffix: false,
                 vowels: [.u, .oh, .u], subsequences: [.u, .uoh, .uohu],
                 roofPosition: -1, withRoof: .none, hookPosition: 1, withHook: .uhohu),
    // vs_uya (60)
    VowelSeqInfo(length: 3, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.u, .y, .a], subsequences: [.u, .uy, .uya],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_uye (61)
    VowelSeqInfo(length: 3, isComplete: false, allowsConsonantSuffix: true,
                 vowels: [.u, .y, .e], subsequences: [.u, .uy, .uye],
                 roofPosition: -1, withRoof: .uyer, hookPosition: -1, withHook: .none),
    // vs_uyer (62) - uyê
    VowelSeqInfo(length: 3, isComplete: true, allowsConsonantSuffix: true,
                 vowels: [.u, .y, .er], subsequences: [.u, .uy, .uyer],
                 roofPosition: 2, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_uyu (63)
    VowelSeqInfo(length: 3, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.u, .y, .u], subsequences: [.u, .uy, .uyu],
                 roofPosition: -1, withRoof: .none, hookPosition: -1, withHook: .none),
    // vs_uhoi (64) - ươi
    VowelSeqInfo(length: 3, isComplete: false, allowsConsonantSuffix: false,
                 vowels: [.uh, .o, .i], subsequences: [.uh, .uho, .uhoi],
                 roofPosition: -1, withRoof: .none, hookPosition: 0, withHook: .uhohi),
    // vs_uhou (65) - ươu
    VowelSeqInfo(length: 3, isComplete: false, allowsConsonantSuffix: false,
                 vowels: [.uh, .o, .u], subsequences: [.uh, .uho, .uhou],
                 roofPosition: -1, withRoof: .none, hookPosition: 0, withHook: .uhohu),
    // vs_uhohi (66) - ươi (full)
    VowelSeqInfo(length: 3, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.uh, .oh, .i], subsequences: [.uh, .uhoh, .uhohi],
                 roofPosition: -1, withRoof: .none, hookPosition: 0, withHook: .none),
    // vs_uhohu (67) - ươu (full)
    VowelSeqInfo(length: 3, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.uh, .oh, .u], subsequences: [.uh, .uhoh, .uhohu],
                 roofPosition: -1, withRoof: .none, hookPosition: 0, withHook: .none),
    // vs_yeu (68)
    VowelSeqInfo(length: 3, isComplete: false, allowsConsonantSuffix: false,
                 vowels: [.y, .e, .u], subsequences: [.y, .ye, .yeu],
                 roofPosition: -1, withRoof: .yeru, hookPosition: -1, withHook: .none),
    // vs_yeru (69) - yêu
    VowelSeqInfo(length: 3, isComplete: true, allowsConsonantSuffix: false,
                 vowels: [.y, .er, .u], subsequences: [.y, .yer, .yeru],
                 roofPosition: 1, withRoof: .none, hookPosition: -1, withHook: .none),
]

/// Pre-sorted vowel sequence list for binary search
public let sortedVSeqList: [VowelSeqKey] = {
    var list: [VowelSeqKey] = []
    for (index, info) in vowelSeqList.enumerated() {
        guard let seq = VowelSequence(rawValue: index) else { continue }
        let v1 = info.vowels.count > 0 ? info.vowels[0] : .nonVnChar
        let v2 = info.vowels.count > 1 ? info.vowels[1] : .nonVnChar
        let v3 = info.vowels.count > 2 ? info.vowels[2] : .nonVnChar
        list.append(VowelSeqKey(v1: v1, v2: v2, v3: v3, sequence: seq))
    }
    return list.sorted()
}()

/// Get vowel sequence info
public func getVowelSeqInfo(_ seq: VowelSequence) -> VowelSeqInfo? {
    guard seq != .none, seq.rawValue >= 0 && seq.rawValue < vowelSeqList.count else {
        return nil
    }
    return vowelSeqList[seq.rawValue]
}
