// PreferencesView.swift
// SwiftUI-based Preferences View (alternative to NIB)
// Unikey Vietnamese Input Method

import SwiftUI

/// Main Preferences View using SwiftUI
struct PreferencesView: View {
  @AppStorage("UniKeyInputMethod") private var inputMethodIndex: Int = 0
  @AppStorage("UniKeyFreeMarking") private var freeMarking: Bool = true
  @AppStorage("UniKeyModernStyle") private var modernStyle: Bool = true
  @AppStorage("UniKeySpellCheck") private var spellCheck: Bool = false

  private let inputMethods = ["Telex", "VNI", "VIQR", "Simple Telex"]

  var body: some View {
    Form {
      // Input Method Section
      Section {
        Picker("Input Method:", selection: $inputMethodIndex) {
          ForEach(0..<inputMethods.count, id: \.self) { index in
            Text(inputMethods[index]).tag(index)
          }
        }
        .pickerStyle(.segmented)
        .onChange(of: inputMethodIndex) { _ in
          NotificationCenter.default.post(name: .inputMethodChanged, object: nil)
        }
      } header: {
        Label("Typing Method", systemImage: "keyboard")
      }

      // Typing Options Section
      Section {
        Toggle("Free Marking", isOn: $freeMarking)
          .help("Allow diacritics to be placed at any position")

        Toggle("Modern Style (oa, oe)", isOn: $modernStyle)
          .help("Use modern tone placement for 'oa', 'oe' words")

        Toggle("Spell Check", isOn: $spellCheck)
          .help("Enable basic Vietnamese spell checking")
      } header: {
        Label("Typing Options", systemImage: "textformat")
      }

      // Keyboard Shortcuts Section
      Section {
        HStack {
          Text("Toggle Vietnamese:")
          Spacer()
          Text("⌘ Space")
            .foregroundColor(.secondary)
        }

        HStack {
          Text("Switch Input Method:")
          Spacer()
          Text("⌃ ⌥ Space")
            .foregroundColor(.secondary)
        }
      } header: {
        Label("Keyboard Shortcuts", systemImage: "command")
      }

      // About Section
      Section {
        HStack {
          Text("Version:")
          Spacer()
          Text("1.0.0")
            .foregroundColor(.secondary)
        }

        Link(destination: URL(string: "https://github.com/user/unikey-swift")!) {
          HStack {
            Text("GitHub Repository")
            Spacer()
            Image(systemName: "arrow.up.right.square")
          }
        }
      } header: {
        Label("About", systemImage: "info.circle")
      }
    }
    .formStyle(.grouped)
    .frame(width: 400, height: 450)
    .padding()
  }
}

/// Preferences Window using SwiftUI
struct PreferencesWindow: View {
  var body: some View {
    PreferencesView()
  }
}

// MARK: - Preview

#Preview {
  PreferencesView()
}

// MARK: - Helper to show preferences window

class PreferencesWindowManager {
  static let shared = PreferencesWindowManager()

  private var window: NSWindow?

  func showPreferences() {
    if window == nil {
      let preferencesView = PreferencesView()
      window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 400, height: 450),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
      )
      window?.title = "Unikey Preferences"
      window?.contentView = NSHostingView(rootView: preferencesView)
      window?.center()
    }

    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}
