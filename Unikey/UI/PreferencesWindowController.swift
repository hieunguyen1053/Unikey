// PreferencesWindowController.swift
// Preferences/Settings window for Unikey
// Unikey Vietnamese Input Method

import Cocoa

/// Preferences window controller
class PreferencesWindowController: NSWindowController {

  // MARK: - Outlets

  @IBOutlet weak var inputMethodPopup: NSPopUpButton!
  @IBOutlet weak var enableSpellCheckCheckbox: NSButton!
  @IBOutlet weak var freeMarkingCheckbox: NSButton!
  @IBOutlet weak var modernStyleCheckbox: NSButton!

  // MARK: - Properties

  static let shared = PreferencesWindowController()

  private let defaults = UserDefaults.standard

  // UserDefaults keys
  private enum Keys {
    static let inputMethod = "UniKeyInputMethod"
    static let spellCheck = "UniKeySpellCheck"
    static let freeMarking = "UniKeyFreeMarking"
    static let modernStyle = "UniKeyModernStyle"
  }

  // MARK: - Initialization

  convenience init() {
    self.init(windowNibName: "PreferencesWindow")
  }

  override func windowDidLoad() {
    super.windowDidLoad()

    window?.title = "Unikey Preferences"
    window?.center()

    loadPreferences()
  }

  // MARK: - Load/Save Preferences

  private func loadPreferences() {
    // Input method
    let inputMethodIndex = defaults.integer(forKey: Keys.inputMethod)
    inputMethodPopup?.selectItem(at: inputMethodIndex)

    // Checkboxes
    enableSpellCheckCheckbox?.state = defaults.bool(forKey: Keys.spellCheck) ? .on : .off
    freeMarkingCheckbox?.state = defaults.bool(forKey: Keys.freeMarking) ? .on : .off
    modernStyleCheckbox?.state = defaults.bool(forKey: Keys.modernStyle) ? .on : .off
  }

  func savePreferences() {
    defaults.set(inputMethodPopup?.indexOfSelectedItem ?? 0, forKey: Keys.inputMethod)
    defaults.set(enableSpellCheckCheckbox?.state == .on, forKey: Keys.spellCheck)
    defaults.set(freeMarkingCheckbox?.state == .on, forKey: Keys.freeMarking)
    defaults.set(modernStyleCheckbox?.state == .on, forKey: Keys.modernStyle)
    defaults.synchronize()
  }

  // MARK: - Actions

  @IBAction func inputMethodChanged(_ sender: NSPopUpButton) {
    savePreferences()
    NotificationCenter.default.post(name: .inputMethodChanged, object: nil)
  }

  @IBAction func spellCheckChanged(_ sender: NSButton) {
    savePreferences()
  }

  @IBAction func freeMarkingChanged(_ sender: NSButton) {
    savePreferences()
  }

  @IBAction func modernStyleChanged(_ sender: NSButton) {
    savePreferences()
  }

  @IBAction func closePreferences(_ sender: Any) {
    savePreferences()
    window?.close()
  }

  // MARK: - Helper Methods

  /// Get current input method from preferences
  static func currentInputMethod() -> UkInputMethod {
    let index = UserDefaults.standard.integer(forKey: Keys.inputMethod)
    return UkInputMethod(rawValue: index) ?? .telex
  }

  /// Check if free marking is enabled
  static func isFreeMarkingEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: Keys.freeMarking)
  }

  /// Check if spell check is enabled
  static func isSpellCheckEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: Keys.spellCheck)
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let inputMethodChanged = Notification.Name("UniKeyInputMethodChanged")
}
