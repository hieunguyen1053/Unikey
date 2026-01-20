//
//  AppDelegate.swift
//  Unikey - Vietnamese Input Method for macOS
//
//  Created by Hiếu Nguyễn on 20/1/26.
//

import Cocoa
import InputMethodKit

/// Global IMK Server instance
var server: IMKServer?

@main
class AppDelegate: NSObject, NSApplicationDelegate {

  // MARK: - Properties

  /// Status bar item for menu
  var statusItem: NSStatusItem?

  /// Current input method (Telex/VNI/VIQR)
  var currentInputMethod: InputMethod = .telex

  /// Whether Vietnamese mode is enabled
  var vietnameseEnabled: Bool = true

  // MARK: - Application Lifecycle

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Initialize IMK Server
    let connectionName =
      Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String ?? "Unikey_Connection"
    let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.unikey.inputmethod"

    server = IMKServer(name: connectionName, bundleIdentifier: bundleIdentifier)

    if server == nil {
      NSLog("Unikey: Failed to create IMKServer")
    } else {
      NSLog("Unikey: IMKServer created successfully")
    }

    // Setup status bar
    setupStatusBar()
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Cleanup
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // MARK: - Status Bar Setup

  private func setupStatusBar() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    if let button = statusItem?.button {
      button.title = "🇻🇳"
      button.action = #selector(statusBarClicked)
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
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

  @objc func statusBarClicked() {
    // Toggle Vietnamese mode on click
    toggleVietnamese()
  }

  @objc func toggleVietnamese() {
    vietnameseEnabled.toggle()
    updateStatusBarTitle()

    // Update menu checkmark
    if let menu = statusItem?.menu, let vnItem = menu.items.first {
      vnItem.state = vietnameseEnabled ? .on : .off
    }
  }

  @objc func selectTelex() {
    currentInputMethod = .telex
    updateInputMethodMenu()
  }

  @objc func selectVNI() {
    currentInputMethod = .vni
    updateInputMethodMenu()
  }

  @objc func selectVIQR() {
    currentInputMethod = .viqr
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
