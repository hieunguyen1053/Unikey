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

  var locale: Locale {
    return Locale(identifier: rawValue)
  }
}

/// Manages localization for the app
class LocalizationManager: ObservableObject {
  static let shared = LocalizationManager()

  /// Current language
  @Published var currentLanguage: AppLanguage {
    didSet {
      UserDefaults.standard.set(currentLanguage.rawValue, forKey: "UniKeyAppLanguage")
      bundle = Self.bundle(for: currentLanguage)
      // Post notification for non-SwiftUI parts
      NotificationCenter.default.post(name: .languageChanged, object: currentLanguage)
    }
  }

  /// Current bundle for localization
  private(set) var bundle: Bundle

  private init() {
    // Load saved language or default to Vietnamese
    let savedLanguage = UserDefaults.standard.string(forKey: "UniKeyAppLanguage") ?? "vi"
    let language = AppLanguage(rawValue: savedLanguage) ?? .vietnamese
    self.currentLanguage = language
    self.bundle = Self.bundle(for: language)
  }

  /// Get bundle for a specific language
  private static func bundle(for language: AppLanguage) -> Bundle {
    guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
      let bundle = Bundle(path: path)
    else {
      return Bundle.main
    }
    return bundle
  }

  /// Localized string for a key
  func string(_ key: String) -> String {
    return bundle.localizedString(forKey: key, value: nil, table: nil)
  }

  /// Toggle between Vietnamese and English
  func toggleLanguage() {
    currentLanguage = (currentLanguage == .vietnamese) ? .english : .vietnamese
  }
}

// MARK: - Notification Name

extension Notification.Name {
  static let languageChanged = Notification.Name("UniKeyLanguageChanged")
}

// MARK: - String Extension for Localization

extension String {
  /// Get localized string using LocalizationManager
  var localized: String {
    return LocalizationManager.shared.string(self)
  }

  /// Get localized string with format arguments
  func localized(with arguments: CVarArg...) -> String {
    return String(format: self.localized, arguments: arguments)
  }
}

// MARK: - SwiftUI Environment Key

private struct LocalizationManagerKey: EnvironmentKey {
  static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
  var localization: LocalizationManager {
    get { self[LocalizationManagerKey.self] }
    set { self[LocalizationManagerKey.self] = newValue }
  }
}

// MARK: - SwiftUI View Extension

extension View {
  /// Inject localization manager into environment
  func withLocalization() -> some View {
    self.environmentObject(LocalizationManager.shared)
  }
}
