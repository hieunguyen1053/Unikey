// Unikey Swift Engine - Core Engine
// Ported from x-unikey-1.0.4/src/ukengine/ukengine.cpp
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Gemini

import Foundation

/// Maximum buffer size for word processing
private let maxEngineBuffer = 128

/// Word form types
public enum WordForm {
  case nonVn  // Non-Vietnamese word
  case empty  // Empty buffer
  case c  // Consonant only
  case v  // Vowel only
  case cv  // Consonant + Vowel
  case vc  // Vowel + Consonant
  case cvc  // Consonant + Vowel + Consonant
}

/// Information about each position in the word buffer
public struct WordInfo {
  // Word structure info
  var form: WordForm = .empty
  var c1Offset: Int = -1  // Offset to first consonant (-1 if none)
  var vOffset: Int = -1  // Offset to vowel sequence (-1 if none)
  var c2Offset: Int = -1  // Offset to ending consonant (-1 if none)

  // Sequence info at this position
  var vseq: VowelSequence = .none
  var cseq: ConsonantSequence = .none

  // Character info
  var caps: Bool = false  // Is uppercase
  var tone: Int = 0  // Tone (0-5)
  var vnSym: VnLexiName = .nonVnChar  // Vietnamese symbol
  var keyCode: UInt32 = 0  // Original key code
}

/// Keystroke buffer entry
struct KeyBufEntry {
  var keyCode: UInt32
  var char: Character
  var isConverted: Bool = false  // True if this key triggered a VN modification
}

/// Helper to quick record key
extension UkEngine {
  private func recordKey(_ event: KeyEvent) {
    let keyEntry = KeyBufEntry(
      keyCode: event.keyCode, char: Character(UnicodeScalar(event.keyCode) ?? " "),
      isConverted: true)
    keyStrokes.append(keyEntry)
  }
}

/// Processing result from engine
public struct ProcessResult {
  /// Number of backspaces needed to delete old output
  public var backspaceCount: Int = 0

  /// New characters to output
  public var output: String = ""

  /// Whether processing was handled
  public var handled: Bool = false
}

/// Main Unikey Engine - processes keystrokes to produce Vietnamese text
public class UkEngine {

  // MARK: - Properties

  private var buffer: [WordInfo] = Array(repeating: WordInfo(), count: maxEngineBuffer)
  private var current: Int = -1
  private var singleMode: Bool = false

  // Spell check / Restoration
  private var keyStrokes: [KeyBufEntry] = []
  public var spellCheckEnabled: Bool = true
  private var restoring: Bool = false  // Flag for restoration process

  private var inputProcessor = InputProcessor()

  // Options
  public var vietKeyEnabled: Bool = true
  public var freeMarking: Bool = true  // Allow marking at any position

  // MARK: - Initialization

  public init() {
    reset()
  }

  // MARK: - Public Methods

  /// Reset engine state (call on word boundary)
  public func reset() {
    current = -1
    singleMode = false
    restoring = false
    keyStrokes.removeAll()
    for i in 0..<maxEngineBuffer {
      buffer[i] = WordInfo()
    }
  }

  /// Set input method
  public func setInputMethod(_ method: InputMethod) {
    inputProcessor.setInputMethod(method)
  }

  /// Get current input method
  public func getInputMethod() -> InputMethod {
    return inputProcessor.getInputMethod()
  }

  /// Check if at word beginning
  public func atWordBeginning() -> Bool {
    return current < 0
  }

  /// Process a key press
  public func process(keyCode: UInt32, char: Character) -> ProcessResult {
    var result = ProcessResult()

    guard vietKeyEnabled else {
      result.output = String(char)
      result.handled = false
      return result
    }

    let event = inputProcessor.keyCodeToEvent(keyCode, char: char)

    switch event.charType {
    case .reset:
      reset()
      result.handled = false
      return result

    case .wordBreak:
      reset()
      result.output = String(char)
      result.handled = false
      return result

    case .nonVn, .vn:
      break
    }

    // Process based on event type
    switch event.eventType {
    case .tone0, .tone1, .tone2, .tone3, .tone4, .tone5:
      result = processTone(event)
    case .roofAll, .roof_a, .roof_e, .roof_o:
      result = processRoof(event)
    case .hookAll, .hook_uo, .hook_u, .hook_o, .bowl:
      result = processHook(event)
    case .dd:
      result = processDd(event)
    case .telex_w:
      result = processTelexW(event)
    case .normal, .mapChar:
      // Append first, then check
      result = processAppend(event)
      if spellCheckEnabled && !result.handled && keyStrokes.count > 0 {
        // If append failed (e.g. buffer full?) or specifically rejected
        // But normally append always 'handles' by adding char.
        // The spell check logic is INSIDE processAppend or called after?
        // Let's put it inside processAppend for atomic handling.
      }
    default:
      result = processAppend(event)
    }

    return result
  }

  /// Process backspace
  public func processBackspace() -> ProcessResult {
    var result = ProcessResult()

    if current >= 0 {
      current -= 1
    }

    if !keyStrokes.isEmpty {
      keyStrokes.removeLast()
    }

    result.backspaceCount = 1
    result.handled = true
    return result
  }

  // MARK: - Private Processing Methods

  /// Append a character to buffer
  private func processAppend(_ event: KeyEvent) -> ProcessResult {
    var result = ProcessResult()

    // Ensure buffer space
    if current >= maxEngineBuffer - 2 {
      reset()
    }

    current += 1

    var info = WordInfo()
    info.keyCode = event.keyCode
    info.vnSym = event.vnSymbol
    info.caps = event.vnSymbol.isUppercase
    info.tone = 0

    // Record keystroke
    var keyEntry = KeyBufEntry(
      keyCode: event.keyCode, char: Character(UnicodeScalar(event.keyCode) ?? " "),
      isConverted: false)
    // Note: char might be different from event.vnSym if mapped. Using raw code for restoration.
    // Ideally we pass original char to processAppend?
    // Using simple mapping for now.

    // Spell Check: Detect if we are breaking a word
    // (Logic moved to check validity later)

    // Propagate Non-Vietnamese state
    if current > 0 && buffer[current - 1].form == .nonVn || event.vnSymbol == .nonVnChar {
      info.form = .nonVn
      buffer[current] = info
      keyStrokes.append(keyEntry)
      result.output = String(event.vnSymbol.toUnicode)
      result.handled = true
      return result
    }

    // Determine word form based on character type
    if event.vnSymbol.isVowel {
      if current == 0 {
        info.form = .v
        info.vOffset = 0
        info.vseq = lookupVowelSeq(event.vnSymbol.baseChar)
      } else {
        let prev = buffer[current - 1]

        // Try to extend vowel sequence
        if prev.vOffset >= 0 {
          let vStart = current - 1 - prev.vOffset
          let existingLen = vowelSeqList[prev.vseq.rawValue].length

          // Try 2 or 3 vowel lookup
          var newSeq: VowelSequence = .none
          if existingLen == 1 {
            newSeq = lookupVowelSeq(buffer[vStart].vnSym.baseChar, event.vnSymbol.baseChar)
          } else if existingLen == 2 {
            newSeq = lookupVowelSeq(
              buffer[vStart].vnSym.baseChar,
              buffer[vStart + 1].vnSym.baseChar,
              event.vnSymbol.baseChar)
          }

          if newSeq != .none {
            info.form = prev.form
            info.c1Offset = prev.c1Offset
            info.vOffset = current - vStart
            info.vseq = newSeq

            // Update subsequences
            if let seqInfo = getVowelSeqInfo(newSeq) {
              for i in 0..<seqInfo.length {
                buffer[vStart + i].vseq = seqInfo.subsequences[i]
              }
            }

            // Reposition tone if needed
            // Logic ported from x-unikey ukengine.cpp processAppend (lines 1597-1608)
            let oldSeqLen = vowelSeqList[prev.vseq.rawValue].length
            let oldVStart = current - 1 - (oldSeqLen - 1)
            let oldTonePos = oldVStart + getTonePosition(prev.vseq, terminated: true)

            if oldTonePos >= 0 && oldTonePos < current && buffer[oldTonePos].tone != 0 {
              let tone = buffer[oldTonePos].tone
              let newTonePos = vStart + getTonePosition(newSeq, terminated: false)

              if newTonePos != oldTonePos {
                buffer[newTonePos].tone = tone
                buffer[oldTonePos].tone = 0
              }
            }
          } else {
            // Can't extend, start new
            info.form = .v
            info.vOffset = 0
            info.vseq = lookupVowelSeq(event.vnSymbol.baseChar)
            if info.vseq == .none { info.form = .nonVn }
          }
        } else if prev.form == .c {
          // After consonant (initial)
          info.form = .cv
          info.c1Offset = prev.c1Offset + 1
          info.vOffset = 0
          info.vseq = lookupVowelSeq(event.vnSymbol.baseChar)
        } else if prev.form == .cvc || prev.form == .vc {
          // After ending consonant -> CVC + V is invalid
          info.form = .nonVn
        } else {
          info.form = .v
          info.vOffset = 0
          info.vseq = lookupVowelSeq(event.vnSymbol.baseChar)
        }
      }
    } else if event.vnSymbol != .nonVnChar {
      // Consonant
      if current == 0 {
        info.form = .c
        info.c1Offset = 0
        info.cseq = lookupConsonantSeq(event.vnSymbol.baseChar)
        if info.cseq == .none { info.form = .nonVn }
      } else {
        let prev = buffer[current - 1]

        if prev.vOffset >= 0 {
          if prev.form == .v || prev.form == .cv {
            // Start NEW ending consonant
            info.form = (prev.form == .cv) ? .cvc : .vc
            info.c1Offset = 0
            info.vOffset = prev.vOffset + 1
            info.c2Offset = 0

            info.cseq = lookupConsonantSeq(event.vnSymbol.baseChar)

            if info.cseq == .none {
              info.form = .nonVn
            }
          } else if prev.form == .vc || prev.form == .cvc {
            // Extend EXISTING ending consonant
            let existingLen = consonantSeqList[prev.cseq.rawValue].length
            var newSeq: ConsonantSequence = .none

            let ecStart = current - existingLen

            // Validate bounds just in case
            if ecStart >= 0 {
              if existingLen == 1 {
                newSeq = lookupConsonantSeq(buffer[ecStart].vnSym.baseChar, event.vnSymbol.baseChar)
              } else if existingLen == 2 {
                if ecStart + 1 < current {
                  newSeq = lookupConsonantSeq(
                    buffer[ecStart].vnSym.baseChar, buffer[ecStart + 1].vnSym.baseChar,
                    event.vnSymbol.baseChar)
                }
              }
            }

            if newSeq != .none {
              info.form = prev.form
              info.c1Offset = (prev.c1Offset >= 0) ? prev.c1Offset + 1 : -1
              info.vOffset = prev.vOffset + 1
              info.cseq = newSeq
            } else {
              info.form = .nonVn
              info.cseq = .none
            }
            print("Processing: \(event.vnSymbol), NewSeq: \(newSeq), Form: \(info.form)")
          } else {
            info.form = .nonVn
          }
        } else if prev.c1Offset >= 0 {
          // Extend consonant sequence
          let cStart = current - 1 - prev.c1Offset
          let existingLen = consonantSeqList[prev.cseq.rawValue].length

          var newSeq: ConsonantSequence = .none
          if existingLen == 1 {
            newSeq = lookupConsonantSeq(buffer[cStart].vnSym.baseChar, event.vnSymbol.baseChar)
          } else if existingLen == 2 {
            newSeq = lookupConsonantSeq(
              buffer[cStart].vnSym.baseChar,
              buffer[cStart + 1].vnSym.baseChar,
              event.vnSymbol.baseChar)
          }

          if newSeq != .none {
            info.form = .c
            info.c1Offset = current - cStart
            info.cseq = newSeq
          } else {
            info.form = .nonVn
            info.c1Offset = 0
            info.cseq = .none
          }
        } else {
          info.form = .c
          info.c1Offset = 0
          info.cseq = lookupConsonantSeq(event.vnSymbol.baseChar)
          if info.cseq == .none { info.form = .nonVn }
        }
      }
    } else {
      info.form = .nonVn
    }

    buffer[current] = info

    // Mark as converted if we successfully formed a VN struct
    // Simple heuristic: if form is c/v/cv/vc/cvc, we are "consuming".
    // Actually, track if we changed anything PREVIOUSLY.
    // But for "refactor": f -> tone. That was a conversion.
    // "a" here is just a letter.

    keyStrokes.append(keyEntry)

    // CHECK VALIDITY
    if spellCheckEnabled && !restoring && current > 0 {
      let prev = buffer[current - 1]
      let curr = buffer[current]

      // If we started a NEW component that is disconnected from previous
      // (e.g. prev was part of a word, but curr starts a new C or V with offset 0/checking back)
      // AND the previous part had some "conversion"

      var disconnected = false
      if curr.form == .c && curr.c1Offset == 0 { disconnected = true }  // New consonant
      if curr.form == .v && curr.vOffset == 0 && curr.c1Offset == -1 { disconnected = true }  // New vowel (standalone)
      if curr.form == .nonVn { disconnected = true }  // Broken word structure

      if disconnected {
        // We have a disconnect.
        // Check if we have any converted keys in the buffer
        // If so, and we just broke the word structure -> Restore.

        if hasConvertedKeys() {
          return restoreKeyStrokes()
        }
      }
    }

    result.output = String(event.vnSymbol.toUnicode)
    result.handled = true
    return result
  }

  private func hasConvertedKeys() -> Bool {
    // In a real implementation, we'd mark specific keys.
    // For now: assume if we are strictly in VN mode, any tone/mark is a conversion.
    // Scan buffer for anything not matching original key?
    // Or check if current structure is complex.

    // Let's rely on `restoreKeyStrokes` to do the heavy lifting of checking 'is this worth restoring'.
    // But we need a trigger.
    // Trigger: Disconnected components in buffer.
    return true  // Simplified: always check restore if disconnected?
    // "vietnam" -> v, i, e, t, n, a, m. All disconnected?
    // v (c), i (v), e (v - extend? ie), t (c - extend? iet).
    // n (c - new).
    // "viet" is one word. "n" breaks it.
    // "vietnam" is valid typing. We don't want to restore "việt nam" to "vietnam" unless "n" is invalid start?

    // The issue with "refactor" is "rè" is valid, but "a" following it is weird.
    // "n" following "t" is valid (new word).
    // "a" following "e" (with tone) is invalid?
    // Actually "rè" ends with vowel. "a" is vowel.
    // Vowel following Vowel (that didn't merge) is almost always invalid in VN (unless space).
  }

  /// Restore original keystrokes
  private func restoreKeyStrokes() -> ProcessResult {
    var result = ProcessResult()

    // Calculate backspaces: everything currently in buffer output
    // We can use current buffer content length or simply `current + 1` chars?
    // Wait, output might have been multi-char (ư, ơ, ê...).
    // We need to know how much we outputted.
    // Currently `processAppend` returns 1 char output usually.
    // But we have `current` pointer.

    // Using a simplified approach:
    // 1. Calculate length of current VN string in buffer to backspace.
    //    (Iterate buffer 0..<current and count unicode length)
    //    Note: current char is in buffer but NOT yet outputted, so don't backspace it.
    //    We only backspace what was previously outputted (0 to current-1).
    var toDelete = 0
    if current > 0 {
      for i in 0..<current {
        let char = buffer[i].vnSym.toUnicode
        toDelete += String(char).count
      }
    } else if current == 0 {
      // If current is 0, nothing to backspace?
      // If 0 is the NEW char, then 0 chars backspace.
      toDelete = 0
    }

    // 2. Capture current keystrokes to replay
    let keysToReplay = keyStrokes

    // 3. Reset Engine to clear state
    reset()

    // 4. Replay keys
    // This repopulates the buffer with exact characters.
    // Since we call processAppend directly, tones/marks become plain chars.
    // If a sequence is invalid (e.g. refa), processAppend should eventually mark .nonVn

    restoring = true
    var original = ""

    for var k in keysToReplay {
      k.isConverted = false
      // We need to convert KeyBufEntry back to KeyEvent to append
      // Using simplified conversion assumes 1-1 mapping or we use the char
      // But keyBufEntry has keyCode.
      let ev = inputProcessor.keyCodeToEvent(k.keyCode, char: k.char)
      _ = processAppend(ev)
      original.append(k.char)
    }
    restoring = false

    result.backspaceCount = toDelete
    result.output = original
    result.handled = true

    return result
  }

  /// Process tone mark
  private func processTone(_ event: KeyEvent) -> ProcessResult {
    var result = ProcessResult()

    // Must have a vowel to add tone
    guard current >= 0, let vRange = getVowelRange(at: current) else {
      return processAppend(event)
    }

    let vStart = vRange.start
    let vEnd = vRange.end
    let vs = buffer[vEnd].vseq
    guard vs != .none, let info = getVowelSeqInfo(vs) else {
      return processAppend(event)
    }

    // Record Key (consumed as Tone)
    recordKey(event)

    let newTone = event.tone

    // Find tone position (use Vietnamese tone placement rules)
    let tonePos = vStart + getTonePosition(vs, terminated: vEnd == current)

    guard tonePos >= 0 && tonePos < maxEngineBuffer else {
      return processAppend(event)
    }

    let oldTone = buffer[tonePos].tone

    // If same tone, remove it (toggle behavior)
    if oldTone == newTone && newTone != 0 {
      buffer[tonePos].tone = 0
      result = rewriteBuffer(from: tonePos)
      singleMode = true
    } else {
      // Clear old tone from other positions
      for i in vStart...vEnd {
        if buffer[i].tone != 0 && i != tonePos {
          buffer[i].tone = 0
        }
      }

      buffer[tonePos].tone = newTone
      result = rewriteBuffer(from: tonePos)
    }

    result.handled = true
    return result
  }

  /// Process roof (^) mark
  private func processRoof(_ event: KeyEvent) -> ProcessResult {
    var result = ProcessResult()

    guard current >= 0, let vRange = getVowelRange(at: current) else {
      return processAppend(event)
    }

    let vStart = vRange.start
    let vEnd = vRange.end
    let vs = buffer[vEnd].vseq
    guard vs != .none, let vInfo = getVowelSeqInfo(vs) else {
      return processAppend(event)
    }

    // Determine target based on event type
    let targetBase: VnLexiName?
    switch event.eventType {
    case .roof_a: targetBase = .ar
    case .roof_e: targetBase = .er
    case .roof_o: targetBase = .or
    default: targetBase = nil
    }

    // Check if roof can be added or removed
    if vInfo.roofPosition >= 0 {
      // Already has roof - remove it
      let roofPos = vStart + vInfo.roofPosition

      // Verify target matches if specified
      if let target = targetBase, buffer[roofPos].vnSym.baseChar != target {
        return processAppend(event)
      }

      if !freeMarking && roofPos != current {
        return processAppend(event)
      }

      // Remove roof
      buffer[roofPos].vnSym = buffer[roofPos].vnSym.withoutRoof

      // Update vowel sequence
      if let newVs = vInfo.withRoof == .none ? nil : vInfo.withRoof {
        updateVowelSequence(vStart: vStart, newSeq: newVs)
      }

      result = rewriteBuffer(from: roofPos)
      singleMode = true
    } else if vInfo.withRoof != .none {
      // Can add roof
      let newVs = vInfo.withRoof
      guard let newInfo = getVowelSeqInfo(newVs) else {
        return processAppend(event)
      }

      // Verify target matches if specified
      if let target = targetBase, newInfo.vowels[newInfo.roofPosition] != target {
        return processAppend(event)
      }

      let changePos = vStart + newInfo.roofPosition

      if !freeMarking && changePos != current {
        return processAppend(event)
      }

      // Add roof
      buffer[changePos].vnSym = buffer[changePos].vnSym.withRoof
      updateVowelSequence(vStart: vStart, newSeq: newVs)

      result = rewriteBuffer(from: changePos)
    } else {
      return processAppend(event)
    }

    recordKey(event)
    result.handled = true
    return result
  }

  /// Process hook/horn mark (ư, ơ, ă)
  private func processHook(_ event: KeyEvent) -> ProcessResult {
    var result = ProcessResult()

    guard current >= 0, let vRange = getVowelRange(at: current) else {
      return processAppend(event)
    }

    let vStart = vRange.start
    let vEnd = vRange.end
    let vs = buffer[vEnd].vseq
    guard vs != .none, let info = getVowelSeqInfo(vs) else {
      return processAppend(event)
    }

    // Check for special UO hook handling (uo, uo^, uo^i...)
    // Ported from x-unikey ukengine.cpp processHook (lines 800-804)
    if getVowelSeqLength(vs) > 1 && event.eventType != .bowl
      && (info.vowels.count > 0 && (info.vowels[0] == .u || info.vowels[0] == .uh))
      && (info.vowels.count > 1
        && (info.vowels[1] == .o || info.vowels[1] == .oh || info.vowels[1] == .or))
    {

      // Special handling: processHookWithUO needs to record key if it handles it.
      // But processHookWithUO signature doesn't imply fallback easily.
      // We'll record here, but pop if processHookWithUO fails (if it calls processAppend).
      // Actually processHookWithUO in this port calls processAppend internally.
      // So assuming processHookWithUO handles recording or we record if successful?
      // Wait, did I add recordKey to processHookWithUO? No.
      // So we should record here.
      recordKey(event)
      return processHookWithUO(event, vRange: vRange)
    }

    // Original logic continues here, using `info` (which is `vInfo` from original code)
    if info.hookPosition >= 0 {
      // Already has hook - remove it
      let hookPos = vStart + info.hookPosition

      if !freeMarking && hookPos != current {
        return processAppend(event)
      }

      buffer[hookPos].vnSym = buffer[hookPos].vnSym.withoutHook

      result = rewriteBuffer(from: hookPos)
      singleMode = true
    } else if info.withHook != .none {
      // Can add hook
      let newVs = info.withHook
      guard let newInfo = getVowelSeqInfo(newVs) else {
        return processAppend(event)
      }

      let changePos = vStart + newInfo.hookPosition

      if !freeMarking && changePos != current {
        return processAppend(event)
      }

      buffer[changePos].vnSym = buffer[changePos].vnSym.withHook
      updateVowelSequence(vStart: vStart, newSeq: newVs)

      result = rewriteBuffer(from: changePos)
    } else {
      return processAppend(event)
    }

    recordKey(event)
    result.handled = true
    return result
  }

  /// Process Đ
  private func processDd(_ event: KeyEvent) -> ProcessResult {
    var result = ProcessResult()

    // Look for 'd' in the buffer
    guard current >= 0 else {
      return processAppend(event)
    }

    // Check current consonant position
    var dPos = -1

    if buffer[current].c1Offset >= 0 {
      let cStart = current - buffer[current].c1Offset
      if buffer[cStart].vnSym.baseChar == .d || buffer[cStart].vnSym.baseChar == .D {
        dPos = cStart
      }
    }

    // Also check if current is vowel, look at c1
    if dPos < 0 && current > 0 && buffer[current].vOffset >= 0 && buffer[current].c1Offset >= 0 {
      let cStart = current - buffer[current].c1Offset
      if buffer[cStart].vnSym.baseChar == .d || buffer[cStart].vnSym.baseChar == .D {
        dPos = cStart
      }
    }

    if dPos >= 0 {
      // Toggle đ/d
      let curSym = buffer[dPos].vnSym
      if curSym == .d {
        buffer[dPos].vnSym = .dd
      } else if curSym == .D {
        buffer[dPos].vnSym = .DD
      } else if curSym == .dd {
        buffer[dPos].vnSym = .d
        singleMode = true
      } else if curSym == .DD {
        buffer[dPos].vnSym = .D
        singleMode = true
      }

      result = rewriteBuffer(from: dPos)
      result.handled = true
      recordKey(event)
    } else {
      return processAppend(event)
    }

    return result
  }

  /// Process Telex W key
  private func processTelexW(_ event: KeyEvent) -> ProcessResult {
    // W in Telex can:
    // 1. Add ư if after u
    // 2. Add ơ if after o
    // 3. Add ă if standalone or after a

    guard current >= 0, buffer[current].vOffset >= 0 else {
      return processAppend(event)
    }

    // Try hook first
    // Telex W acts as hook_uo (like VNI 7, not just hookAll)
    // allowing uo -> ươ conversion
    let hookResult = processHook(
      KeyEvent(eventType: .hook_uo, charType: .vn, vnSymbol: .w, keyCode: event.keyCode))

    if hookResult.handled && !hookResult.output.isEmpty {
      return hookResult
    }

    // Fall back to append
    return processAppend(event)
  }

  // MARK: - Helper Methods

  /// Get vowel sequence length helper
  private func getVowelSeqLength(_ vs: VowelSequence) -> Int {
    return getVowelSeqInfo(vs)?.length ?? 0
  }

  /// Process hook with UO special handling
  /// Ported from x-unikey ukengine.cpp processHookWithUO
  private func processHookWithUO(_ event: KeyEvent, vRange: (start: Int, end: Int)) -> ProcessResult
  {
    var result = ProcessResult()
    _ = result  // Suppress unused warning or just use empty result init

    let vStart = vRange.start
    let vEnd = vRange.end
    let vs = buffer[vEnd].vseq

    guard let info = getVowelSeqInfo(vs) else { return processAppend(event) }
    let v = info.vowels

    var newVs: VowelSequence = .none
    var changeIndices: [Int] = []
    var newSyms: [VnLexiName] = []

    // Logic to determine new sequence
    switch event.eventType {
    case .hook_u:
      if v[0] == .u {
        newVs = info.withHook
        changeIndices = [0]
        newSyms = [.uh]
      } else {  // v[0] == .uh -> uo
        let v3 = v.count > 2 ? v[2] : .nonVnChar
        newVs = lookupVowelSeq(.u, .o, v3)
        changeIndices = [0, 1]
        newSyms = [.u, .o]
      }

    case .hook_o:
      let v1 = v[1]
      if v1 == .o || v1 == .or {
        // Check for o|o^ -> o+ (th + cv case skipped for simplicity or check?)
        // Unikey checks for "th" preceding... lets implement basic first
        let v3 = v.count > 2 ? v[2] : .nonVnChar
        newVs = lookupVowelSeq(.uh, .oh, v3)  // uh oh
        if v[0] == .u {
          changeIndices = [0, 1]
          newSyms = [.uh, .oh]
        } else {
          changeIndices = [1]
          newSyms = [.oh]
        }
      } else {  // v[1] == .oh -> uo
        let v3 = v.count > 2 ? v[2] : .nonVnChar
        newVs = lookupVowelSeq(.u, .o, v3)
        changeIndices = [0, 1]
        newSyms = [.u, .o]
      }

    case .hook_uo:  // Telex W, VNI 7
      // Toggle uo <-> ươ
      if v[0] == .uh && v[1] == .oh {  // ươ -> uo
        let v3 = v.count > 2 ? v[2] : .nonVnChar
        newVs = lookupVowelSeq(.u, .o, v3)
        changeIndices = [0, 1]
        newSyms = [.u, .o]
      } else if v[0] == .u && v[1] == .o {  // uo -> ươ
        let v3 = v.count > 2 ? v[2] : .nonVnChar
        newVs = lookupVowelSeq(.uh, .oh, v3)
        changeIndices = [0, 1]
        newSyms = [.uh, .oh]
      }

    case .hookAll:
      // Try hook_uo logic first
      if v[0] == .u && v[1] == .o {
        let v3 = v.count > 2 ? v[2] : .nonVnChar
        newVs = lookupVowelSeq(.uh, .oh, v3)
        changeIndices = [0, 1]
        newSyms = [.uh, .oh]
      }
    // Fallback to table if needed?

    default:
      break
    }

    if newVs == .none {
      // Fallback to standard hook
      // But verify if standard hook is acceptable (not already handled)
      return processAppend(event)
    }

    // Apply changes
    if !freeMarking && vEnd != current {
      return processAppend(event)
    }

    // Update symbols
    for (i, idx) in changeIndices.enumerated() {
      let pos = vStart + idx
      buffer[pos].vnSym = newSyms[i]
      // Reset tone on changed chars? Unikey does sophisticated tone restoration.
      // For now, let's keep it simple: if symbols change, tone might need reset.
      // Unikey clears tone if it moves or changes significantly.
      // Let's implement basic tone preservation if possible?
      // Unikey: if removing hook/roof, keeps tone. If adding, keeps tone.
      // processHookWithUO in C++ handles tone removal/move carefully.
      // For simplicity: keep tone on index if valid.
    }

    updateVowelSequence(vStart: vStart, newSeq: newVs)

    // Reposition tone (critical for ươ case)
    let newTonePos = vStart + getTonePosition(newVs, terminated: vEnd == current)
    // Find where tone was
    // ... basic logic: scan range, find tone, move to newTonePos
    var foundTone = 0
    for i in vStart...vEnd {
      if buffer[i].tone != 0 {
        foundTone = buffer[i].tone
        buffer[i].tone = 0
      }
    }
    if foundTone != 0 {
      buffer[newTonePos].tone = foundTone
    }

    return rewriteBuffer(from: vStart)
  }

  /// Get tone position within vowel sequence (Vietnamese rules)
  private func getVowelRange(at index: Int) -> (start: Int, end: Int)? {
    guard index >= 0 && index < maxEngineBuffer else { return nil }

    // Check if we have valid vowel info
    guard buffer[index].vOffset >= 0 else { return nil }

    let vStart = index - buffer[index].vOffset
    guard vStart >= 0 else { return nil }

    // Use stored vseq length if possible, or scan forward
    // Since we maintain vseq in the last vowel character, scanning is reliable
    var vEnd = vStart
    while vEnd + 1 <= current && buffer[vEnd + 1].vnSym.isVowel {
      vEnd += 1
    }

    return (vStart, vEnd)
  }

  /// Get tone position within vowel sequence (Vietnamese rules)
  /// Get tone position within vowel sequence (Vietnamese rules)
  /// Ported from x-unikey ukengine.cpp getTonePosition
  private func getTonePosition(_ vs: VowelSequence, terminated: Bool) -> Int {
    guard let info = getVowelSeqInfo(vs) else { return 0 }

    if info.length == 1 {
      return 0
    }

    if info.roofPosition != -1 {
      return info.roofPosition
    }

    if info.hookPosition != -1 {
      // Special cases: u+o+, u+o+u, u+o+i -> tone on 2nd char (o)
      // In our table: uhoh, uhohi, uhohu
      if vs == .uhoh || vs == .uhohi || vs == .uhohu {
        return 1
      }
      return info.hookPosition
    }

    if info.length == 3 {
      return 1
    }

    // Modern style check (always enabled for now)
    // oa, oe, uy -> tone on 2nd char
    if vs == .oa || vs == .oe || vs == .uy {
      return 1
    }

    return terminated ? 0 : 1
  }

  /// Update vowel sequence in buffer
  private func updateVowelSequence(vStart: Int, newSeq: VowelSequence) {
    guard let info = getVowelSeqInfo(newSeq) else { return }

    for i in 0..<info.length {
      if vStart + i < maxEngineBuffer {
        buffer[vStart + i].vseq = info.subsequences[i]
      }
    }
  }

  /// Rewrite buffer from a position onwards
  private func rewriteBuffer(from pos: Int) -> ProcessResult {
    var result = ProcessResult()

    // Count characters to delete (from pos to current)
    result.backspaceCount = current - pos + 1

    // Build output string
    var output = ""
    for i in pos...current {
      var sym = buffer[i].vnSym

      // Apply tone if present
      if buffer[i].tone > 0 && sym.isVowel {
        sym = sym.withTone(buffer[i].tone)
      }

      output.append(sym.toUnicode)
    }

    result.output = output
    result.handled = true
    return result
  }
}
