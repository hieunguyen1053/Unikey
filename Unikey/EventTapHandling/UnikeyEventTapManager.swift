// UnikeyEventTapManager.swift
// CGEventTap lifecycle management for Unikey
// Mirrors xim.c main loop and XIM setup (MyForwardEventHandler, initXIM)
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port

import Carbon
import Cocoa

/// CGEventTap manager for Unikey
/// Mirrors xim.c: main event loop and XIM initialization
public class UnikeyEventTapManager {

    // MARK: - Properties

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isEnabled = false
    private var permissionTimer: Timer?

    private let unikey: UnikeyInterface
    private let processor: UnikeyKeyProcessor
    private let committer: UnikeyTextCommitter

    /// Debug callback for logging
    public var debugLogCallback: ((String) -> Void)?

    /// Callback when language is toggled via shortcut (passes new vietnameseEnabled state)
    public var languageToggleCallback: ((Bool) -> Void)?

    // MARK: - Initialization

    public init() {
        self.unikey = UnikeyInterface.shared
        self.processor = UnikeyKeyProcessor(unikey: unikey)
        self.committer = UnikeyTextCommitter()

        // Setup
        unikey.setup()
    }

    deinit {
        stop()
        unikey.cleanup()
    }

    // MARK: - Configuration

    /// Set input method (Telex, VNI, VIQR)
    public func setInputMethod(_ method: UkInputMethod) {
        unikey.setInputMethod(method)
    }

    /// Enable/disable Vietnamese mode
    public var vietnameseEnabled: Bool {
        get { unikey.vietnameseEnabled }
        set { unikey.vietnameseEnabled = newValue }
    }

    // MARK: - Options Properties

    /// Cho phép gõ tự do
    public var freeMarking: Bool {
        get { unikey.freeMarking }
        set { unikey.freeMarking = newValue }
    }

    /// Kiểu đặt dấu mới (hoà, uý) thay vì kiểu cũ (hòa, úy)
    public var modernStyle: Bool {
        get { unikey.modernStyle }
        set { unikey.modernStyle = newValue }
    }

    /// Bật kiểm tra chính tả
    public var spellCheckEnabled: Bool {
        get { unikey.spellCheckEnabled }
        set { unikey.spellCheckEnabled = newValue }
    }

    /// Tự động khôi phục phím với từ sai
    public var autoNonVnRestore: Bool {
        get { unikey.autoNonVnRestore }
        set { unikey.autoNonVnRestore = newValue }
    }

    /// Bật tính năng gõ tắt (macro)
    public var macroEnabled: Bool {
        get { unikey.macroEnabled }
        set { unikey.macroEnabled = newValue }
    }

    /// Cập nhật tất cả options cùng một lúc
    public func updateOptions(
        freeMarking: Bool,
        modernStyle: Bool,
        spellCheckEnabled: Bool,
        autoNonVnRestore: Bool,
        macroEnabled: Bool,
        switchKeyType: Int
    ) {
        unikey.freeMarking = freeMarking
        unikey.modernStyle = modernStyle
        unikey.spellCheckEnabled = spellCheckEnabled
        unikey.autoNonVnRestore = autoNonVnRestore
        unikey.macroEnabled = macroEnabled

        // Update processor switch key type
        if let type = UnikeyKeyProcessor.UnikeySwitchKeyType(
            rawValue: switchKeyType
        ) {
            processor.switchKeyType = type
        }
    }

    // MARK: - Event Tap Lifecycle (mirrors initXIM and main loop)

    /// Start the event tap
    /// Mirrors xim.c: initXIM() and main loop setup
    public func start() throws {
        guard !isEnabled else { return }

        // Check accessibility permission
        guard checkAccessibilityPermission() else {
            debugLogCallback?(
                "No accessibility permission, starting polling..."
            )
            startPermissionPolling()
            throw NSError(
                domain: "UnikeyEventTapManager",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Accessibility permission required"
                ]
            )
        }
        stopPermissionPolling()
        debugLogCallback?("Accessibility permission OK")

        // Create event mask for keyboard events
        // xim.c: filter_mask = KeyPressMask | KeyReleaseMask
        // Create event mask for keyboard events and flags changed
        // xim.c: filter_mask = KeyPressMask | KeyReleaseMask
        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        // Event tap callback
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else {
                return Unmanaged.passUnretained(event)
            }

            let manager = Unmanaged<UnikeyEventTapManager>.fromOpaque(refcon)
                .takeUnretainedValue()

            if let result = manager.eventCallback(
                proxy: proxy,
                type: type,
                event: event
            ) {
                return result
            } else {
                return nil  // Consume event
            }
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        // Create event tap using helper
        guard
            let tap = createEventTap(
                eventMask: eventMask,
                callback: callback,
                userInfo: userInfo
            )
        else {
            debugLogCallback?("Failed to create event tap!")
            throw NSError(
                domain: "UnikeyEventTapManager",
                code: -2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to create event tap"
                ]
            )
        }

        eventTap = tap
        debugLogCallback?("Event tap created")

        // Create run loop source
        runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            tap,
            0
        )

        guard let source = runLoopSource else {
            eventTap = nil
            throw NSError(
                domain: "UnikeyEventTapManager",
                code: -3,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Failed to create run loop source"
                ]
            )
        }

        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        isEnabled = true
        debugLogCallback?("Event tap started!")
    }

    /// Helper to create event tap with HID fallback
    private func createEventTap(
        eventMask: CGEventMask,
        callback: @escaping CGEventTapCallBack,
        userInfo: UnsafeMutableRawPointer?
    ) -> CFMachPort? {
        // Try HID level first (better timing, avoids swallowing in terminals)
        if let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: userInfo
        ) {
            debugLogCallback?("Event tap created at HID level")
            return tap
        }

        debugLogCallback?("HID tap failed, trying session level...")

        // Fallback to session level
        if let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: userInfo
        ) {
            debugLogCallback?("Event tap created at session level")
            return tap
        }

        return nil
    }

    /// Stop the event tap
    public func stop() {
        stopPermissionPolling()
        guard isEnabled else { return }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            eventTap = nil
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }

        isEnabled = false
        debugLogCallback?("Event tap stopped")
    }

    // MARK: - Permission Polling

    private func startPermissionPolling() {
        guard permissionTimer == nil else { return }
        permissionTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
            if self.checkAccessibilityPermission() {
                self.debugLogCallback?(
                    "Permission granted! Starting event tap..."
                )
                try? self.start()
            }
        }
    }

    private func stopPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }

    /// Reset the engine state
    public func reset() {
        unikey.resetBuf()
    }

    /// Check if running
    public var isRunning: Bool {
        return isEnabled
    }

    // MARK: - Event Callback (mirrors MyForwardEventHandler)

    /// Main event callback
    /// Mirrors xim.c: MyForwardEventHandler() (lines 756-785)
    private func eventCallback(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {

        // Skip events injected by Unikey itself
        if event.getIntegerValueField(.eventSourceUserData)
            == UnikeyTextCommitter.eventMarker
        {
            return Unmanaged.passUnretained(event)
        }

        // Handle tap disabled (xim.c handles this implicitly)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        // Monitor flags changed for Cmd+Shift toggle
        if type == .flagsChanged {
            // Only process if switch type is Cmd+Shift
            if processor.switchKeyType == .cmdShift {
                let flags = event.flags
                let code = event.keyCode

                // Check if Cmd and Shift are pressed
                let hasCmd = flags.contains(.maskCommand)
                let hasShift = flags.contains(.maskShift)

                // We toggle when both are pressed, or maybe when one is released after both were pressed.
                // Common behavior: Toggle when the combination is detected.
                // To avoid repeating toggles while holding, we might need state tracking.
                // But for simplicity, let's try toggling when both are present.
                // Optimization: Only toggle if NO other modifiers are pressed (except maybe caps/fn)

                // Check for exact match (Cmd + Shift only)
                // Ignorning AlphaShift (Caps), NumericPad, Help, NonCoalesced
                let relevantFlags: CGEventFlags = [
                    .maskCommand, .maskShift, .maskControl, .maskAlternate,
                ]
                let currentRelevant = flags.intersection(relevantFlags)

                if currentRelevant == [.maskCommand, .maskShift] {
                    // Check if this is the "press" event (flags changed includes press and release)
                    // If we just detected the combo, toggle.
                    // But flagsChanged fires for each key.
                    // 1. Press Cmd -> flags has Cmd
                    // 2. Press Shift -> flags has Cmd+Shift -> Toggle!
                    // 3. Release Shift -> flags has Cmd
                    // 4. Release Cmd -> flags empty

                    // Issue: If user holds Cmd+Shift, auto-repeat doesn't trigger flagsChanged usually.
                    // But if they press Cmd, then Shift, it toggles.
                    // If they press Shift, then Cmd, it toggles.

                    // We need to debounce or ensure we don't toggle repeatedly if valid?
                    // Actually, Windows switcher usually toggles on RELEASE or invalid key?
                    // macOS input source switcher (Cmd+Space) toggles immediately.
                    // Let's toggle immediately.

                    // To prevent double toggle if they press unrelated keys? No, flagsChanged only fires on modifier keys.
                    // But we should track state to only toggle once per press sequence?
                    // For now, let's keep it simple: Toggle.

                    unikey.vietnameseEnabled.toggle()
                    unikey.resetBuf()

                    // Notify AppDelegate to update UI
                    languageToggleCallback?(unikey.vietnameseEnabled)

                    // Debug log
                    debugLogCallback?(
                        "Toggle via Cmd+Shift: \(unikey.vietnameseEnabled ? "VI" : "EN")"
                    )

                    // We generally don't consume flagsChanged events as they affect system state
                    return Unmanaged.passUnretained(event)
                }
            }
            return Unmanaged.passUnretained(event)
        }

        // Only process keyDown events
        // xim.c: if (call_data->event.type != KeyPress) goto forwardEv
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        // Check Vietnamese mode
        // xim.c: if (!GlobalOpt.enabled) goto forwardEv
        guard unikey.vietnameseEnabled else {
            return Unmanaged.passUnretained(event)
        }

        // Get event info
        let flags = event.flags
        let keyCode = event.keyCode

        // Skip if Command or Control pressed (modifiers)
        // xim.c checks for ControlMask | Mod1Mask in char processing
        if flags.contains(.maskCommand) || flags.contains(.maskControl) {
            // Check for shortcuts first
            if processor.isShortcut(keyCode: keyCode, flags: flags) {
                processor.handleShortcut(keyCode: keyCode, flags: flags)
                return nil  // Consume shortcut
            }

            // Check for switch key
            if processor.isSwitchKey(keyCode: keyCode, flags: flags) {
                unikey.vietnameseEnabled.toggle()
                unikey.resetBuf()
                debugLogCallback?(
                    "Vietnamese mode toggled: \(unikey.vietnameseEnabled)"
                )
                return nil  // Consume switch key
            }

            // Reset and pass through
            unikey.resetBuf()
            return Unmanaged.passUnretained(event)
        }

        // Get character
        guard let chars = event.characters, let char = chars.first else {
            return Unmanaged.passUnretained(event)
        }

        debugLogCallback?("Key: '\(char)' keyCode: \(keyCode)")

        // Process through engine
        // Mirrors xim.c: ProcessKey()
        let result = processor.processKey(
            keyCode: keyCode,
            char: char,
            flags: flags
        )

        debugLogCallback?(
            "Result: consumed=\(result.consumed), bs=\(result.backspaces), out='\(result.outputText)'"
        )

        if result.consumed {
            // Inject replacement text
            committer.inject(
                backspaceCount: result.backspaces,
                text: result.outputText,
                proxy: proxy
            )
            return nil  // Consume original event
        }

        // Pass event through
        return Unmanaged.passUnretained(event)
    }

    // MARK: - Permission Check

    /// Check if accessibility permission is granted
    public func checkAccessibilityPermission() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false
        ]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Request accessibility permission
    public func requestAccessibilityPermission() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}

// MARK: - CGEvent Extension

extension CGEvent {
    var characters: String? {
        guard let nsEvent = NSEvent(cgEvent: self) else { return nil }
        return nsEvent.characters
    }

    var keyCode: UInt16 {
        return UInt16(getIntegerValueField(.keyboardEventKeycode))
    }
}
