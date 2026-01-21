// PreferencesView.swift
// SwiftUI-based Preferences View matching Windows Unikey layout
// Unikey Vietnamese Input Method

import SwiftUI

/// Main Preferences View - Windows Unikey style
struct PreferencesView: View {
  // MARK: - App Storage
  @AppStorage("UniKeyCharacterSet") private var characterSetIndex: Int = 0
  @AppStorage("UniKeyInputMethod") private var inputMethodIndex: Int = 0
  @AppStorage("UniKeySwitchKey") private var switchKeyIndex: Int = 0

  @AppStorage("UniKeyFreeMarking") private var freeMarking: Bool = true
  @AppStorage("UniKeyModernStyle") private var modernStyle: Bool = false
  @AppStorage("UniKeyClipboardForUnicode") private var clipboardForUnicode: Bool = false
  @AppStorage("UniKeySpellCheck") private var spellCheck: Bool = false
  @AppStorage("UniKeyAutoRestore") private var autoRestore: Bool = false
  @AppStorage("UniKeyShowNotification") private var showNotification: Bool = false

  @AppStorage("UniKeyMacroEnabled") private var macroEnabled: Bool = true
  @AppStorage("UniKeyMacroWhenVietnamese") private var macroWhenVietnamese: Bool = true

  @AppStorage("UniKeyShowDialogOnStartup") private var showDialogOnStartup: Bool = false
  @AppStorage("UniKeyLaunchAtLogin") private var launchAtLogin: Bool = false
  @AppStorage("UniKeyVietnameseInterface") private var vietnameseInterface: Bool = true

  // MARK: - Constants
  private let characterSets = ["Unicode", "VNI Windows", "TCVN3 (ABC)", "VIQR"]
  private let inputMethods = ["Telex", "VNI", "VIQR", "Microsoft"]

  var body: some View {
    VStack(spacing: 0) {
      // Content Area
      VStack(spacing: 16) {
        // MARK: - Điều khiển (Controls)
        GroupBox {
          VStack(alignment: .leading, spacing: 12) {
            // Bảng mã
            HStack {
              Text("Bảng mã:")
                .frame(width: 100, alignment: .trailing)
              Picker("", selection: $characterSetIndex) {
                ForEach(0..<characterSets.count, id: \.self) { index in
                  Text(characterSets[index]).tag(index)
                }
              }
              .labelsHidden()
              .frame(maxWidth: .infinity)
            }

            // Kiểu gõ
            HStack {
              Text("Kiểu gõ:")
                .frame(width: 100, alignment: .trailing)
              Picker("", selection: $inputMethodIndex) {
                ForEach(0..<inputMethods.count, id: \.self) { index in
                  Text(inputMethods[index]).tag(index)
                }
              }
              .labelsHidden()
              .frame(maxWidth: .infinity)
              .onChange(of: inputMethodIndex) { _ in
                NotificationCenter.default.post(
                  name: .inputMethodChanged, object: nil)
              }
            }

            // Phím chuyển
            HStack {
              Text("Phím chuyển:")
                .frame(width: 100, alignment: .trailing)

              Picker("", selection: $switchKeyIndex) {
                Text("CTRL + SHIFT").tag(0)
                Text("ALT + Z").tag(1)
              }
              .pickerStyle(.radioGroup)
              .horizontalRadioGroupLayout()
            }
          }
          .padding(8)
        } label: {
          Text("Điều khiển")
            .font(.headline)
        }

        HStack(alignment: .top, spacing: 16) {
          // MARK: - Tùy chọn khác (Other Options)
          GroupBox {
            VStack(alignment: .leading, spacing: 8) {
              Toggle("Cho phép gõ tự do", isOn: $freeMarking)
              Toggle("Đặt dấu oà, uý (thay vì òa, úy)", isOn: $modernStyle)
              Toggle("Luôn sử dụng clipboard cho unicode", isOn: $clipboardForUnicode)
              Toggle("Bật kiểm tra chính tả", isOn: $spellCheck)
              Toggle("Tự động khôi phục phím với từ sai", isOn: $autoRestore)
              Toggle("Hiện thông báo phản hồi", isOn: $showNotification)
            }
            .padding(8)
          } label: {
            Text("Tùy chọn khác")
              .font(.headline)
          }

          VStack(spacing: 16) {
            // MARK: - Tùy chọn gõ tắt (Macro Options)
            GroupBox {
              VStack(alignment: .leading, spacing: 8) {
                Toggle("Cho phép gõ tắt", isOn: $macroEnabled)
                Toggle("Cho phép gõ tắt cả khi tắt tiếng Việt", isOn: $macroWhenVietnamese)

                Button("Bảng gõ tắt...") {
                  showMacroEditor()
                }
                .padding(.top, 4)
              }
              .padding(8)
            } label: {
              Text("Tùy chọn gõ tắt")
                .font(.headline)
            }

            // MARK: - Hệ thống (System)
            GroupBox {
              VStack(alignment: .leading, spacing: 8) {
                Toggle("Bật hội thoại này khi khởi động", isOn: $showDialogOnStartup)
                Toggle("Khởi động cùng macOS", isOn: $launchAtLogin)
                Toggle("Vietnamese interface", isOn: $vietnameseInterface)
              }
              .padding(8)
            } label: {
              Text("Hệ thống")
                .font(.headline)
            }
          }
        }
      }
      .padding(16)

      Divider()

      // MARK: - Footer Buttons
      HStack {
        Button {
          showHelp()
        } label: {
          Label("Hướng dẫn", systemImage: "questionmark.circle")
        }

        Button("Thông tin") {
          showAbout()
        }

        Spacer()

        Button("Mặc định") {
          resetToDefaults()
        }
      }
      .padding(16)
    }
    .frame(width: 580, height: 420)
  }

  // MARK: - Actions

  private func showMacroEditor() {
    // TODO: Show macro editor window
    print("Show macro editor")
  }

  private func showHelp() {
    if let url = URL(string: "https://www.unikey.org/huong-dan.html") {
      NSWorkspace.shared.open(url)
    }
  }

  private func showAbout() {
    NSApp.orderFrontStandardAboutPanel(nil)
  }

  private func resetToDefaults() {
    characterSetIndex = 0
    inputMethodIndex = 0
    switchKeyIndex = 0
    freeMarking = true
    modernStyle = false
    clipboardForUnicode = false
    spellCheck = false
    autoRestore = false
    showNotification = false
    macroEnabled = true
    macroWhenVietnamese = true
    showDialogOnStartup = false
    launchAtLogin = false
    vietnameseInterface = true
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
        contentRect: NSRect(x: 0, y: 0, width: 580, height: 420),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
      )
      window?.title = "Unikey"
      window?.contentView = NSHostingView(rootView: preferencesView)
      window?.center()
    }

    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  func closePreferences() {
    window?.close()
  }
}
