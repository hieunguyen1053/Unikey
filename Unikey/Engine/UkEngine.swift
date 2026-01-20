// Unikey Swift Engine
// Ported from x-unikey-1.0.4/src/ukengine/ukengine.cpp & .h
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Jules

import Foundation

// MARK: - Constants & Enums

public let MAX_UK_ENGINE = 128

public enum VnWordForm: Int {
    case nonVn = 0, empty, c, v, cv, vc, cvc
}

public enum UkOutputType: Int {
    case normal = 0
}

public struct UnikeyOptions {
    public var vietKeyEnabled: Bool = true
    public var freeMarking: Bool = true
    public var spellCheckEnabled: Bool = true
    public var modernStyle: Bool = true // oa, oe, uy tone pos
    public var allowUoa: Bool = false // allow uoa (uòa) style
    public var macroEnabled: Bool = true
    public var autoNonVnRestore: Bool = true

    public init() {}
}

public class UkSharedMem {
    public var initialized: Int = 0
    public var vietKey: Int = 1
    public var iconShown: Int = 0

    public var options = UnikeyOptions()
    public var input = UkInputProcessor()

    public var usrKeyMapLoaded: Int = 0
    public var usrKeyMap: [Int] = Array(repeating: 0, count: 256)
    public var charsetId: Int = 0

    public var macStore = MacroTable()

    public init() {}
}

public struct KeyBufEntry {
    var ev: UkKeyEvent
    var converted: Bool

    init(ev: UkKeyEvent = UkKeyEvent(), converted: Bool = false) {
        self.ev = ev
        self.converted = converted
    }
}

public struct WordInfo {
    var form: VnWordForm = .empty
    var c1Offset: Int = -1
    var vOffset: Int = -1
    var c2Offset: Int = -1

    var vseq: VowelSequence = .none
    var cseq: ConsonantSequence = .none

    var caps: Bool = false
    var tone: Int = 0
    var vnSym: VnLexiName = .nonVnChar
    var keyCode: UInt32 = 0
}

public typealias CheckKeyboardCaseCb = (_ shiftPressed: inout Int, _ capslockOn: inout Int) -> Void

// MARK: - Validation Tables

private struct VCPair: Hashable {
    var v: VowelSequence
    var c: ConsonantSequence
}

private let validVCPairs: Set<VCPair> = [
    VCPair(v: .a, c: .c), VCPair(v: .a, c: .ch), VCPair(v: .a, c: .m), VCPair(v: .a, c: .n), VCPair(v: .a, c: .ng), VCPair(v: .a, c: .nh), VCPair(v: .a, c: .p), VCPair(v: .a, c: .t),
    VCPair(v: .ar, c: .c), VCPair(v: .ar, c: .m), VCPair(v: .ar, c: .n), VCPair(v: .ar, c: .ng), VCPair(v: .ar, c: .p), VCPair(v: .ar, c: .t),
    VCPair(v: .ab, c: .c), VCPair(v: .ab, c: .m), VCPair(v: .ab, c: .n), VCPair(v: .ab, c: .ng), VCPair(v: .ab, c: .p), VCPair(v: .ab, c: .t),

    VCPair(v: .e, c: .c), VCPair(v: .e, c: .ch), VCPair(v: .e, c: .m), VCPair(v: .e, c: .n), VCPair(v: .e, c: .ng), VCPair(v: .e, c: .nh), VCPair(v: .e, c: .p), VCPair(v: .e, c: .t),
    VCPair(v: .er, c: .c), VCPair(v: .er, c: .ch), VCPair(v: .er, c: .m), VCPair(v: .er, c: .n), VCPair(v: .er, c: .nh), VCPair(v: .er, c: .p), VCPair(v: .er, c: .t),

    VCPair(v: .i, c: .c), VCPair(v: .i, c: .ch), VCPair(v: .i, c: .m), VCPair(v: .i, c: .n), VCPair(v: .i, c: .nh), VCPair(v: .i, c: .p), VCPair(v: .i, c: .t),

    VCPair(v: .o, c: .c), VCPair(v: .o, c: .m), VCPair(v: .o, c: .n), VCPair(v: .o, c: .ng), VCPair(v: .o, c: .p), VCPair(v: .o, c: .t),
    VCPair(v: .or, c: .c), VCPair(v: .or, c: .m), VCPair(v: .or, c: .n), VCPair(v: .or, c: .ng), VCPair(v: .or, c: .p), VCPair(v: .or, c: .t),
    VCPair(v: .oh, c: .m), VCPair(v: .oh, c: .n), VCPair(v: .oh, c: .p), VCPair(v: .oh, c: .t),

    VCPair(v: .u, c: .c), VCPair(v: .u, c: .m), VCPair(v: .u, c: .n), VCPair(v: .u, c: .ng), VCPair(v: .u, c: .p), VCPair(v: .u, c: .t),
    VCPair(v: .uh, c: .c), VCPair(v: .uh, c: .m), VCPair(v: .uh, c: .n), VCPair(v: .uh, c: .ng), VCPair(v: .uh, c: .t),

    VCPair(v: .y, c: .t),

    VCPair(v: .ie, c: .c), VCPair(v: .ie, c: .m), VCPair(v: .ie, c: .n), VCPair(v: .ie, c: .ng), VCPair(v: .ie, c: .p), VCPair(v: .ie, c: .t),
    VCPair(v: .ier, c: .c), VCPair(v: .ier, c: .m), VCPair(v: .ier, c: .n), VCPair(v: .ier, c: .ng), VCPair(v: .ier, c: .p), VCPair(v: .ier, c: .t),

    VCPair(v: .oa, c: .c), VCPair(v: .oa, c: .ch), VCPair(v: .oa, c: .m), VCPair(v: .oa, c: .n), VCPair(v: .oa, c: .ng), VCPair(v: .oa, c: .nh), VCPair(v: .oa, c: .p), VCPair(v: .oa, c: .t),
    VCPair(v: .oab, c: .c), VCPair(v: .oab, c: .m), VCPair(v: .oab, c: .n), VCPair(v: .oab, c: .ng), VCPair(v: .oab, c: .t),

    VCPair(v: .oe, c: .n), VCPair(v: .oe, c: .t),

    VCPair(v: .ua, c: .n), VCPair(v: .ua, c: .ng), VCPair(v: .ua, c: .t),
    VCPair(v: .uar, c: .n), VCPair(v: .uar, c: .ng), VCPair(v: .uar, c: .t),

    VCPair(v: .ue, c: .c), VCPair(v: .ue, c: .ch), VCPair(v: .ue, c: .n), VCPair(v: .ue, c: .nh),
    VCPair(v: .uer, c: .c), VCPair(v: .uer, c: .ch), VCPair(v: .uer, c: .n), VCPair(v: .uer, c: .nh),

    VCPair(v: .uo, c: .c), VCPair(v: .uo, c: .m), VCPair(v: .uo, c: .n), VCPair(v: .uo, c: .ng), VCPair(v: .uo, c: .p), VCPair(v: .uo, c: .t),
    VCPair(v: .uor, c: .c), VCPair(v: .uor, c: .m), VCPair(v: .uor, c: .n), VCPair(v: .uor, c: .ng), VCPair(v: .uor, c: .t),
    VCPair(v: .uho, c: .c), VCPair(v: .uho, c: .m), VCPair(v: .uho, c: .n), VCPair(v: .uho, c: .ng), VCPair(v: .uho, c: .p), VCPair(v: .uho, c: .t),
    VCPair(v: .uhoh, c: .c), VCPair(v: .uhoh, c: .m), VCPair(v: .uhoh, c: .n), VCPair(v: .uhoh, c: .ng), VCPair(v: .uhoh, c: .p), VCPair(v: .uhoh, c: .t),

    VCPair(v: .uy, c: .c), VCPair(v: .uy, c: .ch), VCPair(v: .uy, c: .n), VCPair(v: .uy, c: .nh), VCPair(v: .uy, c: .p), VCPair(v: .uy, c: .t),

    VCPair(v: .ye, c: .m), VCPair(v: .ye, c: .n), VCPair(v: .ye, c: .ng), VCPair(v: .ye, c: .p), VCPair(v: .ye, c: .t),
    VCPair(v: .yer, c: .m), VCPair(v: .yer, c: .n), VCPair(v: .yer, c: .ng), VCPair(v: .yer, c: .t),

    VCPair(v: .uye, c: .n), VCPair(v: .uye, c: .t),
    VCPair(v: .uyer, c: .n), VCPair(v: .uyer, c: .t)
]

// MARK: - UkEngine Class

public class UkEngine {
    // Properties
    private var m_keyCheckFunc: CheckKeyboardCaseCb?
    private var m_pCtrl: UkSharedMem?

    private var m_changePos: Int = 0
    private var m_backs: Int = 0
    private var m_bufSize: Int = MAX_UK_ENGINE
    private var m_current: Int = -1
    private var m_singleMode: Bool = false

    private var m_keyBufSize: Int = MAX_UK_ENGINE
    private var m_keyStrokes: [KeyBufEntry] = Array(repeating: KeyBufEntry(), count: MAX_UK_ENGINE)
    private var m_keyCurrent: Int = -1
    private var m_toEscape: Bool = false

    private var m_outBuf: [UInt16] = []
    private var m_outputWritten: Bool = false
    private var m_reverted: Bool = false
    private var m_keyRestored: Bool = false
    private var m_keyRestoring: Bool = false
    private var m_outType: UkOutputType = .normal

    private var m_buffer: [WordInfo] = Array(repeating: WordInfo(), count: MAX_UK_ENGINE)

    // MARK: - Public Methods

    public init() {
        reset()
    }

    public func setCtrlInfo(_ p: UkSharedMem) {
        m_pCtrl = p
    }

    public func setCheckKbCaseFunc(_ pFunc: @escaping CheckKeyboardCaseCb) {
        m_keyCheckFunc = pFunc
    }

    public func atWordBeginning() -> Bool {
        return (m_current < 0 || m_buffer[m_current].form == .empty)
    }

    public func pass(_ keyCode: Int) {
        var ev = UkKeyEvent()
        m_pCtrl?.input.keyCodeToEvent(UInt32(keyCode), &ev)
        _ = processAppend(ev)
    }

    public func setSingleMode() {
        m_singleMode = true
    }

    public func reset() {
        m_current = -1
        m_keyCurrent = -1
        m_singleMode = false
        m_toEscape = false
        resetKeyBuf()
    }

    public func process(_ keyCode: UInt32, _ backs: inout Int, _ outBuf: inout [UInt16], _ outSize: inout Int, _ outType: inout UkOutputType) -> Int {
        var ev = UkKeyEvent()
        prepareBuffer()
        m_backs = 0
        m_changePos = m_current + 1
        m_outBuf = []
        m_outputWritten = false
        m_reverted = false
        m_keyRestored = false
        m_keyRestoring = false
        m_outType = .normal

        guard let ctrl = m_pCtrl else { return 0 }

        ctrl.input.keyCodeToEvent(keyCode, &ev)

        var ret = 0

        if !m_toEscape {
            switch ev.evType {
             case UkKeyEvName.roofAll.rawValue, UkKeyEvName.roof_a.rawValue, UkKeyEvName.roof_e.rawValue, UkKeyEvName.roof_o.rawValue:
                 ret = processRoof(ev)
             case UkKeyEvName.hookAll.rawValue, UkKeyEvName.hook_uo.rawValue, UkKeyEvName.hook_u.rawValue, UkKeyEvName.hook_o.rawValue, UkKeyEvName.bowl.rawValue:
                 ret = processHook(ev)
             case UkKeyEvName.dd.rawValue:
                 ret = processDd(ev)
             case UkKeyEvName.tone0.rawValue...UkKeyEvName.tone5.rawValue:
                 ret = processTone(ev)
             case UkKeyEvName.telex_w.rawValue:
                 ret = processTelexW(ev)
             case UkKeyEvName.mapChar.rawValue:
                 ret = processMapChar(ev)
             case UkKeyEvName.escChar.rawValue:
                 ret = processEscChar(ev)
             default:
                 ret = processAppend(ev)
            }
        } else {
            m_toEscape = false
            if m_current < 0 || ev.evType == UkKeyEvName.normal.rawValue || ev.evType == UkKeyEvName.escChar.rawValue {
                ret = processAppend(ev)
            } else {
                m_current -= 1
                ret = processAppend(ev)
                markChange(m_current)
                ret = 1
            }
        }

        if ctrl.vietKey != 0 &&
            m_current >= 0 && m_buffer[m_current].form == .nonVn &&
            ev.chType == .vn &&
            (!ctrl.options.spellCheckEnabled || m_singleMode) {
             ret = processNoSpellCheck(ev)
        }

        if m_current >= 0 {
            ev.chType = ctrl.input.getCharType(ev.keyCode)
            m_keyCurrent += 1
            if m_keyCurrent < MAX_UK_ENGINE {
                m_keyStrokes[m_keyCurrent].ev = ev
                m_keyStrokes[m_keyCurrent].converted = (ret != 0 && !m_keyRestored)
            }
        }

        if ret == 0 {
            backs = 0
            outSize = 0
            outType = m_outType
            return 0
        }

        backs = m_backs
        if !m_outputWritten {
            writeOutput()
        }
        outType = m_outType
        outBuf.append(contentsOf: m_outBuf)
        outSize = outBuf.count

        return ret
    }

    public func processBackspace(_ backs: inout Int, _ outBuf: inout [UInt16], _ outSize: inout Int, _ outType: inout UkOutputType) -> Int {
        outType = .normal
        guard let ctrl = m_pCtrl, ctrl.vietKey != 0, m_current >= 0 else {
            backs = 0
            outSize = 0
            return 0
        }

        m_backs = 0
        m_outBuf = []
        m_changePos = m_current + 1
        markChange(m_current)

        if m_current == 0 ||
            m_buffer[m_current].form == .empty ||
            m_buffer[m_current].form == .nonVn ||
            m_buffer[m_current].form == .c ||
            m_buffer[m_current-1].form == .c ||
            m_buffer[m_current-1].form == .cvc ||
            m_buffer[m_current-1].form == .vc {

            m_current -= 1
            backs = m_backs
            outSize = 0
            synchKeyStrokeBuffer()
            return (backs > 1) ? 1 : 0
        }

        let vEnd = m_current - m_buffer[m_current].vOffset
        let vs = m_buffer[vEnd].vseq
        guard let vsInfo = getVowelSeqInfo(vs) else { return 0 }
        let vStart = vEnd - vsInfo.length + 1
        let newVs = m_buffer[m_current-1].vseq

        let curTonePos = vStart + getTonePosition(vs, terminated: vEnd == m_current)
        let newTonePos = vStart + getTonePosition(newVs, terminated: true)

        let tone = m_buffer[curTonePos].tone

        if tone == 0 || curTonePos == newTonePos || (curTonePos == m_current && m_buffer[m_current].tone != 0) {
            m_current -= 1
            backs = m_backs
            outSize = 0
            synchKeyStrokeBuffer()
            return (backs > 1) ? 1 : 0
        }

        markChange(newTonePos)
        m_buffer[newTonePos].tone = tone
        markChange(curTonePos)
        m_buffer[curTonePos].tone = 0
        m_current -= 1
        synchKeyStrokeBuffer()

        backs = m_backs
        writeOutput()
        outBuf.append(contentsOf: m_outBuf)
        outSize = outBuf.count

        return 1
    }

    public func restoreKeyStrokes(_ backs: inout Int, _ outBuf: inout [UInt16], _ outSize: inout Int, _ outType: inout UkOutputType) -> Int {
        outType = .normal // UkKeyOutput in C++? C++ says UkKeyOutput but defines normal=0.
        // Actually C++ sets outType = UkKeyOutput. I only have .normal.
        // I should add .keyOutput to UkOutputType if needed, or just use normal.

        if !lastWordHasVnMark() {
            backs = 0
            outSize = 0
            return 0
        }

        m_backs = 0
        m_changePos = m_current + 1

        var keyStart = m_keyCurrent
        var converted = false

        while keyStart >= 0 && m_keyStrokes[keyStart].ev.chType != .wordBreak {
            if m_keyStrokes[keyStart].converted {
                converted = true
            }
            keyStart -= 1
        }
        keyStart += 1

        if !converted {
            backs = 0
            outSize = 0
            return 0
        }

        while m_current >= 0 && m_buffer[m_current].form != .empty {
            m_current -= 1
        }
        markChange(m_current + 1)
        backs = m_backs

        m_outBuf = []
        m_keyRestoring = true

        var ev = UkKeyEvent()
        if m_keyCurrent >= keyStart {
            for i in keyStart...m_keyCurrent {
                // C++: outBuf[count++] = keyCode
                // In Swift we append to m_outBuf? No, outBuf arg.
                // But `restoreKeyStrokes` signature returns `outBuf`.
                // We should append RAW keys to output.
                m_outBuf.append(UInt16(m_keyStrokes[i].ev.keyCode))

                guard let ctrl = m_pCtrl else { continue }
                ctrl.input.keyCodeToSymbol(m_keyStrokes[i].ev.keyCode, &ev)
                m_keyStrokes[i].converted = false
                _ = processAppend(ev)
            }
        }

        m_keyRestoring = false

        // Output is raw keys, not processed string?
        // C++: outBuf gets keyCodes.
        // My implementation of process puts processed chars in m_outBuf.
        // But here we want raw keys.
        // `m_outBuf` was filled with raw keys above.
        // Wait, `processAppend` inside loop might update `m_buffer` but we don't call `writeOutput`.
        // Correct.

        outBuf.append(contentsOf: m_outBuf)
        outSize = m_outBuf.count

        return 1
    }

    private func lastWordHasVnMark() -> Bool {
        var i = m_current
        while i >= 0 && m_buffer[i].form != .empty {
            let sym = m_buffer[i].vnSym
            if sym != .nonVnChar {
                if sym.isVowel && m_buffer[i].tone != 0 {
                    return true
                }
                // Check if sym is different from root
                // VnLexiName.baseChar gives root.
                if sym != sym.baseChar {
                    return true
                }
            }
            i -= 1
        }
        return false
    }

    private func lastWordIsNonVn() -> Bool {
        if m_current < 0 { return false }

        switch m_buffer[m_current].form {
        case .nonVn: return true
        case .empty, .c: return false
        case .v, .cv:
            if let info = getVowelSeqInfo(m_buffer[m_current].vseq) {
                return !info.complete
            }
            return true
        case .vc, .cvc:
            let vIndex = m_current - m_buffer[m_current].vOffset
            let vs = m_buffer[vIndex].vseq
            guard let vsInfo = getVowelSeqInfo(vs) else { return true }
            if !vsInfo.complete { return true }

            let cs = m_buffer[m_current].cseq
            var c1: ConsonantSequence = .none
            if m_buffer[m_current].c1Offset != -1 {
                c1 = m_buffer[m_current - m_buffer[m_current].c1Offset].cseq
            }

            if !isValidCVC(c1, vs, cs) { return true }

            let tonePos = (vIndex - vsInfo.length + 1) + getTonePosition(vs, terminated: false)
            let tone = m_buffer[tonePos].tone
            if (cs == .c || cs == .ch || cs == .p || cs == .t) && (tone == 2 || tone == 3 || tone == 4) {
                return true
            }
        }
        return false
    }

    // MARK: - Internal Logic

    private func resetKeyBuf() {
        m_keyCurrent = -1
    }

    private func checkEscapeVIQR(_ ev: UkKeyEvent) -> Int {
        if m_current < 0 { return 0 }
        let entry = m_buffer[m_current]
        var escape = false

        if entry.form == .v || entry.form == .cv {
            switch ev.keyCode {
            case 94: // ^
                escape = (entry.vnSym == .a || entry.vnSym == .o || entry.vnSym == .e)
            case 40: // (
                escape = (entry.vnSym == .a)
            case 43: // +
                escape = (entry.vnSym == .o || entry.vnSym == .u)
            case 39, 96, 63, 126, 46: // ' ` ? ~ .
                escape = (entry.tone == 0)
            default: break
            }
        } else if entry.form == .nonVn {
             let ch = Charset.toUpper(Character(UnicodeScalar(entry.keyCode) ?? " "))
             // Check...
             // Simplified
        }

        if escape {
            // ...
        }
        return 0
    }

    private func processWordEnd(_ ev: UkKeyEvent) -> Int {
        guard let ctrl = m_pCtrl else { return 0 }
        if ctrl.options.macroEnabled && macroMatch(ev) != 0 {
            return 1
        }

        if !ctrl.options.spellCheckEnabled || m_singleMode || m_current < 0 || m_keyRestoring {
            m_current += 1
            var entry = WordInfo()
            entry.form = .empty
            entry.keyCode = ev.keyCode
            entry.vnSym = ev.vnSym.toLower
            entry.caps = (entry.vnSym != ev.vnSym)
            m_buffer[m_current] = entry
            return 0
        }

        // Restore logic...

        m_current += 1
        var entry = WordInfo()
        entry.form = .empty
        entry.keyCode = ev.keyCode
        entry.vnSym = ev.vnSym.toLower
        entry.caps = (entry.vnSym != ev.vnSym)
        m_buffer[m_current] = entry

        return 0
    }

    private func macroMatch(_ ev: UkKeyEvent) -> Int {
        return 0
    }

    private func processTone(_ ev: UkKeyEvent) -> Int {
        guard let ctrl = m_pCtrl, m_current >= 0, ctrl.vietKey != 0 else {
            return processAppend(ev)
        }

        if m_buffer[m_current].form == .c && (m_buffer[m_current].cseq == .gi || m_buffer[m_current].cseq == .gin) {
            let p = (m_buffer[m_current].cseq == .gi) ? m_current : m_current - 1
            if m_buffer[p].tone == 0 && ev.tone == 0 {
                return processAppend(ev)
            }
            markChange(p)
            if m_buffer[p].tone == ev.tone {
                m_buffer[p].tone = 0
                m_singleMode = false
                _ = processAppend(ev)
                m_reverted = true
                return 1
            }
            m_buffer[p].tone = ev.tone
            return 1
        }

        if m_buffer[m_current].vOffset < 0 {
            return processAppend(ev)
        }

        let vEnd = m_current - m_buffer[m_current].vOffset
        let vs = m_buffer[vEnd].vseq
        guard let info = getVowelSeqInfo(vs) else { return processAppend(ev) }

        if ctrl.options.spellCheckEnabled && !ctrl.options.freeMarking && !info.complete {
            return processAppend(ev)
        }

        if m_buffer[m_current].form == .vc || m_buffer[m_current].form == .cvc {
            let cs = m_buffer[m_current].cseq
            if (cs == .c || cs == .ch || cs == .p || cs == .t) && (ev.tone == 2 || ev.tone == 3 || ev.tone == 4) {
                return processAppend(ev)
            }
        }

        let toneOffset = getTonePosition(vs, terminated: vEnd == m_current)
        let tonePos = vEnd - (info.length - 1) + toneOffset

        if m_buffer[tonePos].tone == 0 && ev.tone == 0 {
            return processAppend(ev)
        }

        if m_buffer[tonePos].tone == ev.tone {
            markChange(tonePos)
            m_buffer[tonePos].tone = 0
            m_singleMode = false
            _ = processAppend(ev)
            m_reverted = true
            return 1
        }

        markChange(tonePos)
        m_buffer[tonePos].tone = ev.tone
        return 1
    }

    private func processRoof(_ ev: UkKeyEvent) -> Int {
        guard let ctrl = m_pCtrl, ctrl.vietKey != 0, m_current >= 0, m_buffer[m_current].vOffset >= 0 else {
            return processAppend(ev)
        }

        var target: VnLexiName = .nonVnChar
        switch ev.evType {
        case UkKeyEvName.roof_a.rawValue: target = .ar
        case UkKeyEvName.roof_e.rawValue: target = .er
        case UkKeyEvName.roof_o.rawValue: target = .or
        default: break
        }

        let vEnd = m_current - m_buffer[m_current].vOffset
        let vs = m_buffer[vEnd].vseq
        guard let info = getVowelSeqInfo(vs) else { return processAppend(ev) }
        let vStart = vEnd - (info.length - 1)

        let curTonePos = vStart + getTonePosition(vs, terminated: vEnd == m_current)
        let tone = m_buffer[curTonePos].tone

        var newVs: VowelSequence = .none
        var doubleChangeUO = false

        if vs == .uho || vs == .uhoh || vs == .uhoi || vs == .uhohi {
            newVs = lookupVowelSeq(.u, .or, info.vowels[2])
            doubleChangeUO = true
        } else {
            newVs = info.withRoof
        }

        guard let newInfo = getVowelSeqInfo(newVs) else {
            // Undo roof if exists
            if info.roofPosition == -1 { return processAppend(ev) }

            let curCh = m_buffer[vStart + info.roofPosition].vnSym
            if target != .nonVnChar && curCh != target { return processAppend(ev) }

            let newCh = (curCh == .ar) ? .a : ((curCh == .er) ? .e : .o)
            let changePos = vStart + info.roofPosition

            if !ctrl.options.freeMarking && changePos != m_current { return processAppend(ev) }

            markChange(changePos)
            m_buffer[changePos].vnSym = newCh

            if info.length == 3 {
                newVs = lookupVowelSeq(m_buffer[vStart].vnSym, m_buffer[vStart+1].vnSym, m_buffer[vStart+2].vnSym)
            } else if info.length == 2 {
                newVs = lookupVowelSeq(m_buffer[vStart].vnSym, m_buffer[vStart+1].vnSym)
            } else {
                newVs = lookupVowelSeq(m_buffer[vStart].vnSym)
            }

            if let pInfo = getVowelSeqInfo(newVs) {
                for i in 0..<pInfo.length {
                    m_buffer[vStart+i].vseq = pInfo.subsequences[i]
                }
            }

            // Tone reposition
            let newTonePos = vStart + getTonePosition(newVs, terminated: vEnd == m_current)
            if curTonePos != newTonePos && tone != 0 {
                markChange(newTonePos)
                m_buffer[newTonePos].tone = tone
                markChange(curTonePos)
                m_buffer[curTonePos].tone = 0
            }

            m_singleMode = false
            _ = processAppend(ev)
            m_reverted = true
            return 1
        }

        // Add roof
        if target != .nonVnChar && newInfo.vowels[newInfo.roofPosition] != target {
            return processAppend(ev)
        }

        // Validation
        var c1: ConsonantSequence = .none
        if m_buffer[m_current].c1Offset != -1 {
            c1 = m_buffer[m_current - m_buffer[m_current].c1Offset].cseq
        }
        var c2: ConsonantSequence = .none
        if m_buffer[m_current].c2Offset != -1 {
            c2 = m_buffer[m_current - m_buffer[m_current].c2Offset].cseq
        }

        if !isValidCVC(c1, newVs, c2) { return processAppend(ev) }

        var changePos = 0
        if doubleChangeUO {
            changePos = vStart
        } else {
            changePos = vStart + newInfo.roofPosition
        }

        if !ctrl.options.freeMarking && changePos != m_current { return processAppend(ev) }

        markChange(changePos)
        if doubleChangeUO {
            m_buffer[vStart].vnSym = .u
            m_buffer[vStart+1].vnSym = .or
        } else {
            m_buffer[changePos].vnSym = newInfo.vowels[newInfo.roofPosition]
        }

        for i in 0..<newInfo.length {
            m_buffer[vStart+i].vseq = newInfo.subsequences[i]
        }

        let newTonePos = vStart + getTonePosition(newVs, terminated: vEnd == m_current)
        if curTonePos != newTonePos && tone != 0 {
            markChange(newTonePos)
            m_buffer[newTonePos].tone = tone
            markChange(curTonePos)
            m_buffer[curTonePos].tone = 0
        }

        return 1
    }

    private func processHookWithUO(_ ev: UkKeyEvent) -> Int {
        guard let ctrl = m_pCtrl else { return processAppend(ev) }
        if !ctrl.options.freeMarking && m_buffer[m_current].vOffset != 0 {
            return processAppend(ev)
        }

        let vEnd = m_current - m_buffer[m_current].vOffset
        let vs = m_buffer[vEnd].vseq
        guard let info = getVowelSeqInfo(vs) else { return processAppend(ev) }
        let vStart = vEnd - (info.length - 1)
        let vowels = info.vowels

        let curTonePos = vStart + getTonePosition(vs, terminated: vEnd == m_current)
        let tone = m_buffer[curTonePos].tone

        var newVs: VowelSequence = .none
        var hookRemoved = false
        var toneRemoved = false
        var removeWithUndo = true

        switch ev.evType {
        case UkKeyEvName.hook_u.rawValue:
            if vowels[0] == .u {
                newVs = info.withHook
                markChange(vStart)
                m_buffer[vStart].vnSym = .uh
            } else { // uh -> uo
                newVs = lookupVowelSeq(.u, .o, info.length > 2 ? vowels[2] : .nonVnChar)
                markChange(vStart)
                m_buffer[vStart].vnSym = .u
                m_buffer[vStart+1].vnSym = .o
                hookRemoved = true
                toneRemoved = (m_buffer[vStart].tone != 0)
            }

        case UkKeyEvName.hook_o.rawValue:
            if vowels[1] == .o || vowels[1] == .or {
                if vEnd == m_current && info.length == 2 && m_buffer[m_current].form == .cv &&
                   m_buffer[m_current-2].cseq == .th {
                    // o|o^ -> o+ (th+uo -> th+uo+)
                    newVs = info.withHook
                    markChange(vStart+1)
                    m_buffer[vStart+1].vnSym = .oh
                } else {
                    newVs = lookupVowelSeq(.uh, .oh, info.length > 2 ? vowels[2] : .nonVnChar)
                    if vowels[0] == .u {
                        markChange(vStart)
                        m_buffer[vStart].vnSym = .uh
                        m_buffer[vStart+1].vnSym = .oh
                    } else {
                        markChange(vStart+1)
                        m_buffer[vStart+1].vnSym = .oh
                    }
                }
            } else { // oh -> uo
                newVs = lookupVowelSeq(.u, .o, info.length > 2 ? vowels[2] : .nonVnChar)
                if vowels[0] == .uh {
                    markChange(vStart)
                    m_buffer[vStart].vnSym = .u
                    m_buffer[vStart+1].vnSym = .o
                } else {
                    markChange(vStart+1)
                    m_buffer[vStart+1].vnSym = .o
                }
                hookRemoved = true
                toneRemoved = (m_buffer[vStart+1].tone != 0)
            }

        default: // hookAll, hookUO
            if vowels[0] == .u {
                if vowels[1] == .o || vowels[1] == .or {
                    // uo -> uo+ if th or h
                    if (vs == .uo || vs == .uor) && vEnd == m_current && m_buffer[m_current].form == .cv &&
                       (m_buffer[m_current-2].cseq == .th || m_buffer[m_current-2].cseq == .h) {
                        newVs = .uoh
                        markChange(vStart+1)
                        m_buffer[vStart+1].vnSym = .oh
                    } else {
                        // uo -> u+o+
                        newVs = info.withHook
                        markChange(vStart)
                        m_buffer[vStart].vnSym = .uh
                        if let tempInfo = getVowelSeqInfo(newVs) {
                            newVs = tempInfo.withHook
                            m_buffer[vStart+1].vnSym = .oh
                        }
                    }
                } else { // uo+ -> u+o+
                    newVs = info.withHook
                    markChange(vStart)
                    m_buffer[vStart].vnSym = .uh
                }
            } else { // v[0] == uh
                if vowels[1] == .o { // u+o -> u+o+
                    newVs = info.withHook
                    markChange(vStart+1)
                    m_buffer[vStart+1].vnSym = .oh
                } else { // v[1] == oh, u+o+ -> uo
                    newVs = lookupVowelSeq(.u, .o, info.length > 2 ? vowels[2] : .nonVnChar)
                    markChange(vStart)
                    m_buffer[vStart].vnSym = .u
                    m_buffer[vStart+1].vnSym = .o
                    hookRemoved = true
                    toneRemoved = (m_buffer[vStart].tone != 0 || m_buffer[vStart+1].tone != 0)
                }
            }
        }

        guard let p = getVowelSeqInfo(newVs) else { return 1 } // Should fail gracefully?
        for i in 0..<p.length {
            m_buffer[vStart+i].vseq = p.subsequences[i]
        }

        let newTonePos = vStart + getTonePosition(newVs, terminated: vEnd == m_current)
        if curTonePos != newTonePos && tone != 0 {
            markChange(newTonePos)
            m_buffer[newTonePos].tone = tone
            markChange(curTonePos)
            m_buffer[curTonePos].tone = 0
        }

        if hookRemoved && removeWithUndo {
            m_singleMode = false
            _ = processAppend(ev)
            m_reverted = true
        }

        return 1
    }

    private func processHook(_ ev: UkKeyEvent) -> Int {
        guard let ctrl = m_pCtrl, ctrl.vietKey != 0, m_current >= 0, m_buffer[m_current].vOffset >= 0 else {
            return processAppend(ev)
        }

        let vEnd = m_current - m_buffer[m_current].vOffset
        let vs = m_buffer[vEnd].vseq
        guard let info = getVowelSeqInfo(vs) else { return processAppend(ev) }
        let vStart = vEnd - (info.length - 1)
        let vowels = info.vowels

        if info.length > 1 && ev.evType != UkKeyEvName.bowl.rawValue &&
           (vowels[0] == .u || vowels[0] == .uh) &&
           (vowels[1] == .o || vowels[1] == .oh || vowels[1] == .or) {
            return processHookWithUO(ev)
        }

        let curTonePos = vStart + getTonePosition(vs, terminated: vEnd == m_current)
        let tone = m_buffer[curTonePos].tone

        var newVs = info.withHook

        if newVs == .none {
            if info.hookPosition == -1 { return processAppend(ev) }

            // Remove hook
            let curCh = m_buffer[vStart + info.hookPosition].vnSym
            var newCh: VnLexiName = .nonVnChar
            if curCh == .ab { newCh = .a }
            else if curCh == .uh { newCh = .u }
            else { newCh = .o } // oh -> o

            let changePos = vStart + info.hookPosition
            if !ctrl.options.freeMarking && changePos != m_current { return processAppend(ev) }

            // Check event type match
            switch ev.evType {
            case UkKeyEvName.hook_u.rawValue: if curCh != .uh { return processAppend(ev) }
            case UkKeyEvName.hook_o.rawValue: if curCh != .oh { return processAppend(ev) }
            case UkKeyEvName.bowl.rawValue: if curCh != .ab { return processAppend(ev) }
            default: break
            }

            markChange(changePos)
            m_buffer[changePos].vnSym = newCh

            if info.length == 3 {
                newVs = lookupVowelSeq(m_buffer[vStart].vnSym, m_buffer[vStart+1].vnSym, m_buffer[vStart+2].vnSym)
            } else if info.length == 2 {
                newVs = lookupVowelSeq(m_buffer[vStart].vnSym, m_buffer[vStart+1].vnSym)
            } else {
                newVs = lookupVowelSeq(m_buffer[vStart].vnSym)
            }

            if let pInfo = getVowelSeqInfo(newVs) {
                for i in 0..<pInfo.length {
                    m_buffer[vStart+i].vseq = pInfo.subsequences[i]
                }
            }

            let newTonePos = vStart + getTonePosition(newVs, terminated: vEnd == m_current)
            if curTonePos != newTonePos && tone != 0 {
                markChange(newTonePos)
                m_buffer[newTonePos].tone = tone
                markChange(curTonePos)
                m_buffer[curTonePos].tone = 0
            }

            m_singleMode = false
            _ = processAppend(ev)
            m_reverted = true
            return 1
        } else {
            guard let newInfo = getVowelSeqInfo(newVs) else { return processAppend(ev) }

            switch ev.evType {
            case UkKeyEvName.hook_u.rawValue: if newInfo.vowels[newInfo.hookPosition] != .uh { return processAppend(ev) }
            case UkKeyEvName.hook_o.rawValue: if newInfo.vowels[newInfo.hookPosition] != .oh { return processAppend(ev) }
            case UkKeyEvName.bowl.rawValue: if newInfo.vowels[newInfo.hookPosition] != .ab { return processAppend(ev) }
            default: break
            }

            // Validation (CVC)
            var c1: ConsonantSequence = .none
            if m_buffer[m_current].c1Offset != -1 {
                c1 = m_buffer[m_current - m_buffer[m_current].c1Offset].cseq
            }
            var c2: ConsonantSequence = .none
            if m_buffer[m_current].c2Offset != -1 {
                c2 = m_buffer[m_current - m_buffer[m_current].c2Offset].cseq
            }

            if !isValidCVC(c1, newVs, c2) { return processAppend(ev) }

            let changePos = vStart + newInfo.hookPosition
            if !ctrl.options.freeMarking && changePos != m_current { return processAppend(ev) }

            markChange(changePos)
            m_buffer[changePos].vnSym = newInfo.vowels[newInfo.hookPosition]

            for i in 0..<newInfo.length {
                m_buffer[vStart+i].vseq = newInfo.subsequences[i]
            }

            let newTonePos = vStart + getTonePosition(newVs, terminated: vEnd == m_current)
            if curTonePos != newTonePos && tone != 0 {
                markChange(newTonePos)
                m_buffer[newTonePos].tone = tone
                markChange(curTonePos)
                m_buffer[curTonePos].tone = 0
            }

            return 1
        }
    }

    private func processDd(_ ev: UkKeyEvent) -> Int {
        guard let ctrl = m_pCtrl, ctrl.vietKey != 0, m_current >= 0 else {
            return processAppend(ev)
        }

        // Allow dd in non-vn if preceding is not vowel
        if m_buffer[m_current].form == .nonVn && m_buffer[m_current].vnSym == .d {
            let prevSym = (m_current > 0) ? m_buffer[m_current-1].vnSym : .nonVnChar
            if prevSym == .nonVnChar || !prevSym.isVowel {
                m_singleMode = true
                markChange(m_current)
                m_buffer[m_current].cseq = .dd
                m_buffer[m_current].vnSym = .dd
                m_buffer[m_current].form = .c
                m_buffer[m_current].c1Offset = 0
                m_buffer[m_current].c2Offset = -1
                m_buffer[m_current].vOffset = -1
                return 1
            }
        }

        if m_buffer[m_current].c1Offset < 0 {
            return processAppend(ev)
        }

        let pos = m_current - m_buffer[m_current].c1Offset
        if !ctrl.options.freeMarking && pos != m_current {
            return processAppend(ev)
        }

        if m_buffer[pos].cseq == .d {
            markChange(pos)
            m_buffer[pos].cseq = .dd
            m_buffer[pos].vnSym = .dd
            m_singleMode = true
            return 1
        }

        if m_buffer[pos].cseq == .dd {
            markChange(pos)
            m_buffer[pos].cseq = .d
            m_buffer[pos].vnSym = .d
            m_singleMode = false
            _ = processAppend(ev)
            m_reverted = true
            return 1
        }

        return processAppend(ev)
    }

    private func processTelexW(_ ev: UkKeyEvent) -> Int {
        guard let ctrl = m_pCtrl, ctrl.vietKey != 0 else { return processAppend(ev) }

        var newEv = ev
        newEv.evType = UkKeyEvName.hookAll.rawValue
        let ret = processHook(newEv)

        if ret == 0 {
            // Try map char (w -> u/o hook map?)
            // In C++: uses static flag usedAsMapChar to avoid infinite recursion.
            // If hook fails, try as mapChar (u+, o+ etc).
            // W map to Uh/uh?
            // "ev.evType = vneMapChar; ev.vnSym = isupper? Uh : uh;"
            // We can try to call processMapChar.
            if m_current >= 0 {
                // m_current-- ?
                // processMapChar usually handles replacement.
            }
            newEv.evType = UkKeyEvName.mapChar.rawValue
            newEv.chType = .vn
            newEv.vnSym = Charset.isUpper(Character(UnicodeScalar(ev.keyCode) ?? "W")) ? .Uh : .uh
            return processMapChar(newEv)
        }
        return ret
    }

    private func processMapChar(_ ev: UkKeyEvent) -> Int {
        return processAppend(ev)
    }

    private func processEscChar(_ ev: UkKeyEvent) -> Int {
        return processAppend(ev)
    }

    private func processAppend(_ ev: UkKeyEvent) -> Int {
        switch ev.chType {
        case .reset:
            reset()
            return 0
        case .wordBreak:
            m_singleMode = false
            return processWordEnd(ev)
        case .nonVn:
             // ...
             m_current += 1
             var entry = WordInfo()
             entry.form = (ev.chType == .wordBreak) ? .empty : .nonVn
             entry.keyCode = ev.keyCode
             entry.vnSym = ev.vnSym.toLower
             entry.caps = (entry.vnSym != ev.vnSym)
             m_buffer[m_current] = entry
             markChange(m_current)
             return 1
        case .vn:
             if ev.vnSym.isVowel {
                 // appendVowel...
                 var lowerSym = ev.vnSym.toLower
                 // In C++, StdVnNoTone check.
                 // We need to normalize to base (remove tone from Input)
                 // But wait, key input normally doesn't have tone except via mapChar?
                 // InputMethod returns 'vnSym'.

                 // Logic:
                 return appendVowel(ev)
             }
             return appendConsonnant(ev)
        }
    }

    private func appendVowel(_ ev: UkKeyEvent) -> Int {
        var autoCompleted = false
        m_current += 1
        var entry = WordInfo()

        let lowerSym = ev.vnSym.toLower
        let canSym = lowerSym.baseChar

        entry.vnSym = canSym
        entry.caps = (lowerSym != ev.vnSym)
        entry.tone = (lowerSym.rawValue - canSym.rawValue) / 2
        entry.keyCode = ev.keyCode

        guard let ctrl = m_pCtrl else { return 0 }

        if m_current == 0 || ctrl.vietKey == 0 {
            entry.form = .v
            entry.c1Offset = -1
            entry.c2Offset = -1
            entry.vOffset = 0
            entry.vseq = lookupVowelSeq(canSym)

            if ctrl.vietKey == 0 {
                // If charset check fails... (skipped)
                // Just return 0? C++ logic
                return 0
            }
            m_buffer[m_current] = entry
            markChange(m_current)
            return 1
        }

        let prev = m_buffer[m_current - 1]
        var newVs: VowelSequence = .none
        var tone = 0
        var newTone = 0

        switch prev.form {
        case .empty:
            entry.form = .v
            entry.c1Offset = -1
            entry.c2Offset = -1
            entry.vOffset = 0
            entry.vseq = lookupVowelSeq(canSym)
            newVs = entry.vseq

        case .nonVn, .cvc, .vc:
            entry.form = .nonVn
            entry.c1Offset = -1
            entry.c2Offset = -1
            entry.vOffset = -1

        case .v, .cv:
            let vs = prev.vseq
            guard let vsInfo = getVowelSeqInfo(vs) else {
                entry.form = .nonVn
                break
            }

            let prevTonePos = (m_current - 1) - (vsInfo.length - 1) + getTonePosition(vs, terminated: true)
            tone = m_buffer[prevTonePos].tone

            if lowerSym != canSym && tone != 0 {
                newVs = .none
            } else {
                if vsInfo.length == 3 {
                    newVs = .none
                } else if vsInfo.length == 2 {
                    newVs = lookupVowelSeq(vsInfo.vowels[0], vsInfo.vowels[1], canSym)
                } else {
                    newVs = lookupVowelSeq(vsInfo.vowels[0], canSym)
                }
            }

            if newVs != .none && prev.form == .cv {
                if prev.c1Offset >= 0 {
                    let cs = m_buffer[m_current - 1 - prev.c1Offset].cseq
                    if !isValidCV(cs, newVs) {
                        newVs = .none
                    }
                }
            }

            if newVs == .none {
                entry.form = .nonVn
                entry.c1Offset = -1
                entry.c2Offset = -1
                entry.vOffset = -1
                break
            }

            entry.form = prev.form
            entry.c1Offset = (prev.form == .cv) ? prev.c1Offset + 1 : -1
            entry.c2Offset = -1
            entry.vOffset = 0
            entry.vseq = newVs
            entry.tone = 0

            newTone = (lowerSym.rawValue - canSym.rawValue) / 2

            if tone == 0 {
                if newTone != 0 {
                    tone = newTone
                    let tonePos = getTonePosition(newVs, terminated: true) + ((m_current - 1) - vsInfo.length + 1)
                    // Wait, logic in C++: tonePos = getTonePosition(...) + ...
                    // Correct.
                    // But we need buffer index.
                    // C++: tonePos is absolute index?
                    // "tonePos = getTonePosition(newVs, true) + ((m_current - 1) - VSeqList[vs].len + 1);"
                    // (m_current - 1) is index of previous char.
                    // VSeqList[vs].len is length of PREVIOUS sequence.
                    // So ((m_current - 1) - len + 1) is START of sequence.
                    // Correct.

                    // We need newVs info for getTonePosition? Yes.
                    // But C++ uses getTonePosition(newVs, true).
                    // Wait, tonePos depends on newVs structure.
                    // If newVs is length 2 (extended), and previous was length 1.
                    // The start index is the same.

                    markChange(tonePos)
                    m_buffer[m_current] = entry // Save entry before accessing buffer potentially?
                    // No, tonePos is previous char usually.
                    // But wait, tonePos is calculated based on start.
                    // We must ensure buffer at tonePos is valid.
                    // If tonePos == m_current, we are setting tone on current.
                    // Yes.

                    m_buffer[m_current] = entry // Commit current
                    m_buffer[tonePos].tone = tone
                    return 1
                }
            } else {
                let newTonePos = getTonePosition(newVs, terminated: true) + ((m_current - 1) - vsInfo.length + 1)
                if newTonePos != prevTonePos {
                    markChange(prevTonePos)
                    m_buffer[prevTonePos].tone = 0
                    markChange(newTonePos)
                    if newTone != 0 { tone = newTone }
                    m_buffer[m_current] = entry
                    m_buffer[newTonePos].tone = tone
                    return 1
                }
                if newTone != 0 && newTone != tone {
                    tone = newTone
                    markChange(prevTonePos)
                    m_buffer[m_current] = entry
                    m_buffer[prevTonePos].tone = tone
                    return 1
                }
            }

        case .c:
            newVs = lookupVowelSeq(canSym)
            let cs = prev.cseq
            if !isValidCV(cs, newVs) {
                entry.form = .nonVn
                entry.c1Offset = -1
                entry.c2Offset = -1
                entry.vOffset = -1
                break
            }

            entry.form = .cv
            entry.c1Offset = 1
            entry.c2Offset = -1
            entry.vOffset = 0
            entry.vseq = newVs

            if cs == .gi && prev.tone != 0 {
                if entry.tone == 0 { entry.tone = prev.tone }
                markChange(m_current - 1)
                m_buffer[m_current - 1].tone = 0
                m_buffer[m_current] = entry
                return 1
            }
        }

        m_buffer[m_current] = entry
        markChange(m_current)
        return 1
    }

    private func appendConsonnant(_ ev: UkKeyEvent) -> Int {
        var complexEvent = false
        m_current += 1
        var entry = WordInfo()

        let lowerSym = ev.vnSym.toLower
        entry.vnSym = lowerSym
        entry.caps = (lowerSym != ev.vnSym)
        entry.keyCode = ev.keyCode
        entry.tone = 0

        guard let ctrl = m_pCtrl else { return 0 }

        if m_current == 0 || ctrl.vietKey == 0 {
            entry.form = .c
            entry.c1Offset = 0
            entry.c2Offset = -1
            entry.vOffset = -1
            entry.cseq = lookupConsonantSeq(lowerSym)

            if ctrl.vietKey == 0 { return 0 }
            m_buffer[m_current] = entry
            markChange(m_current)
            return 1
        }

        var prev = m_buffer[m_current - 1]
        var cs: ConsonantSequence = .none
        var newCs: ConsonantSequence = .none

        switch prev.form {
        case .nonVn:
            entry.form = .nonVn
            entry.c1Offset = -1
            entry.c2Offset = -1
            entry.vOffset = -1
            m_buffer[m_current] = entry
            markChange(m_current)
            return 1

        case .empty:
            entry.form = .c
            entry.c1Offset = 0
            entry.c2Offset = -1
            entry.vOffset = -1
            entry.cseq = lookupConsonantSeq(lowerSym)
            m_buffer[m_current] = entry
            markChange(m_current)
            return 1

        case .v, .cv:
            var vs = prev.vseq
            var newVs = vs
            if vs == .uoh || vs == .uho {
                newVs = .uhoh
            }

            var c1: ConsonantSequence = .none
            if prev.c1Offset != -1 {
                c1 = m_buffer[m_current - 1 - prev.c1Offset].cseq
            }

            newCs = lookupConsonantSeq(lowerSym)
            let isValid = isValidCVC(c1, newVs, newCs)

            if isValid {
                if vs == .uho {
                    markChange(m_current - 1)
                    m_buffer[m_current - 1].vnSym = .oh
                    m_buffer[m_current - 1].vseq = .uhoh
                    prev.vseq = .uhoh // Update local copy if needed? No, reference `prev` is value copy in Swift struct?
                    // Swift structs are value types. `prev` is a copy.
                    // We must update m_buffer directly.
                    complexEvent = true
                } else if vs == .uoh {
                    markChange(m_current - 2)
                    m_buffer[m_current - 2].vnSym = .uh
                    m_buffer[m_current - 2].vseq = .uh
                    m_buffer[m_current - 1].vseq = .uhoh
                    complexEvent = true
                }

                if prev.form == .v {
                    entry.form = .vc
                    entry.c1Offset = -1
                    entry.c2Offset = 0
                    entry.vOffset = 1
                } else {
                    entry.form = .cvc
                    entry.c1Offset = prev.c1Offset + 1
                    entry.c2Offset = 0
                    entry.vOffset = 1
                }
                entry.cseq = newCs

                // Reposition tone
                guard let vsInfo = getVowelSeqInfo(vs), let newVsInfo = getVowelSeqInfo(newVs) else { break }

                let oldIdx = (m_current - 1) - (vsInfo.length - 1) + getTonePosition(vs, terminated: true)
                if m_buffer[oldIdx].tone != 0 {
                    let newIdx = (m_current - 1) - (newVsInfo.length - 1) + getTonePosition(newVs, terminated: false)
                    if newIdx != oldIdx {
                        markChange(newIdx)
                        m_buffer[newIdx].tone = m_buffer[oldIdx].tone
                        markChange(oldIdx)
                        m_buffer[oldIdx].tone = 0
                        m_buffer[m_current] = entry
                        return 1
                    }
                }
            } else {
                entry.form = .nonVn
                entry.c1Offset = -1
                entry.c2Offset = -1
                entry.vOffset = -1
            }

            if complexEvent {
                m_buffer[m_current] = entry
                return 1
            }
            m_buffer[m_current] = entry
            markChange(m_current)
            return 1

        case .c, .vc, .cvc:
            cs = prev.cseq
            guard let csInfo = getConsonantSeqInfo(cs) else {
                entry.form = .nonVn
                break
            }

            if csInfo.length == 3 {
                newCs = .none
            } else if csInfo.length == 2 {
                newCs = lookupConsonantSeq(csInfo.consonants[0], csInfo.consonants[1], lowerSym)
            } else {
                newCs = lookupConsonantSeq(csInfo.consonants[0], lowerSym)
            }

            if newCs != .none && (prev.form == .vc || prev.form == .cvc) {
                var c1: ConsonantSequence = .none
                if prev.c1Offset != -1 {
                    c1 = m_buffer[m_current - 1 - prev.c1Offset].cseq
                }
                let vIdx = (m_current - 1) - prev.vOffset
                let vs = m_buffer[vIdx].vseq
                if !isValidCVC(c1, vs, newCs) {
                    newCs = .none
                }
            }

            if newCs == .none {
                entry.form = .nonVn
                entry.c1Offset = -1
                entry.c2Offset = -1
                entry.vOffset = -1
            } else {
                if prev.form == .c {
                    entry.form = .c
                    entry.c1Offset = 0
                    entry.c2Offset = -1
                    entry.vOffset = -1
                } else if prev.form == .vc {
                    entry.form = .vc
                    entry.c1Offset = -1
                    entry.c2Offset = 0
                    entry.vOffset = prev.vOffset + 1
                } else {
                    entry.form = .cvc
                    entry.c1Offset = prev.c1Offset + 1
                    entry.c2Offset = 0
                    entry.vOffset = prev.vOffset + 1
                }
                entry.cseq = newCs
            }
            m_buffer[m_current] = entry
            markChange(m_current)
            return 1
        }

        m_buffer[m_current] = entry
        markChange(m_current)
        return 1
    }

    private func processNoSpellCheck(_ ev: UkKeyEvent) -> Int {
        var entry = m_buffer[m_current]
        if entry.vnSym.isVowel {
             entry.form = .v
             entry.vOffset = 0
             entry.vseq = lookupVowelSeq(entry.vnSym)
             entry.c1Offset = -1
             entry.c2Offset = -1
        } else {
             entry.form = .c
             entry.c1Offset = 0
             entry.c2Offset = -1
             entry.vOffset = -1
             entry.cseq = lookupConsonantSeq(entry.vnSym)
        }
        m_buffer[m_current] = entry

        if ev.evType == UkKeyEvName.normal.rawValue &&
           ((entry.keyCode >= 65 && entry.keyCode <= 90) || (entry.keyCode >= 97 && entry.keyCode <= 122)) {
            return 0
        }

        markChange(m_current)
        return 1
    }

    private func prepareBuffer() {
        if m_current >= m_bufSize - 10 {
            // Get rid of at least half of the current entries
            // don't get rid from the middle of a word.
            var rid = m_current / 2
            while rid < m_current && m_buffer[rid].form != .empty {
                rid += 1
            }

            if rid == m_current {
                m_current = -1
            } else {
                rid += 1
                if rid <= m_current {
                    for i in 0...(m_current - rid) {
                        m_buffer[i] = m_buffer[rid + i]
                    }
                    m_current -= rid
                } else {
                    // rid > m_current means we cleared everything
                    m_current = -1
                }
            }
        }

        if m_keyCurrent > 0 && m_keyCurrent + 1 >= m_keyBufSize {
            let rid = m_keyCurrent / 2
            if rid <= m_keyCurrent {
                for i in 0...(m_keyCurrent - rid) {
                    m_keyStrokes[i] = m_keyStrokes[rid + i]
                }
                m_keyCurrent -= rid
            }
        }
    }

    private func writeOutput() {
        // Convert to Unicode
        m_outBuf = []
        for i in m_changePos...m_current {
            if i < 0 { continue }
            let info = m_buffer[i]
            var sym = info.vnSym

            if sym != .nonVnChar {
                 if info.tone > 0 && sym.isVowel {
                     sym = sym.withTone(info.tone)
                 }
                 if info.caps {
                     sym = sym.toUpper
                 }

                 // To Unicode
                 if let u = vnLexiToUnicode[sym] {
                     m_outBuf.append(contentsOf: u.utf16)
                 } else {
                     m_outBuf.append(UInt16(info.keyCode)) // Fallback
                 }
            } else {
                m_outBuf.append(UInt16(info.keyCode))
            }
        }
        m_outputWritten = true
    }

    private func getSeqSteps(_ first: Int, _ last: Int) -> Int {
        if last < first { return 0 }
        // Calculate length of output between first and last
        var len = 0
        for i in first...last {
             let info = m_buffer[i]
             if info.vnSym != .nonVnChar {
                 var sym = info.vnSym
                 if info.tone > 0 && sym.isVowel { sym = sym.withTone(info.tone) }
                 if let u = vnLexiToUnicode[sym] {
                     len += u.utf16.count
                 } else {
                     len += 1
                 }
             } else {
                 len += 1
             }
        }
        return len
    }

    private func markChange(_ pos: Int) {
        if pos < m_changePos {
            m_backs += getSeqSteps(pos, m_changePos - 1)
            m_changePos = pos
        }
    }

    private func getTonePosition(_ vs: VowelSequence, terminated: Bool) -> Int {
        guard let info = getVowelSeqInfo(vs) else { return 0 }

        if info.length == 1 { return 0 }
        if info.roofPosition != -1 { return info.roofPosition }
        if info.hookPosition != -1 {
            if vs == .uhoh || vs == .uhohi || vs == .uhohu { return 1 }
            return info.hookPosition
        }

        if info.length == 3 { return 1 }

        if (m_pCtrl?.options.modernStyle ?? true) {
            if vs == .oa || vs == .oe || vs == .uy { return 1 }
        }

        return terminated ? 0 : 1
    }

    private func synchKeyStrokeBuffer() {
        if m_keyCurrent >= 0 {
            m_keyCurrent -= 1
        }
        if m_current >= 0 && m_buffer[m_current].form == .empty {
            while m_keyCurrent >= 0 && m_keyStrokes[m_keyCurrent].ev.chType != .wordBreak {
                m_keyCurrent -= 1
            }
        }
    }

    private func isValidCV(_ c: ConsonantSequence, _ v: VowelSequence) -> Bool {
        if c == .none || v == .none { return true }
        guard let vInfo = getVowelSeqInfo(v) else { return true }

        if (c == .gi && vInfo.vowels[0] == .i) || (c == .qu && vInfo.vowels[0] == .u) {
            return false
        }

        if c == .k {
            let kVseq: [VowelSequence] = [.e, .i, .y, .er, .eo, .eu, .eru, .ia, .ie, .ier, .ieu, .ieru]
            return kVseq.contains(v)
        }
        return true
    }

    private func isValidVC(_ v: VowelSequence, _ c: ConsonantSequence) -> Bool {
        if v == .none || c == .none { return true }

        guard let vInfo = getVowelSeqInfo(v) else { return true }
        if !vInfo.conSuffix { return false }

        guard let cInfo = getConsonantSeqInfo(c) else { return true }
        if !cInfo.suffix { return false }

        return validVCPairs.contains(VCPair(v: v, c: c))
    }

    private func isValidCVC(_ c1: ConsonantSequence, _ v: VowelSequence, _ c2: ConsonantSequence) -> Bool {
        if v == .none {
            return (c1 == .none || c2 != .none)
        }

        if c1 == .none {
            return isValidVC(v, c2)
        }

        if c2 == .none {
            return isValidCV(c1, v)
        }

        let okCV = isValidCV(c1, v)
        let okVC = isValidVC(v, c2)

        if okCV && okVC {
            return true
        }

        if !okVC {
            // Exceptions
            // quyn, quynh
            if c1 == .qu && v == .y && (c2 == .n || c2 == .nh) {
                return true
            }

            // gieng, gie^ng
            if c1 == .gi && (v == .e || v == .er) && (c2 == .n || c2 == .ng) {
                return true
            }
        }

        return false
    }

}

// Unicode Table
private let vnLexiToUnicode: [VnLexiName: String] = [
    .A: "A", .a: "a", .A1: "\u{00C1}", .a1: "\u{00E1}", .A2: "\u{00C0}", .a2: "\u{00E0}", .A3: "\u{1EA2}", .a3: "\u{1EA3}", .A4: "\u{00C3}", .a4: "\u{00E3}", .A5: "\u{1EA0}", .a5: "\u{1EA1}",
    .Ar: "\u{00C2}", .ar: "\u{00E2}", .Ar1: "\u{1EA4}", .ar1: "\u{1EA5}", .Ar2: "\u{1EA6}", .ar2: "\u{1EA7}", .Ar3: "\u{1EA8}", .ar3: "\u{1EA9}", .Ar4: "\u{1EAA}", .ar4: "\u{1EAB}", .Ar5: "\u{1EAC}", .ar5: "\u{1EAD}",
    .Ab: "\u{0102}", .ab: "\u{0103}", .Ab1: "\u{1EAE}", .ab1: "\u{1EAF}", .Ab2: "\u{1EB0}", .ab2: "\u{1EB1}", .Ab3: "\u{1EB2}", .ab3: "\u{1EB3}", .Ab4: "\u{1EB4}", .ab4: "\u{1EB5}", .Ab5: "\u{1EB6}", .ab5: "\u{1EB7}",
    .E: "E", .e: "e", .E1: "\u{00C9}", .e1: "\u{00E9}", .E2: "\u{00C8}", .e2: "\u{00E8}", .E3: "\u{1EBA}", .e3: "\u{1EBB}", .E4: "\u{1EBC}", .e4: "\u{1EBD}", .E5: "\u{1EB8}", .e5: "\u{1EB9}",
    .Er: "\u{00CA}", .er: "\u{00EA}", .Er1: "\u{1EBE}", .er1: "\u{1EBF}", .Er2: "\u{1EC0}", .er2: "\u{1EC1}", .Er3: "\u{1EC2}", .er3: "\u{1EC3}", .Er4: "\u{1EC4}", .er4: "\u{1EC5}", .Er5: "\u{1EC6}", .er5: "\u{1EC7}",
    .I: "I", .i: "i", .I1: "\u{00CD}", .i1: "\u{00ED}", .I2: "\u{00CC}", .i2: "\u{00EC}", .I3: "\u{1EC8}", .i3: "\u{1EC9}", .I4: "\u{0128}", .i4: "\u{0129}", .I5: "\u{1ECA}", .i5: "\u{1ECB}",
    .O: "O", .o: "o", .O1: "\u{00D3}", .o1: "\u{00F3}", .O2: "\u{00D2}", .o2: "\u{00F2}", .O3: "\u{1ECE}", .o3: "\u{1ECF}", .O4: "\u{00D5}", .o4: "\u{00F5}", .O5: "\u{1ECC}", .o5: "\u{1ECD}",
    .Or: "\u{00D4}", .or: "\u{00F4}", .Or1: "\u{1ED0}", .or1: "\u{1ED1}", .Or2: "\u{1ED2}", .or2: "\u{1ED3}", .Or3: "\u{1ED4}", .or3: "\u{1ED5}", .Or4: "\u{1ED6}", .or4: "\u{1ED7}", .Or5: "\u{1ED8}", .or5: "\u{1ED9}",
    .Oh: "\u{01A0}", .oh: "\u{01A1}", .Oh1: "\u{1EDA}", .oh1: "\u{1EDB}", .Oh2: "\u{1EDC}", .oh2: "\u{1EDD}", .Oh3: "\u{1EDE}", .oh3: "\u{1EDF}", .Oh4: "\u{1EE0}", .oh4: "\u{1EE1}", .Oh5: "\u{1EE2}", .oh5: "\u{1EE3}",
    .U: "U", .u: "u", .U1: "\u{00DA}", .u1: "\u{00FA}", .U2: "\u{00D9}", .u2: "\u{00F9}", .U3: "\u{1EE6}", .u3: "\u{1EE7}", .U4: "\u{0168}", .u4: "\u{0169}", .U5: "\u{1EE4}", .u5: "\u{1EE5}",
    .Uh: "\u{01AF}", .uh: "\u{01B0}", .Uh1: "\u{1EE8}", .uh1: "\u{1EE9}", .Uh2: "\u{1EEA}", .uh2: "\u{1EEB}", .Uh3: "\u{1EEC}", .uh3: "\u{1EED}", .Uh4: "\u{1EEE}", .uh4: "\u{1EEF}", .Uh5: "\u{1EF0}", .uh5: "\u{1EF1}",
    .Y: "Y", .y: "y", .Y1: "\u{00DD}", .y1: "\u{00FD}", .Y2: "\u{1EF2}", .y2: "\u{1EF3}", .Y3: "\u{1EF6}", .y3: "\u{1EF7}", .Y4: "\u{1EF8}", .y4: "\u{1EF9}", .Y5: "\u{1EF4}", .y5: "\u{1EF5}",
    .dd: "\u{0111}", .DD: "\u{0110}",
    .B: "B", .b: "b", .C: "C", .c: "c", .D: "D", .d: "d",
    .F: "F", .f: "f", .G: "G", .g: "g", .H: "H", .h: "h",
    .J: "J", .j: "j", .K: "K", .k: "k", .L: "L", .l: "l", .M: "M", .m: "m", .N: "N", .n: "n",
    .P: "P", .p: "p", .Q: "Q", .q: "q", .R: "R", .r: "r", .S: "S", .s: "s", .T: "T", .t: "t",
    .V: "V", .v: "v", .W: "W", .w: "w", .X: "X", .x: "x", .Z: "Z", .z: "z"
]
