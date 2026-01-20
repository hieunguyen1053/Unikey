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

  private let unikey: UnikeyInterface
  private let processor: UnikeyKeyProcessor
  private let committer: UnikeyTextCommitter

  /// Debug callback for logging
  public var debugLogCallback: ((String) -> Void)?

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

  // MARK: - Event Tap Lifecycle (mirrors initXIM and main loop)

  /// Start the event tap
  /// Mirrors xim.c: initXIM() and main loop setup
  public func start() throws {
    guard !isEnabled else { return }

    // Check accessibility permission
    guard checkAccessibilityPermission() else {
      debugLogCallback?("No accessibility permission")
      throw NSError(
        domain: "UnikeyEventTapManager",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Accessibility permission required"]
      )
    }
    debugLogCallback?("Accessibility permission OK")

    // Create event mask for keyboard events
    // xim.c: filter_mask = KeyPressMask | KeyReleaseMask
    let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

    // Event tap callback
    let callback: CGEventTapCallBack = { proxy, type, event, refcon in
      guard let refcon = refcon else {
        return Unmanaged.passUnretained(event)
      }

      let manager = Unmanaged<UnikeyEventTapManager>.fromOpaque(refcon).takeUnretainedValue()

      if let result = manager.eventCallback(proxy: proxy, type: type, event: event) {
        return result
      } else {
        return nil  // Consume event
      }
    }

    let userInfo = Unmanaged.passUnretained(self).toOpaque()

    // Create event tap
    guard
      let tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: eventMask,
        callback: callback,
        userInfo: userInfo
      )
    else {
      debugLogCallback?("Failed to create event tap!")
      throw NSError(
        domain: "UnikeyEventTapManager",
        code: -2,
        userInfo: [NSLocalizedDescriptionKey: "Failed to create event tap"]
      )
    }

    eventTap = tap
    debugLogCallback?("Event tap created")

    // Create run loop source
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

    guard let source = runLoopSource else {
      eventTap = nil
      throw NSError(
        domain: "UnikeyEventTapManager",
        code: -3,
        userInfo: [NSLocalizedDescriptionKey: "Failed to create run loop source"]
      )
    }

    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)

    isEnabled = true
    debugLogCallback?("Event tap started!")
  }

  /// Stop the event tap
  public func stop() {
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
    if event.getIntegerValueField(.eventSourceUserData) == UnikeyTextCommitter.eventMarker {
      return Unmanaged.passUnretained(event)
    }

    // Handle tap disabled (xim.c handles this implicitly)
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      if let tap = eventTap {
        CGEvent.tapEnable(tap: tap, enable: true)
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
        debugLogCallback?("Vietnamese mode toggled: \(unikey.vietnameseEnabled)")
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
    let result = processor.processKey(keyCode: keyCode, char: char, flags: flags)

    debugLogCallback?(
      "Result: consumed=\(result.consumed), bs=\(result.backspaces), out='\(result.outputText)'")

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
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

  /// Request accessibility permission
  public func requestAccessibilityPermission() {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
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
