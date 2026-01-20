// UniKeyInputController.swift
// macOS Input Method Controller using InputMethodKit
// Unikey Vietnamese Input Method

import Cocoa
import InputMethodKit

/// Main Input Method Controller
/// Handles keyboard events and produces Vietnamese text output
@objc(UniKeyInputController)
public class UniKeyInputController: IMKInputController {

  // MARK: - Properties

  /// The Unikey engine instance
  private let engine = UkEngine()

  /// Composing text (text being built before commit)
  private var composingText: String = ""

  /// Whether we're in Vietnamese mode
  private var vietnameseMode: Bool = true

  // MARK: - Initialization

  public override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
    super.init(server: server, delegate: delegate, client: inputClient)

    // Default to Telex input method
    engine.setInputMethod(.telex)
  }

  // MARK: - IMKInputController Override

  /// Main event handler - processes keyboard input
  public override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
    guard let event = event, event.type == .keyDown else {
      return false
    }

    // Don't process if not in Vietnamese mode
    guard vietnameseMode else {
      return false
    }

    // Get the client for text input
    guard let client = sender as? IMKTextInput else {
      return false
    }

    // Check for special keys
    let keyCode = event.keyCode
    let modifiers = event.modifierFlags

    // Pass through if Command or Control is pressed (shortcuts)
    if modifiers.contains(.command) || modifiers.contains(.control) {
      commitComposing(client: client)
      return false
    }

    // Handle backspace
    if keyCode == 51 {  // Backspace key code
      return handleBackspace(client: client)
    }

    // Handle Enter, Tab, Escape - commit and pass through
    if keyCode == 36 || keyCode == 48 || keyCode == 53 {  // Enter, Tab, Escape
      commitComposing(client: client)
      return false
    }

    // Handle Space - commit current word
    if keyCode == 49 {  // Space
      commitComposing(client: client)
      // Let space through
      return false
    }

    // Get character from event
    guard let chars = event.characters, let char = chars.first else {
      return false
    }

    // Process through engine
    return processCharacter(char, keyCode: UInt32(keyCode), client: client)
  }

  /// Handle backspace key
  private func handleBackspace(client: IMKTextInput) -> Bool {
    if composingText.isEmpty {
      // Let system handle normal backspace
      engine.reset()
      return false
    }

    let result = engine.processBackspace()

    if !composingText.isEmpty {
      composingText.removeLast()

      // Update marked text
      client.setMarkedText(
        composingText as NSString,
        selectionRange: NSRange(location: composingText.count, length: 0),
        replacementRange: NSRange(location: NSNotFound, length: 0)
      )
    }

    return true
  }

  /// Process a character through the Unikey engine
  private func processCharacter(_ char: Character, keyCode: UInt32, client: IMKTextInput) -> Bool {
    let result = engine.process(keyCode: keyCode, char: char)

    if result.handled {
      // Update composing text
      if result.backspaceCount > 0 && composingText.count >= result.backspaceCount {
        // Remove characters that need to be replaced
        composingText.removeLast(result.backspaceCount)
      }

      // Add new output
      composingText += result.output

      // Set marked text (composing state)
      client.setMarkedText(
        composingText as NSString,
        selectionRange: NSRange(location: composingText.count, length: 0),
        replacementRange: NSRange(location: NSNotFound, length: 0)
      )

      return true
    }

    return false
  }

  /// Commit the composing text to the client
  private func commitComposing(client: IMKTextInput) {
    if !composingText.isEmpty {
      client.insertText(
        composingText as NSString,
        replacementRange: NSRange(location: NSNotFound, length: 0)
      )
      composingText = ""
      engine.reset()
    }
  }

  // MARK: - IMKStateSetting Protocol

  public override func activateServer(_ sender: Any!) {
    super.activateServer(sender)
    engine.reset()
    composingText = ""
  }

  public override func deactivateServer(_ sender: Any!) {
    if let client = sender as? IMKTextInput {
      commitComposing(client: client)
    }
    super.deactivateServer(sender)
  }

  // MARK: - Menu Actions

  /// Toggle Vietnamese mode
  @objc public func toggleVietnameseMode() {
    vietnameseMode.toggle()
    engine.reset()
    composingText = ""
  }

  /// Switch to Telex input method
  @objc public func switchToTelex() {
    engine.setInputMethod(.telex)
    engine.reset()
  }

  /// Switch to VNI input method
  @objc public func switchToVNI() {
    engine.setInputMethod(.vni)
    engine.reset()
  }

  /// Switch to VIQR input method
  @objc public func switchToVIQR() {
    engine.setInputMethod(.viqr)
    engine.reset()
  }
}

// MARK: - IMKTextInput Extension (Type-safe casting)

extension IMKTextInput {
  /// Safe method to insert text
  func safeInsertText(_ text: String) {
    self.insertText(text as NSString, replacementRange: NSRange(location: NSNotFound, length: 0))
  }
}
