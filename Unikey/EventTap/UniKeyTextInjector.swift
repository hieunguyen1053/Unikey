// UniKeyTextInjector.swift
// Injects Vietnamese text into the system
// Simplified version based on MLKey CharacterInjector

import Carbon
import Cocoa

class UniKeyTextInjector {

  // MARK: - Properties

  private var eventSource: CGEventSource?
  var debugCallback: ((String) -> Void)?

  // MARK: - Initialization

  init() {
    eventSource = CGEventSource(stateID: .privateState)
  }

  // MARK: - Public Methods

  /// Inject text replacement: backspaces + new text
  func inject(backspaceCount: Int, text: String, proxy: CGEventTapProxy) {
    // Recreate event source for each injection
    eventSource = CGEventSource(stateID: .privateState)

    debugCallback?("Inject: bs=\(backspaceCount), text='\(text)'")

    // Step 1: Send backspaces
    for i in 0..<backspaceCount {
      sendBackspace(proxy: proxy)
      usleep(2000)  // 2ms delay
      debugCallback?("  → Backspace \(i + 1)/\(backspaceCount)")
    }

    // Wait after backspaces
    if backspaceCount > 0 {
      usleep(5000)  // 5ms wait
    }

    // Step 2: Send new text
    if !text.isEmpty {
      sendText(text, proxy: proxy)
    }

    // Settle time
    usleep(5000)
  }

  // MARK: - Private Methods

  private func sendBackspace(proxy: CGEventTapProxy) {
    guard let source = eventSource else { return }

    let deleteKeyCode: CGKeyCode = 0x33  // Backspace

    guard
      let keyDown = CGEvent(keyboardEventSource: source, virtualKey: deleteKeyCode, keyDown: true),
      let keyUp = CGEvent(keyboardEventSource: source, virtualKey: deleteKeyCode, keyDown: false)
    else {
      return
    }

    // Mark as Unikey-injected event
    keyDown.setIntegerValueField(.eventSourceUserData, value: kUnikeyEventMarker)
    keyUp.setIntegerValueField(.eventSourceUserData, value: kUnikeyEventMarker)

    keyDown.tapPostEvent(proxy)
    keyUp.tapPostEvent(proxy)
  }

  private func sendText(_ text: String, proxy: CGEventTapProxy) {
    guard let source = eventSource else { return }

    debugCallback?("  → Sending text: '\(text)'")

    // Send text one character at a time for best compatibility
    for (index, char) in text.enumerated() {
      var utf16 = Array(String(char).utf16)

      guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
      else {
        continue
      }

      keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
      keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)

      // Mark as Unikey-injected event
      keyDown.setIntegerValueField(.eventSourceUserData, value: kUnikeyEventMarker)
      keyUp.setIntegerValueField(.eventSourceUserData, value: kUnikeyEventMarker)

      keyDown.tapPostEvent(proxy)
      keyUp.tapPostEvent(proxy)

      debugCallback?("  → Sent char [\(index)]: '\(char)'")

      // Small delay between characters
      usleep(1000)
    }
  }
}
