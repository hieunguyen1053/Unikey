//
//  AppDelegate.swift
//  Unikey - Vietnamese Input Method for macOS
//
//  Uses CGEventTap approach for reliable keyboard handling
//

import Cocoa
import ServiceManagement
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

  /// Launch at login
  @AppStorage("UniKeyLaunchAtLogin") var launchAtLogin: Bool = false {
    didSet {
      updateLaunchAtLogin()
    }
  }

  /// Show preferences on startup
  @AppStorage("UniKeyShowDialogOnStartup") var showDialogOnStartup: Bool =
    false

  // Input methods list
  private var inputMethods: [(name: String, method: UkInputMethod)] {
    [
      ("input.telex".localized, .telex),
      ("input.vni".localized, .vni),
      ("input.viqr".localized, .viqr),
      ("input.microsoft".localized, .telex),  // TODO: Add proper support
    ]
  }

  // Character sets list
  private var characterSets: [String] {
    [
      "charset.unicode".localized,
      "charset.tcvn3".localized,
      "charset.vni".localized,
    ]
  }

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

    // Observe language changes to rebuild menu
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(languageDidChange),
      name: .languageChanged,
      object: nil
    )

    // Show preferences on startup if enabled
    if showDialogOnStartup {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.showPreferences()
      }
    }

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

    let method =
      inputMethods[safe: currentInputMethodIndex]?.method ?? .telex
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
    let options = [
      kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false
    ]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

  private func showAccessibilityDialog() {
    let alert = NSAlert()
    alert.messageText = "accessibility.title".localized
    alert.informativeText = "accessibility.message".localized
    alert.alertStyle = .warning
    alert.addButton(withTitle: "accessibility.open_prefs".localized)
    alert.addButton(withTitle: "accessibility.later".localized)

    if alert.runModal() == .alertFirstButtonReturn {
      let url = URL(
        string:
          "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
      )!
      NSWorkspace.shared.open(url)
    }
  }

  // MARK: - Status Bar Setup

  private func setupStatusBar() {
    statusItem = NSStatusBar.system.statusItem(
      withLength: NSStatusItem.variableLength
    )

    if let button = statusItem?.button {
      button.title = vietnameseEnabled ? "VI" : "EN"
    }

    rebuildMenu()
  }

  private func rebuildMenu() {
    let menu = NSMenu()

    // MARK: - Help & Tools
    menu.addItem(
      NSMenuItem(
        title: "menu.help".localized,
        action: #selector(showHelp),
        keyEquivalent: ""
      )
    )
    menu.addItem(
      NSMenuItem(
        title: "menu.tools".localized,
        action: #selector(showTools),
        keyEquivalent: ""
      )
    )
    menu.addItem(
      NSMenuItem(
        title: "menu.quick_convert".localized,
        action: #selector(quickConvert),
        keyEquivalent: ""
      )
    )

    menu.addItem(NSMenuItem.separator())

    // MARK: - Spell Check
    let spellCheckItem = NSMenuItem(
      title: "menu.spell_check".localized,
      action: #selector(toggleSpellCheck),
      keyEquivalent: ""
    )
    spellCheckItem.state = spellCheckEnabled ? .on : .off
    menu.addItem(spellCheckItem)

    // MARK: - Macro
    let macroItem = NSMenuItem(
      title: "menu.macro".localized,
      action: #selector(toggleMacro),
      keyEquivalent: ""
    )
    macroItem.state = macroEnabled ? .on : .off
    menu.addItem(macroItem)

    // Edit Macro Table
    menu.addItem(
      NSMenuItem(
        title: "menu.macro_editor".localized,
        action: #selector(showMacroEditor),
        keyEquivalent: ""
      )
    )

    // MARK: - Input Method Submenu
    let inputMethodItem = NSMenuItem(
      title: "menu.input_method".localized,
      action: nil,
      keyEquivalent: ""
    )
    let inputMethodSubmenu = NSMenu()

    for (index, im) in inputMethods.enumerated() {
      let item = NSMenuItem(
        title: im.name,
        action: #selector(selectInputMethod(_:)),
        keyEquivalent: ""
      )
      item.tag = index
      item.state = (index == currentInputMethodIndex) ? .on : .off
      inputMethodSubmenu.addItem(item)
    }

    inputMethodItem.submenu = inputMethodSubmenu
    menu.addItem(inputMethodItem)

    menu.addItem(NSMenuItem.separator())

    // MARK: - Character Sets
    for (index, charset) in characterSets.enumerated() {
      let item = NSMenuItem(
        title: charset,
        action: #selector(selectCharacterSet(_:)),
        keyEquivalent: ""
      )
      item.tag = index
      item.state = (index == currentCharacterSetIndex) ? .on : .off
      menu.addItem(item)
    }

    // Other Charsets
    menu.addItem(
      NSMenuItem(
        title: "menu.other_charsets".localized,
        action: #selector(showOtherCharsets),
        keyEquivalent: ""
      )
    )

    menu.addItem(NSMenuItem.separator())

    // MARK: - Preferences
    menu.addItem(
      NSMenuItem(
        title: "menu.preferences".localized,
        action: #selector(showPreferences),
        keyEquivalent: ","
      )
    )

    // MARK: - Quit
    menu.addItem(
      NSMenuItem(
        title: "menu.quit".localized,
        action: #selector(NSApplication.terminate(_:)),
        keyEquivalent: "q"
      )
    )

    statusItem?.menu = menu
  }

  @objc private func languageDidChange() {
    rebuildMenu()
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
    let method =
      inputMethods[safe: currentInputMethodIndex]?.method ?? .telex
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
    MacroEditorWindowController.shared.showEditor()
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

  // MARK: - Launch at Login

  private func updateLaunchAtLogin() {
    if #available(macOS 13.0, *) {
      do {
        if launchAtLogin {
          try SMAppService.mainApp.register()
          NSLog("Unikey: Registered for launch at login")
        } else {
          try SMAppService.mainApp.unregister()
          NSLog("Unikey: Unregistered from launch at login")
        }
      } catch {
        NSLog("Unikey: Failed to update launch at login: \(error)")
      }
    } else {
      // Fallback for older macOS versions
      NSLog("Unikey: Launch at login requires macOS 13.0 or later")
    }
  }

  /// Check current launch at login status
  func isLaunchAtLoginEnabled() -> Bool {
    if #available(macOS 13.0, *) {
      return SMAppService.mainApp.status == .enabled
    }
    return false
  }
}

// MARK: - Array Safe Subscript

extension Array {
  subscript(safe index: Int) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
