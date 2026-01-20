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
      result = processAppend(event)
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
          } else {
            // Can't extend, start new
            info.form = .v
            info.vOffset = 0
            info.vseq = lookupVowelSeq(event.vnSymbol.baseChar)
          }
        } else if prev.c1Offset >= 0 {
          // After consonant
          info.form = .cv
          info.c1Offset = prev.c1Offset + 1
          info.vOffset = 0
          info.vseq = lookupVowelSeq(event.vnSymbol.baseChar)
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
      } else {
        let prev = buffer[current - 1]

        if prev.vOffset >= 0 {
          // After vowel - ending consonant
          info.form = (prev.c1Offset >= 0) ? .cvc : .vc
          info.c1Offset = prev.c1Offset >= 0 ? prev.c1Offset + 1 : -1
          info.vOffset = prev.vOffset + 1
          info.c2Offset = 0
          info.vseq = prev.vseq
          info.cseq = lookupConsonantSeq(event.vnSymbol.baseChar)
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
            // Start new consonant
            info.form = .c
            info.c1Offset = 0
            info.cseq = lookupConsonantSeq(event.vnSymbol.baseChar)
          }
        } else {
          info.form = .c
          info.c1Offset = 0
          info.cseq = lookupConsonantSeq(event.vnSymbol.baseChar)
        }
      }
    } else {
      // Non-Vietnamese character
      info.form = .nonVn
    }

    buffer[current] = info

    result.output = String(event.vnSymbol.toUnicode)
    result.handled = true
    return result
  }

  /// Process tone mark
  private func processTone(_ event: KeyEvent) -> ProcessResult {
    var result = ProcessResult()

    // Must have a vowel to add tone
    guard current >= 0, buffer[current].vOffset >= 0 else {
      return processAppend(event)
    }

    let vEnd = current - buffer[current].vOffset
    let vs = buffer[vEnd].vseq
    guard vs != .none, let vInfo = getVowelSeqInfo(vs) else {
      return processAppend(event)
    }

    let vStart = vEnd - (vInfo.length - 1)
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

    guard current >= 0, buffer[current].vOffset >= 0 else {
      return processAppend(event)
    }

    let vEnd = current - buffer[current].vOffset
    let vs = buffer[vEnd].vseq
    guard vs != .none, let vInfo = getVowelSeqInfo(vs) else {
      return processAppend(event)
    }

    let vStart = vEnd - (vInfo.length - 1)

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

    result.handled = true
    return result
  }

  /// Process hook/horn mark (ư, ơ, ă)
  private func processHook(_ event: KeyEvent) -> ProcessResult {
    var result = ProcessResult()

    guard current >= 0, buffer[current].vOffset >= 0 else {
      return processAppend(event)
    }

    let vEnd = current - buffer[current].vOffset
    let vs = buffer[vEnd].vseq
    guard vs != .none, let vInfo = getVowelSeqInfo(vs) else {
      return processAppend(event)
    }

    let vStart = vEnd - (vInfo.length - 1)

    if vInfo.hookPosition >= 0 {
      // Already has hook - remove it
      let hookPos = vStart + vInfo.hookPosition

      if !freeMarking && hookPos != current {
        return processAppend(event)
      }

      buffer[hookPos].vnSym = buffer[hookPos].vnSym.withoutHook

      result = rewriteBuffer(from: hookPos)
      singleMode = true
    } else if vInfo.withHook != .none {
      // Can add hook
      let newVs = vInfo.withHook
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
    let hookResult = processHook(
      KeyEvent(eventType: .hookAll, charType: .vn, vnSymbol: .w, keyCode: event.keyCode))

    if hookResult.handled && !hookResult.output.isEmpty {
      return hookResult
    }

    // Fall back to append
    return processAppend(event)
  }

  // MARK: - Helper Methods

  /// Get tone position within vowel sequence (Vietnamese rules)
  private func getTonePosition(_ vs: VowelSequence, terminated: Bool) -> Int {
    guard let info = getVowelSeqInfo(vs) else { return 0 }

    // Vietnamese tone placement rules:
    // 1. If single vowel: on that vowel
    // 2. If double vowel ending word: on first vowel
    // 3. If double vowel with ending consonant: on second vowel
    // 4. If triple vowel: on middle vowel

    switch info.length {
    case 1:
      return 0
    case 2:
      // If word continues (has consonant suffix), tone on second vowel
      // If word ends, tone on first vowel with some exceptions
      if terminated {
        // Check for "oa", "oe", "uy" rules
        if vs == .oa || vs == .oab || vs == .oe {
          return 1  // tone on 'a' or 'e'
        }
        if vs == .uy {
          return 1  // tone on 'y'
        }
        return 0  // default: first vowel
      } else {
        return 1  // with consonant suffix: second vowel
      }
    case 3:
      return 1  // middle vowel
    default:
      return 0
    }
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
