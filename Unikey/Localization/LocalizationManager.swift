//
//  LocalizationManager.swift
//  Unikey - Vietnamese Input Method for macOS
//
//  Manages app-level localization with support for Vietnamese and English
//

import Combine
import Foundation
import SwiftUI

/// Supported languages
enum AppLanguage: String, CaseIterable {
  case vietnamese = "vi"
  case english = "en"

  var displayName: String {
    switch self {
    case .vietnamese: return "Tiếng Việt"
    case .english: return "English"
    }
  }
}

/// Localized strings for each language
struct LocalizedStrings {
  // MARK: - Menu Items
  let menuHelp: String
  let menuTools: String
  let menuQuickConvert: String
  let menuSpellCheck: String
  let menuMacro: String
  let menuMacroEditor: String
  let menuInputMethod: String
  let menuOtherCharsets: String
  let menuPreferences: String
  let menuQuit: String

  // MARK: - Character Sets
  let charsetUnicode: String
  let charsetTCVN3: String
  let charsetVNI: String

  // MARK: - Preferences
  let controls: String
  let charset: String
  let inputMethod: String
  let switchKey: String

  let otherOptions: String
  let freeMarking: String
  let modernStyle: String
  let clipboardUnicode: String
  let spellCheck: String
  let autoRestore: String
  let showNotification: String

  let macroOptions: String
  let enableMacro: String
  let macroWhenOff: String
  let macroTable: String

  let system: String
  let showOnStartup: String
  let launchAtLogin: String
  let language: String
  let homePage: String

  let help: String
  let about: String
  let reset: String

  // MARK: - Accessibility
  let accessibilityTitle: String
  let accessibilityMessage: String
  let accessibilityOpenPrefs: String
  let accessibilityLater: String

  // Vietnamese strings
  static let vietnamese = LocalizedStrings(
    menuHelp: "Trang chủ",
    menuTools: "Công cụ...",
    menuQuickConvert: "Chuyển mã nhanh",
    menuSpellCheck: "Bật kiểm tra chính tả",
    menuMacro: "Bật tính năng gõ tắt",
    menuMacroEditor: "Soạn bảng gõ tắt...",
    menuInputMethod: "Kiểu gõ",
    menuOtherCharsets: "Bảng mã khác...",
    menuPreferences: "Bảng điều khiển...",
    menuQuit: "Kết thúc",

    charsetUnicode: "Unicode dựng sẵn",
    charsetTCVN3: "TCVN3 (ABC)",
    charsetVNI: "VNI Windows",

    controls: "Điều khiển",
    charset: "Bảng mã:",
    inputMethod: "Kiểu gõ:",
    switchKey: "Phím chuyển:",

    otherOptions: "Tùy chọn khác",
    freeMarking: "Cho phép gõ tự do",
    modernStyle: "Đặt dấu oà, uý (thay vì òa, úy)",
    clipboardUnicode: "Luôn sử dụng clipboard cho Unicode",
    spellCheck: "Bật kiểm tra chính tả",
    autoRestore: "Tự động khôi phục phím với từ sai",
    showNotification: "Hiện thông báo phản hồi",

    macroOptions: "Tùy chọn gõ tắt",
    enableMacro: "Cho phép gõ tắt",
    macroWhenOff: "Cho phép gõ tắt cả khi tắt tiếng Việt",
    macroTable: "Bảng gõ tắt...",

    system: "Hệ thống",
    showOnStartup: "Bật hội thoại này khi khởi động",
    launchAtLogin: "Khởi động cùng macOS",
    language: "Ngôn ngữ",
    homePage: "Trang chủ",

    help: "Hướng dẫn",
    about: "Thông tin",
    reset: "Mặc định",

    accessibilityTitle: "Cần quyền Accessibility",
    accessibilityMessage:
      "Unikey cần quyền Accessibility để xử lý sự kiện bàn phím.\n\nVui lòng vào System Preferences → Security & Privacy → Privacy → Accessibility và thêm Unikey.",
    accessibilityOpenPrefs: "Mở System Preferences",
    accessibilityLater: "Để sau"
  )

  // English strings
  static let english = LocalizedStrings(
    menuHelp: "Home Page",
    menuTools: "Tools...",
    menuQuickConvert: "Quick Convert",
    menuSpellCheck: "Enable Spell Check",
    menuMacro: "Enable Macro",
    menuMacroEditor: "Edit Macro Table...",
    menuInputMethod: "Input Method",
    menuOtherCharsets: "Other Charsets...",
    menuPreferences: "Preferences...",
    menuQuit: "Quit",

    charsetUnicode: "Unicode (Precomposed)",
    charsetTCVN3: "TCVN3 (ABC)",
    charsetVNI: "VNI Windows",

    controls: "Controls",
    charset: "Character Set:",
    inputMethod: "Input Method:",
    switchKey: "Switch Key:",

    otherOptions: "Other Options",
    freeMarking: "Free Marking",
    modernStyle: "Modern style óa, úy (instead of òa, úy)",
    clipboardUnicode: "Always use clipboard for Unicode",
    spellCheck: "Enable Spell Check",
    autoRestore: "Auto restore keys for invalid words",
    showNotification: "Show feedback notification",

    macroOptions: "Macro Options",
    enableMacro: "Enable Macro",
    macroWhenOff: "Enable Macro even when Vietnamese is off",
    macroTable: "Macro Table...",

    system: "System",
    showOnStartup: "Show this dialog on startup",
    launchAtLogin: "Launch at Login",
    language: "Language",
    homePage: "Home",

    help: "Help",
    about: "About",
    reset: "Reset to Defaults",

    accessibilityTitle: "Accessibility Permission Required",
    accessibilityMessage:
      "Unikey needs Accessibility permission to intercept keyboard events.\n\nPlease go to System Preferences → Security & Privacy → Privacy → Accessibility and add Unikey.",
    accessibilityOpenPrefs: "Open System Preferences",
    accessibilityLater: "Later"
  )
}

/// Manages localization for the app
class LocalizationManager: ObservableObject {
  static let shared = LocalizationManager()

  /// Current language
  @Published var currentLanguage: AppLanguage {
    didSet {
      UserDefaults.standard.set(
        currentLanguage.rawValue,
        forKey: "UniKeyAppLanguage"
      )
      // Post notification for non-SwiftUI parts
      NotificationCenter.default.post(
        name: .languageChanged,
        object: currentLanguage
      )
    }
  }

  /// Get current localized strings
  var strings: LocalizedStrings {
    switch currentLanguage {
    case .vietnamese:
      return .vietnamese
    case .english:
      return .english
    }
  }

  private init() {
    // Load saved language or default to Vietnamese
    let savedLanguage =
      UserDefaults.standard.string(forKey: "UniKeyAppLanguage") ?? "vi"
    self.currentLanguage =
      AppLanguage(rawValue: savedLanguage) ?? .vietnamese
  }

  /// Toggle between Vietnamese and English
  func toggleLanguage() {
    currentLanguage =
      (currentLanguage == .vietnamese) ? .english : .vietnamese
  }
}

// MARK: - Notification Name

extension Notification.Name {
  static let languageChanged = Notification.Name("UniKeyLanguageChanged")
}

// MARK: - String Extension for Localization (backwards compatibility)

extension String {
  /// Get localized string using LocalizationManager
  var localized: String {
    let L = LocalizationManager.shared.strings
    // Map keys to localized values
    switch self {
    case "menu.help": return L.menuHelp
    case "menu.tools": return L.menuTools
    case "menu.quick_convert": return L.menuQuickConvert
    case "menu.spell_check": return L.menuSpellCheck
    case "menu.macro": return L.menuMacro
    case "menu.macro_editor": return L.menuMacroEditor
    case "menu.input_method": return L.menuInputMethod
    case "menu.other_charsets": return L.menuOtherCharsets
    case "menu.preferences": return L.menuPreferences
    case "menu.quit": return L.menuQuit
    case "charset.unicode": return L.charsetUnicode
    case "charset.tcvn3": return L.charsetTCVN3
    case "charset.vni": return L.charsetVNI
    case "input.telex": return "Telex"
    case "input.vni": return "VNI"
    case "input.viqr": return "VIQR"
    case "input.microsoft": return "Microsoft VI Layout"
    case "accessibility.title": return L.accessibilityTitle
    case "accessibility.message": return L.accessibilityMessage
    case "accessibility.open_prefs": return L.accessibilityOpenPrefs
    case "accessibility.later": return L.accessibilityLater
    default: return self
    }
  }
}
