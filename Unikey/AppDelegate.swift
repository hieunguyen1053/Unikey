//
//  AppDelegate.swift
//  Unikey - Vietnamese Input Method for macOS
//
//  Uses CGEventTap approach for reliable keyboard handling
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {

  // MARK: - Properties

  /// Status bar item for menu
  var statusItem: NSStatusItem?

  /// Event tap manager (new EventTapHandling module)
  var eventTap: UnikeyEventTapManager?

  /// Current input method (Telex/VNI/VIQR)
  @AppStorage("UniKeyInputMethod") var currentInputMethodIndex: Int = 0

  /// Current character set
  @AppStorage("UniKeyCharacterSet") var currentCharacterSetIndex: Int = 0

  /// Whether Vietnamese mode is enabled
  var vietnameseEnabled: Bool = true

  /// Spell check enabled
  @AppStorage("UniKeySpellCheck") var spellCheckEnabled: Bool = false

  /// Macro enabled
  @AppStorage("UniKeyMacroEnabled") var macroEnabled: Bool = true

  // Input methods list
  private let inputMethods: [(name: String, method: UkInputMethod)] = [
    ("Telex", .telex),
    ("VNI", .vni),
    ("VIQR", .viqr),
    ("Microsoft VI Layout", .telex),  // TODO: Add proper support
  ]

  // Character sets list
  private let characterSets = [
    "Unicode dựng sẵn",
    "TCVN3 (ABC)",
    "VNI Windows",
  ]

  // MARK: - Application Lifecycle

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSLog("Unikey: Starting...")

    // Check and request accessibility permission
    if !checkAccessibilityPermission() {
      showAccessibilityDialog()
    }

    // Setup event tap
    setupEventTap()

    // Setup status bar
    setupStatusBar()

    NSLog("Unikey: Ready!")
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    eventTap?.stop()
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // MARK: - Event Tap Setup

  private func setupEventTap() {
    eventTap = UnikeyEventTapManager()
    eventTap?.debugLogCallback = { msg in
      NSLog("Unikey: \(msg)")
    }

    let method = inputMethods[safe: currentInputMethodIndex]?.method ?? .telex
    eventTap?.setInputMethod(method)

    do {
      try eventTap?.start()
      NSLog("Unikey: Event tap started successfully")
    } catch {
      NSLog("Unikey: Failed to start event tap: \(error)")
    }
  }

  // MARK: - Accessibility Permission

  private func checkAccessibilityPermission() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

  private func showAccessibilityDialog() {
    let alert = NSAlert()
    alert.messageText = "Accessibility Permission Required"
    alert.informativeText =
      "Unikey needs Accessibility permission to intercept keyboard events.\n\nPlease go to System Preferences → Security & Privacy → Privacy → Accessibility and add Unikey."
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Open System Preferences")
    alert.addButton(withTitle: "Later")

    if alert.runModal() == .alertFirstButtonReturn {
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
      NSWorkspace.shared.open(url)
    }
  }

  // MARK: - Status Bar Setup

  private func setupStatusBar() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    if let button = statusItem?.button {
      button.title = vietnameseEnabled ? "VI" : "EN"
    }

    rebuildMenu()
  }

  private func rebuildMenu() {
    let menu = NSMenu()

    // MARK: - Hướng dẫn & Công cụ
    menu.addItem(NSMenuItem(title: "Hướng dẫn", action: #selector(showHelp), keyEquivalent: ""))
    menu.addItem(
      NSMenuItem(title: "Công cụ...", action: #selector(showTools), keyEquivalent: ""))
    menu.addItem(
      NSMenuItem(
        title: "Chuyển mã nhanh", action: #selector(quickConvert), keyEquivalent: ""))

    menu.addItem(NSMenuItem.separator())

    // MARK: - Bật kiểm tra chính tả
    let spellCheckItem = NSMenuItem(
      title: "Bật kiểm tra chính tả", action: #selector(toggleSpellCheck), keyEquivalent: "")
    spellCheckItem.state = spellCheckEnabled ? .on : .off
    menu.addItem(spellCheckItem)

    // MARK: - Bật tính năng gõ tắt
    let macroItem = NSMenuItem(
      title: "Bật tính năng gõ tắt", action: #selector(toggleMacro), keyEquivalent: "")
    macroItem.state = macroEnabled ? .on : .off
    menu.addItem(macroItem)

    // Soạn bảng gõ tắt
    menu.addItem(
      NSMenuItem(
        title: "Soạn bảng gõ tắt...", action: #selector(showMacroEditor), keyEquivalent: ""))

    // MARK: - Kiểu gõ (Input Method) - Submenu
    let inputMethodItem = NSMenuItem(title: "Kiểu gõ", action: nil, keyEquivalent: "")
    let inputMethodSubmenu = NSMenu()

    for (index, im) in inputMethods.enumerated() {
      let item = NSMenuItem(
        title: im.name, action: #selector(selectInputMethod(_:)), keyEquivalent: "")
      item.tag = index
      item.state = (index == currentInputMethodIndex) ? .on : .off
      inputMethodSubmenu.addItem(item)
    }

    inputMethodItem.submenu = inputMethodSubmenu
    menu.addItem(inputMethodItem)

    menu.addItem(NSMenuItem.separator())

    // MARK: - Character Sets (Bảng mã)
    for (index, charset) in characterSets.enumerated() {
      let item = NSMenuItem(
        title: charset, action: #selector(selectCharacterSet(_:)), keyEquivalent: "")
      item.tag = index
      item.state = (index == currentCharacterSetIndex) ? .on : .off
      menu.addItem(item)
    }

    // Bảng mã khác
    menu.addItem(
      NSMenuItem(
        title: "Bảng mã khác...", action: #selector(showOtherCharsets), keyEquivalent: ""))

    menu.addItem(NSMenuItem.separator())

    // MARK: - Bảng điều khiển (Preferences)
    menu.addItem(
      NSMenuItem(
        title: "Bảng điều khiển...", action: #selector(showPreferences), keyEquivalent: ","))

    // MARK: - Kết thúc (Quit)
    menu.addItem(
      NSMenuItem(
        title: "Kết thúc", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"
      ))

    statusItem?.menu = menu
  }

  // MARK: - Menu Actions

  @objc func toggleVietnamese() {
    vietnameseEnabled.toggle()
    eventTap?.vietnameseEnabled = vietnameseEnabled
    eventTap?.reset()
    updateStatusBarTitle()
  }

  @objc func toggleSpellCheck() {
    spellCheckEnabled.toggle()
    rebuildMenu()
  }

  @objc func toggleMacro() {
    macroEnabled.toggle()
    rebuildMenu()
  }

  @objc func selectInputMethod(_ sender: NSMenuItem) {
    currentInputMethodIndex = sender.tag
    let method = inputMethods[safe: currentInputMethodIndex]?.method ?? .telex
    eventTap?.setInputMethod(method)
    eventTap?.reset()
    rebuildMenu()
  }

  @objc func selectCharacterSet(_ sender: NSMenuItem) {
    currentCharacterSetIndex = sender.tag
    rebuildMenu()
  }

  @objc func showHelp() {
    if let url = URL(string: "https://www.unikey.org/huong-dan.html") {
      NSWorkspace.shared.open(url)
    }
  }

  @objc func showTools() {
    // TODO: Implement tools window
    NSLog("Unikey: Show tools")
  }

  @objc func quickConvert() {
    // TODO: Implement quick convert
    NSLog("Unikey: Quick convert")
  }

  @objc func showMacroEditor() {
    // TODO: Implement macro editor
    NSLog("Unikey: Show macro editor")
  }

  @objc func showOtherCharsets() {
    // TODO: Implement other charsets picker
    NSLog("Unikey: Show other charsets")
  }

  @objc func showPreferences() {
    PreferencesWindowManager.shared.showPreferences()
  }

  private func updateStatusBarTitle() {
    if let button = statusItem?.button {
      button.title = vietnameseEnabled ? "VI" : "EN"
    }
  }
}

// MARK: - Array Safe Subscript

extension Array {
  subscript(safe index: Int) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
