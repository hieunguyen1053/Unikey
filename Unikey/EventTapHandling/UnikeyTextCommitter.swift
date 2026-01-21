// UnikeyTextCommitter.swift
// Text injection for Unikey - commit and backspace operations
// Mirrors xim.c: forwardBackspaces(), sendBackspaces(), commitBuf(), commitString()
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port

import Carbon
import Cocoa

/// Handles text injection for Unikey
/// Based on xim.c text commitment functions
public class UnikeyTextCommitter {

    // MARK: - Constants

    /// Event marker to identify Unikey-injected events
    /// Prevents re-processing of our own events
    public static let eventMarker: Int64 = 0x554E_494B  // "UNIK" in hex

    // MARK: - Properties

    private var eventSource: CGEventSource?

    /// Debug callback for logging
    public var debugCallback: ((String) -> Void)?

    // MARK: - Initialization

    public init() {
        eventSource = CGEventSource(stateID: .privateState)
    }

    // MARK: - Public Methods

    /// Forward backspaces to application
    /// Mirrors xim.c: forwardBackspaces() (lines 492-509)
    /// Uses IMForwardEvent style - direct forwarding
    public func forwardBackspaces(count: Int, proxy: CGEventTapProxy) {
        guard count > 0 else { return }

        debugCallback?("forwardBackspaces: count=\(count)")

        for i in 0..<count {
            sendBackspaceEvent(proxy: proxy)
            usleep(2000)  // 2ms delay between backspaces
            debugCallback?("  → Backspace \(i + 1)/\(count)")
        }
    }

    /// Send backspaces using XSendEvent style
    /// Mirrors xim.c: sendBackspaces() (lines 512-535)
    /// Sends KeyPress events only (as in original)
    public func sendBackspaces(count: Int, proxy: CGEventTapProxy) {
        guard count > 0 else { return }

        debugCallback?("sendBackspaces: count=\(count)")

        for i in 0..<count {
            sendBackspaceEvent(proxy: proxy, keyUpToo: false)
            usleep(2000)
            debugCallback?("  → SendBackspace \(i + 1)/\(count)")
        }
    }

    /// Commit a buffer of text
    /// Mirrors xim.c: commitBuf() (lines 570-607)
    public func commitBuffer(buffer: [UInt16], proxy: CGEventTapProxy) {
        guard !buffer.isEmpty else { return }

        let text = String(utf16CodeUnits: buffer, count: buffer.count)
        debugCallback?("commitBuffer: '\(text)' (\(buffer.count) chars)")

        commitString(text, proxy: proxy)
    }

    /// Commit a string
    /// Mirrors xim.c: commitString() (lines 558-567)
    public func commitString(_ text: String, proxy: CGEventTapProxy) {
        guard !text.isEmpty else { return }

        debugCallback?("commitString: '\(text)'")

        // Create fresh event source for each commit
        eventSource = CGEventSource(stateID: .privateState)

        // Send each character
        for (index, char) in text.enumerated() {
            sendCharacter(char, proxy: proxy)
            usleep(1000)  // 1ms between characters
            debugCallback?("  → Sent char [\(index)]: '\(char)'")
        }
    }

    /// Send a commit signal (for pending commit flow)
    /// Mirrors xim.c: sendCommit() (lines 538-555)
    public func sendCommit(proxy: CGEventTapProxy) {
        // In xim.c this sends a special COMMIT_KEYSYM (F12)
        // For macOS, we don't need this - we handle commit state differently
        debugCallback?("sendCommit called")
    }

    /// Combined injection: backspaces + text
    /// Convenience method combining backspace and text injection
    public func inject(
        backspaceCount: Int,
        text: String,
        proxy: CGEventTapProxy
    ) {
        debugCallback?("inject: bs=\(backspaceCount), text='\(text)'")

        // Recreate event source
        eventSource = CGEventSource(stateID: .privateState)

        // Step 1: Send backspaces
        if backspaceCount > 0 {
            forwardBackspaces(count: backspaceCount, proxy: proxy)
            usleep(5000)  // 5ms wait after backspaces
        }

        // Step 2: Send text
        if !text.isEmpty {
            commitString(text, proxy: proxy)
        }

        // Settle time
        usleep(5000)
    }

    // MARK: - Private Methods

    /// Send a single backspace key event
    private func sendBackspaceEvent(
        proxy: CGEventTapProxy,
        keyUpToo: Bool = true
    ) {
        guard let source = eventSource else { return }

        let backspaceKeyCode: CGKeyCode = 0x33  // Backspace key code

        guard
            let keyDown = CGEvent(
                keyboardEventSource: source,
                virtualKey: backspaceKeyCode,
                keyDown: true
            )
        else {
            return
        }

        // Mark as Unikey event
        keyDown.setIntegerValueField(
            .eventSourceUserData,
            value: UnikeyTextCommitter.eventMarker
        )
        keyDown.tapPostEvent(proxy)

        if keyUpToo {
            guard
                let keyUp = CGEvent(
                    keyboardEventSource: source,
                    virtualKey: backspaceKeyCode,
                    keyDown: false
                )
            else {
                return
            }
            keyUp.setIntegerValueField(
                .eventSourceUserData,
                value: UnikeyTextCommitter.eventMarker
            )
            keyUp.tapPostEvent(proxy)
        }
    }

    /// Send a single character
    private func sendCharacter(_ char: Character, proxy: CGEventTapProxy) {
        guard let source = eventSource else { return }

        var utf16 = Array(String(char).utf16)

        guard
            let keyDown = CGEvent(
                keyboardEventSource: source,
                virtualKey: 0,
                keyDown: true
            ),
            let keyUp = CGEvent(
                keyboardEventSource: source,
                virtualKey: 0,
                keyDown: false
            )
        else {
            return
        }

        keyDown.keyboardSetUnicodeString(
            stringLength: utf16.count,
            unicodeString: &utf16
        )
        keyUp.keyboardSetUnicodeString(
            stringLength: utf16.count,
            unicodeString: &utf16
        )

        // Mark as Unikey events
        keyDown.setIntegerValueField(
            .eventSourceUserData,
            value: UnikeyTextCommitter.eventMarker
        )
        keyUp.setIntegerValueField(
            .eventSourceUserData,
            value: UnikeyTextCommitter.eventMarker
        )

        keyDown.tapPostEvent(proxy)
        keyUp.tapPostEvent(proxy)
    }
}
