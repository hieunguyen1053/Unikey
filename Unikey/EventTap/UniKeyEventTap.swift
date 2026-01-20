// UniKeyEventTap.swift
// Simplified CGEventTap for Unikey - based on MLKey
// Uses Event Tap instead of InputMethodKit

import Carbon
import Cocoa

// Event marker to prevent re-processing of injected events
let kUnikeyEventMarker: Int64 = 0x554E_494B  // "UNIK" in hex

class UniKeyEventTap {

  // MARK: - Properties

  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var isEnabled = false

  private let engine = UkEngine()
  private let sharedMem = UkSharedMem()
  private let injector = UniKeyTextInjector()

  var debugLogCallback: ((String) -> Void)?
  var vietnameseEnabled = true

  // MARK: - Initialization

  init() {
    sharedMem.input.setIM(.telex)
    sharedMem.vietKey = 1
    engine.setCtrlInfo(sharedMem)
  }

  deinit {
    stop()
  }

  // MARK: - Public Methods

  func setInputMethod(_ method: UkInputMethod) {
    sharedMem.input.setIM(method)
  }

  func start() throws {
    guard !isEnabled else { return }

    // Check accessibility permission
    guard checkAccessibilityPermission() else {
      debugLogCallback?("No accessibility permission")
      throw NSError(
        domain: "UniKeyEventTap", code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Accessibility permission required"])
    }
    debugLogCallback?("Accessibility permission OK")

    // Create event mask for keyboard events
    let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

    // Callback closure for event tap
    let callback: CGEventTapCallBack = { proxy, type, event, refcon in
      guard let refcon = refcon else {
        return Unmanaged.passUnretained(event)
      }

      let manager = Unmanaged<UniKeyEventTap>.fromOpaque(refcon).takeUnretainedValue()

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
        domain: "UniKeyEventTap", code: -2,
        userInfo: [NSLocalizedDescriptionKey: "Failed to create event tap"])
    }

    eventTap = tap
    debugLogCallback?("Event tap created")

    // Create run loop source
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

    guard let source = runLoopSource else {
      eventTap = nil
      throw NSError(
        domain: "UniKeyEventTap", code: -3,
        userInfo: [NSLocalizedDescriptionKey: "Failed to create run loop source"])
    }

    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)

    isEnabled = true
    debugLogCallback?("Event tap started!")
  }

  func stop() {
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

  func reset() {
    engine.reset()
  }

  // MARK: - Event Callback

  private func eventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent
  ) -> Unmanaged<CGEvent>? {

    // Skip events injected by Unikey itself
    if event.getIntegerValueField(.eventSourceUserData) == kUnikeyEventMarker {
      return Unmanaged.passUnretained(event)
    }

    // Handle tap disabled
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      if let tap = eventTap {
        CGEvent.tapEnable(tap: tap, enable: true)
      }
      return Unmanaged.passUnretained(event)
    }

    // Only process keyDown events
    guard type == .keyDown else {
      return Unmanaged.passUnretained(event)
    }

    // Check Vietnamese mode
    guard vietnameseEnabled else {
      return Unmanaged.passUnretained(event)
    }

    // Skip if Command or Control pressed
    let flags = event.flags
    if flags.contains(.maskCommand) || flags.contains(.maskControl) {
      engine.reset()
      return Unmanaged.passUnretained(event)
    }

    // Get key info
    let keyCode = event.keyCode

    // Handle special keys
    // Unikey engine handles Backspace internally if passed, but we need to check if we should pass it.
    // engine.processBackspace checks logic.
    if keyCode == 51 {  // Backspace
        var backs = 0
        var outBuf: [UInt16] = []
        var outSize = 0
        var outType: UkOutputType = .normal

        let ret = engine.processBackspace(&backs, &outBuf, &outSize, &outType)
        if ret != 0 {
            // Handled
            if !outBuf.isEmpty {
                let text = String(utf16CodeUnits: outBuf, count: outSize)
                // Backspace count from processBackspace logic is usually 1 (the backspace itself) + any additional
                // But wait, if engine handled backspace, it might mean we restore something?
                // C++: processBackspace returns > 0 if handled.
                // It modifies backs.
                // If it returns 1, we consume the event?
                // If backs > 1, we might need to send extra backspaces?
                // Or if outSize > 0, we inject text.

                // If outSize > 0 (restoration), inject text.
                // We consume original Backspace.
                injector.inject(backspaceCount: backs, text: text, proxy: proxy)
                // Wait, if we consume backspace, we don't delete.
                // But the engine logic assumes we are deleting?
                // processBackspace logic:
                // m_current--.
                // if returns > 1 (e.g. restoring word), backs is count to delete?
                // Actually C++ returns (backs > 1).
                // If it returns true, we handled it.
                // If it returns false, let system handle.
            }
            return nil // Consume
        }
        return Unmanaged.passUnretained(event)
    }

    if keyCode == 36 || keyCode == 48 || keyCode == 53 || keyCode == 49 {  // Enter, Tab, Escape, Space
      // Space is handled by engine processWordEnd usually?
      // But 49 is Space.
      if keyCode != 49 {
          engine.reset()
          return Unmanaged.passUnretained(event)
      }
    }

    // Get character
    guard let chars = event.characters, let char = chars.first, let asciiVal = char.asciiValue else {
      return Unmanaged.passUnretained(event)
    }

    debugLogCallback?("Key: '\(char)' keyCode: \(keyCode)")

    // Process through engine
    var backs = 0
    var outBuf: [UInt16] = []
    var outSize = 0
    var outType: UkOutputType = .normal

    // We pass ASCII value as keyCode to engine (as C++ does generally for char codes)
    // Or we pass hardware keyCode?
    // C++ Unikey uses Windows virtual key codes or ASCII?
    // keyCodeToEvent in InputMethod.swift uses ASCII if < 256.
    // So pass char.asciiValue.
    let ret = engine.process(UInt32(asciiVal), &backs, &outBuf, &outSize, &outType)

    let output = String(utf16CodeUnits: outBuf, count: outSize)
    debugLogCallback?(
      "Result: ret=\(ret), bs=\(backs), out='\(output)'")

    if ret != 0 {
      // Inject replacement text
      // We consume the original key event
      // If we need to backspace previous chars, do so.
      injector.inject(backspaceCount: backs, text: output, proxy: proxy)
      return nil  // Consume original event
    }

    // Let event through
    return Unmanaged.passUnretained(event)
  }

  // MARK: - Permission Check

  func checkAccessibilityPermission() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

  func requestAccessibilityPermission() {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

  var isRunning: Bool {
    return isEnabled
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
