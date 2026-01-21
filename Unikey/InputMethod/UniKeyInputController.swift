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

    /// Shared memory for engine state
    private let sharedMem = UkSharedMem()

    /// Whether we're in Vietnamese mode
    private var vietnameseMode: Bool = true

    /// Debug logging enabled
    private let debugLog: Bool = true

    // MARK: - Initialization

    public override init!(
        server: IMKServer!,
        delegate: Any!,
        client inputClient: Any!
    ) {
        super.init(server: server, delegate: delegate, client: inputClient)

        // Initialize engine
        engine.setCtrlInfo(sharedMem)

        // Default to Telex input method
        sharedMem.input.setIM(.telex)
        log("UniKeyInputController initialized with Telex")
    }

    // MARK: - Debug Logging

    private func log(_ message: String) {
        if debugLog {
            NSLog("Unikey: \(message)")
        }
    }

    // MARK: - IMKInputController Override

    /// Main event handler - processes keyboard input
    public override func handle(_ event: NSEvent!, client sender: Any!) -> Bool
    {
        // Log the event
        log(
            "handle() called - type: \(event != nil ? Int(event!.type.rawValue) : -1)"
        )

        guard let event = event else {
            log("Event is nil")
            return false
        }

        guard event.type == .keyDown else {
            log("Not keyDown event, type: \(event.type.rawValue)")
            return false
        }

        // Don't process if not in Vietnamese mode
        guard vietnameseMode else {
            log("Vietnamese mode disabled")
            return false
        }

        // Get the client for text input
        guard let client = sender as? IMKTextInput else {
            log("Cannot get IMKTextInput client")
            return false
        }

        // Check for special keys
        let keyCode = event.keyCode
        let modifiers = event.modifierFlags
        let chars = event.characters ?? ""

        log(
            "KeyDown - keyCode: \(keyCode), chars: '\(chars)', modifiers: \(modifiers.rawValue)"
        )

        // Pass through if Command or Control is pressed (shortcuts)
        if modifiers.contains(.command) || modifiers.contains(.control) {
            log("Modifier key pressed, passing through")
            engine.reset()
            return false
        }

        // Handle backspace
        if keyCode == 51 {  // Backspace key code
            log("Backspace pressed")
            if processBackspace(client: client) {
                return true
            }
            return false  // Let system handle backspace
        }

        // Handle Enter, Tab, Escape - reset and pass through
        if keyCode == 36 || keyCode == 48 || keyCode == 53 {  // Enter, Tab, Escape
            log("Enter/Tab/Escape pressed, resetting engine")
            engine.reset()
            return false
        }

        // Handle Space - reset and pass through
        if keyCode == 49 {  // Space
            log("Space pressed, resetting engine")
            engine.reset()
            return false
        }

        // Get character from event
        guard let char = chars.first else {
            log("No character in event")
            return false
        }

        // Process through engine
        return processCharacter(char, keyCode: UInt32(keyCode), client: client)
    }

    /// Process backspace through engine
    private func processBackspace(client: IMKTextInput) -> Bool {
        var backs: Int = 0
        var outBuf: [UInt16] = []
        var outSize: Int = 0
        var outType: UkOutputType = .normal

        let ret = engine.processBackspace(&backs, &outBuf, &outSize, &outType)

        if ret != 0 {
            let output = String(utf16CodeUnits: outBuf, count: outSize)
            applyChanges(client: client, backspaceCount: backs, output: output)
            return true
        }
        return false
    }

    /// Process a character through the Unikey engine
    private func processCharacter(
        _ char: Character,
        keyCode: UInt32,
        client: IMKTextInput
    ) -> Bool {
        log("Processing character: '\(char)' keyCode: \(keyCode)")

        var backs: Int = 0
        var outBuf: [UInt16] = []
        var outSize: Int = 0
        var outType: UkOutputType = .normal

        let ret = engine.process(keyCode, &backs, &outBuf, &outSize, &outType)

        let output = String(utf16CodeUnits: outBuf, count: outSize)

        log(
            "Engine result - handled: \(ret != 0), backspaces: \(backs), output: '\(output)'"
        )

        if ret != 0 {
            applyChanges(client: client, backspaceCount: backs, output: output)
            return true
        }

        log("Not handled by engine, returning false")
        return false
    }

    private func applyChanges(
        client: IMKTextInput,
        backspaceCount: Int,
        output: String
    ) {
        // If we need to replace characters (backspace then insert)
        if backspaceCount > 0 {
            // Delete previous characters
            for _ in 0..<backspaceCount {
                // Send backspace to delete previous character
                sendBackspace(client: client)
            }
        }

        // Insert new text directly
        if !output.isEmpty {
            log("Inserting text: '\(output)'")
            client.insertText(
                output as NSString,
                replacementRange: NSRange(location: NSNotFound, length: 0)
            )
        }
    }

    /// Send a backspace key event
    private func sendBackspace(client: IMKTextInput) {
        // Try to get selected range and delete previous character
        log("sendBackspace called")

        let sel = client.selectedRange()
        if sel.location != NSNotFound && sel.location > 0 {
            let deleteRange = NSRange(location: sel.location - 1, length: 1)
            client.insertText("" as NSString, replacementRange: deleteRange)
            log("Deleted character at position \(sel.location - 1)")
        }
    }

    // MARK: - IMKStateSetting Protocol

    public override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        log("Server activated")
        engine.reset()
    }

    public override func deactivateServer(_ sender: Any!) {
        log("Server deactivating")
        engine.reset()
        super.deactivateServer(sender)
    }

    // MARK: - Input Mode

    public override func recognizedEvents(_ sender: Any!) -> Int {
        // We want to receive key down events
        let events = Int(NSEvent.EventTypeMask.keyDown.rawValue)
        log("recognizedEvents() returning: \(events)")
        return events
    }

    // MARK: - Menu Actions

    /// Toggle Vietnamese mode
    @objc public func toggleVietnameseMode() {
        vietnameseMode.toggle()
        engine.reset()
        log("Vietnamese mode toggled: \(vietnameseMode)")
    }

    /// Switch to Telex input method
    @objc public func switchToTelex() {
        sharedMem.input.setIM(.telex)
        engine.reset()
        log("Switched to Telex")
    }

    /// Switch to VNI input method
    @objc public func switchToVNI() {
        sharedMem.input.setIM(.vni)
        engine.reset()
        log("Switched to VNI")
    }

    /// Switch to VIQR input method
    @objc public func switchToVIQR() {
        sharedMem.input.setIM(.viqr)
        engine.reset()
        log("Switched to VIQR")
    }
}

// MARK: - NSRange Extension

extension NSRange {
    func toRange() -> Range<Int>? {
        guard location != NSNotFound else { return nil }
        return location..<(location + length)
    }
}
