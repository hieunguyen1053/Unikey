// UnikeyKeyProcessor.swift
// Main key processing logic for Unikey
// Mirrors xim.c: ProcessKey(), isShortcut(), isSwitchKey(), Forward_Keys
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port

import Carbon
import Cocoa

/// Result of key processing
public struct ProcessKeyResult {
  /// Whether the key was consumed (don't pass to application)
  public var consumed: Bool

  /// Number of backspaces to send before output
  public var backspaces: Int

  /// Output text to inject
  public var outputText: String

  /// Whether pending commit is waiting
  public var pendingCommit: Bool

  public init(
    consumed: Bool = false, backspaces: Int = 0, outputText: String = "",
    pendingCommit: Bool = false
  ) {
    self.consumed = consumed
    self.backspaces = backspaces
    self.outputText = outputText
    self.pendingCommit = pendingCommit
  }
}

/// Main key processor
/// Mirrors xim.c: ProcessKey() and related functions
public class UnikeyKeyProcessor {

  // MARK: - Special Key Codes (macOS)

  private struct KeyCode {
    static let backspace: UInt16 = 0x33  // 51
    static let returnKey: UInt16 = 0x24  // 36
    static let tab: UInt16 = 0x30  // 48
    static let escape: UInt16 = 0x35  // 53
    static let space: UInt16 = 0x31  // 49
  }

  // MARK: - Forward Keys (xim.c lines 218-223)
  // Keys that should reset state and be forwarded

  private let forwardKeyCodes: Set<UInt16> = [
    0x24,  // Return
    0x30,  // Tab
    0x75,  // Delete (forward delete)
  ]

  // MARK: - Properties

  private let unikey: UnikeyInterface
  private let state: UnikeyState

  /// Debug callback for logging
  public var debugCallback: ((String) -> Void)?

  // MARK: - Initialization

  public init(unikey: UnikeyInterface) {
    self.unikey = unikey
    self.state = unikey.state
  }

  // MARK: - Main Processing (xim.c lines 610-753: ProcessKey)

  /// Process a key event
  /// Mirrors xim.c: ProcessKey()
  public func processKey(keyCode: UInt16, char: Character?, flags: CGEventFlags) -> ProcessKeyResult
  {
    let charValue = char?.asciiValue.map { UInt32($0) }
    let charStr = char.map { String($0) } ?? "nil"

    debugCallback?(
      "ProcessKey: keyCode=\(keyCode), char='\(charStr)', flags=\(flags.rawValue)")

    // Handle special keys

    // Backspace (xim.c lines 624-659)
    if keyCode == KeyCode.backspace {
      return processBackspace()
    }

    // Forward keys - reset and pass through (xim.c lines 773-776)
    if isForwardKey(keyCode) {
      debugCallback?("Forward key detected, resetting state")
      unikey.resetBuf()
      return ProcessKeyResult(consumed: false)
    }

    // Space handling - special case in xim.c
    // Space is processed through the engine
    if keyCode == KeyCode.space {
      // Let engine handle space
      if let cv = charValue {
        return processRegularKey(charValue: cv, flags: flags)
      }
      return ProcessKeyResult(consumed: false)
    }

    // Regular character processing
    if let cv = charValue {
      // Check for pending commit handling (xim.c lines 686-693)
      if state.postponeKeyEv && state.postponeCount < 50 {
        state.postponeCount += 1
        debugCallback?("Postponing key event, count=\(state.postponeCount)")
        // In macOS we don't actually postpone, just process
      }

      return processRegularKey(charValue: cv, flags: flags)
    }

    // Non-character key - check if it should reset state
    if !isModifierKey(keyCode) {
      debugCallback?("Non-character key, resetting state")
      unikey.resetBuf()
    }

    return ProcessKeyResult(consumed: false)
  }

  // MARK: - Regular Key Processing (xim.c lines 694-752)

  private func processRegularKey(charValue: UInt32, flags: CGEventFlags) -> ProcessKeyResult {
    // Set caps state (xim.c line 696)
    let shiftPressed = flags.contains(.maskShift)
    let capsLockOn = flags.contains(.maskAlphaShift)
    unikey.setCapsState(shiftPressed: shiftPressed, capsLockOn: capsLockOn)

    // Filter through engine (xim.c line 702: UnikeyFilter)
    unikey.filter(charValue)

    // Check results
    let backspaces = unikey.ukBackspaces
    let bufChars = unikey.ukBufChars
    let buffer = unikey.ukBuffer

    debugCallback?("Engine result: backspaces=\(backspaces), bufChars=\(bufChars)")

    // If backspaces needed (xim.c lines 703-726)
    if backspaces > 0 || bufChars > 0 {
      let outputText = bufChars > 0 ? String(utf16CodeUnits: buffer, count: bufChars) : ""

      // Decide commit method
      // xim.c has two methods: UkForwardCommit and UkSendCommit
      // We use forward commit style (simpler for macOS)
      return ProcessKeyResult(
        consumed: true,
        backspaces: backspaces,
        outputText: outputText,
        pendingCommit: false
      )
    }

    // Triggering mode - commit the key itself (xim.c lines 727-732)
    if state.ukTriggering {
      let charStr = String(UnicodeScalar(charValue) ?? UnicodeScalar(0))
      return ProcessKeyResult(
        consumed: true,
        backspaces: 0,
        outputText: charStr,
        pendingCommit: false
      )
    }

    // No transformation needed - pass through
    return ProcessKeyResult(consumed: false)
  }

  // MARK: - Backspace Processing (xim.c lines 624-659)

  private func processBackspace() -> ProcessKeyResult {
    // If pending commit, this might be a fake backspace (xim.c lines 653-657)
    if state.pendingCommit {
      debugCallback?("Fake backspace during pending commit")
      return ProcessKeyResult(consumed: false)
    }

    // Process through engine
    unikey.backspacePress()

    let backspaces = unikey.ukBackspaces
    let bufChars = unikey.ukBufChars
    let buffer = unikey.ukBuffer

    debugCallback?("Backspace result: backspaces=\(backspaces), bufChars=\(bufChars)")

    // If engine modified the buffer (xim.c lines 630-651)
    if backspaces > 0 {
      let outputText = bufChars > 0 ? String(utf16CodeUnits: buffer, count: bufChars) : ""

      return ProcessKeyResult(
        consumed: true,
        backspaces: backspaces,
        outputText: outputText,
        pendingCommit: false
      )
    }

    // Just buffer content, no extra backspaces
    if bufChars > 0 {
      let outputText = String(utf16CodeUnits: buffer, count: bufChars)
      return ProcessKeyResult(
        consumed: true,
        backspaces: 0,
        outputText: outputText,
        pendingCommit: false
      )
    }

    // Let system handle backspace normally
    return ProcessKeyResult(consumed: false)
  }

  // MARK: - Key Classification

  /// Check if key is a forward key (reset state and pass through)
  /// Mirrors xim.c: Forward_Keys (lines 218-223)
  public func isForwardKey(_ keyCode: UInt16) -> Bool {
    return forwardKeyCodes.contains(keyCode)
  }

  /// Check if key is a switch key (toggle Vietnamese mode)
  /// Mirrors xim.c: isSwitchKey() (lines 370-405)
  public func isSwitchKey(keyCode: UInt16, flags: CGEventFlags) -> Bool {
    // Control+Shift or Alt+Shift toggles Vietnamese mode
    // Original xim.c checks for Shift_L/Shift_R with Control or Alt modifier

    // For macOS, we use Control+Space or similar
    // This is a simplified version
    if keyCode == KeyCode.space && flags.contains(.maskControl) {
      return true
    }

    return false
  }

  /// Check if key is a shortcut
  /// Mirrors xim.c: isShortcut() (lines 408-489)
  public func isShortcut(keyCode: UInt16, flags: CGEventFlags) -> Bool {
    // Shortcuts in xim.c are Ctrl+Shift+F1..F9, etc.
    // For macOS, we can implement similar shortcuts

    // Check for Control+Shift modifier
    let ctrlShift = flags.contains(.maskControl) && flags.contains(.maskShift)
    if !ctrlShift {
      return false
    }

    // F1-F9 for various shortcuts
    // F1: Unicode charset, F2: VIQR, F3: TCVN, F4: VNI
    // F5: Telex input, F6: VNI input, F7: VIQR input
    // F9: Switch
    switch keyCode {
    case 0x7A:  // F1
      return true  // Switch to Unicode
    case 0x78:  // F2
      return true  // Switch to VIQR
    case 0x63:  // F3
      return true  // Switch to TCVN
    case 0x76:  // F4
      return true  // Switch to VNI charset
    case 0x60:  // F5
      return true  // Switch to Telex
    case 0x61:  // F6
      return true  // Switch to VNI input
    case 0x62:  // F7
      return true  // Switch to VIQR input
    case 0x65:  // F9
      return true  // Toggle switch
    default:
      return false
    }
  }

  /// Handle a shortcut key
  public func handleShortcut(keyCode: UInt16, flags: CGEventFlags) {
    let ctrlShift = flags.contains(.maskControl) && flags.contains(.maskShift)
    guard ctrlShift else { return }

    switch keyCode {
    case 0x60:  // F5 - Telex
      unikey.setInputMethod(.telex)
      debugCallback?("Switched to Telex input")
    case 0x61:  // F6 - VNI
      unikey.setInputMethod(.vni)
      debugCallback?("Switched to VNI input")
    case 0x62:  // F7 - VIQR
      unikey.setInputMethod(.viqr)
      debugCallback?("Switched to VIQR input")
    case 0x65:  // F9 - Toggle
      state.vietnameseEnabled.toggle()
      unikey.resetBuf()
      debugCallback?("Vietnamese mode: \(state.vietnameseEnabled ? "ON" : "OFF")")
    default:
      break
    }
  }

  /// Check if key is a modifier key
  private func isModifierKey(_ keyCode: UInt16) -> Bool {
    switch keyCode {
    case 0x38, 0x3C:  // Shift L/R
      return true
    case 0x3B, 0x3E:  // Control L/R
      return true
    case 0x3A, 0x3D:  // Option/Alt L/R
      return true
    case 0x37, 0x36:  // Command L/R
      return true
    case 0x39:  // Caps Lock
      return true
    case 0x3F:  // Fn
      return true
    default:
      return false
    }
  }
}
