//
//  AppDelegate.swift
//  Unikey - Vietnamese Input Method for macOS
//
//  Uses CGEventTap approach for reliable keyboard handling
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

  // MARK: - Properties

  /// Status bar item for menu
  var statusItem: NSStatusItem?

  /// Event tap manager (new EventTapHandling module)
  var eventTap: UnikeyEventTapManager?

  /// Current input method (Telex/VNI/VIQR)
  var currentInputMethod: UkInputMethod = .telex

  /// Whether Vietnamese mode is enabled
  var vietnameseEnabled: Bool = true

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
    eventTap?.debugLogCallback = { [weak self] msg in
      NSLog("Unikey: \(msg)")
    }
    eventTap?.setInputMethod(currentInputMethod)

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
      button.title = vietnameseEnabled ? "🇻🇳" : "EN"
    }

    // Create menu
    let menu = NSMenu()

    // Vietnamese toggle
    let vnItem = NSMenuItem(
      title: "Vietnamese", action: #selector(toggleVietnamese), keyEquivalent: "")
    vnItem.state = vietnameseEnabled ? .on : .off
    menu.addItem(vnItem)

    menu.addItem(NSMenuItem.separator())

    // Input method selection
    let telexItem = NSMenuItem(title: "Telex", action: #selector(selectTelex), keyEquivalent: "")
    telexItem.state = currentInputMethod == .telex ? .on : .off
    menu.addItem(telexItem)

    let vniItem = NSMenuItem(title: "VNI", action: #selector(selectVNI), keyEquivalent: "")
    vniItem.state = currentInputMethod == .vni ? .on : .off
    menu.addItem(vniItem)

    let viqrItem = NSMenuItem(title: "VIQR", action: #selector(selectVIQR), keyEquivalent: "")
    viqrItem.state = currentInputMethod == .viqr ? .on : .off
    menu.addItem(viqrItem)

    menu.addItem(NSMenuItem.separator())

    // Preferences
    menu.addItem(
      NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))

    // Quit
    menu.addItem(
      NSMenuItem(
        title: "Quit Unikey", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

    statusItem?.menu = menu
  }

  // MARK: - Menu Actions

  @objc func toggleVietnamese() {
    vietnameseEnabled.toggle()
    eventTap?.vietnameseEnabled = vietnameseEnabled
    eventTap?.reset()
    updateStatusBarTitle()

    if let menu = statusItem?.menu, let vnItem = menu.items.first {
      vnItem.state = vietnameseEnabled ? .on : .off
    }
  }

  @objc func selectTelex() {
    currentInputMethod = .telex
    eventTap?.setInputMethod(.telex)
    eventTap?.reset()
    updateInputMethodMenu()
  }

  @objc func selectVNI() {
    currentInputMethod = .vni
    eventTap?.setInputMethod(.vni)
    eventTap?.reset()
    updateInputMethodMenu()
  }

  @objc func selectVIQR() {
    currentInputMethod = .viqr
    eventTap?.setInputMethod(.viqr)
    eventTap?.reset()
    updateInputMethodMenu()
  }

  @objc func showPreferences() {
    PreferencesWindowManager.shared.showPreferences()
  }

  private func updateStatusBarTitle() {
    if let button = statusItem?.button {
      button.title = vietnameseEnabled ? "🇻🇳" : "EN"
    }
  }

  private func updateInputMethodMenu() {
    guard let menu = statusItem?.menu else { return }

    for item in menu.items {
      switch item.title {
      case "Telex":
        item.state = currentInputMethod == .telex ? .on : .off
      case "VNI":
        item.state = currentInputMethod == .vni ? .on : .off
      case "VIQR":
        item.state = currentInputMethod == .viqr ? .on : .off
      default:
        break
      }
    }
  }
}
