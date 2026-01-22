// PreferencesView.swift
// SwiftUI-based Preferences View matching Windows Unikey layout
// Unikey Vietnamese Input Method

import Cocoa
import ServiceManagement
import SwiftUI

/// Main Preferences View - Windows Unikey style
struct PreferencesView: View {
    // MARK: - Localization
    @ObservedObject private var localization = LocalizationManager.shared

    // MARK: - App Storage
    @AppStorage("UniKeyCharacterSet") private var characterSetIndex: Int = 0
    @AppStorage("UniKeyInputMethod") private var inputMethodIndex: Int = 0
    @AppStorage("UniKeySwitchKey") private var switchKeyIndex: Int = 0

    @AppStorage("UniKeyFreeMarking") private var freeMarking: Bool = true
    @AppStorage("UniKeyModernStyle") private var modernStyle: Bool = false
    @AppStorage("UniKeyClipboardForUnicode") private var clipboardForUnicode:
        Bool = false
    @AppStorage("UniKeySpellCheck") private var spellCheck: Bool = false
    @AppStorage("UniKeyAutoRestore") private var autoRestore: Bool = false
    @AppStorage("UniKeyShowNotification") private var showNotification: Bool =
        false

    @AppStorage("UniKeyMacroEnabled") private var macroEnabled: Bool = true
    @AppStorage("UniKeyMacroWhenVietnamese") private var macroWhenVietnamese:
        Bool = true

    @AppStorage("UniKeyShowDialogOnStartup") private var showDialogOnStartup:
        Bool = false
    @AppStorage("UniKeyLaunchAtLogin") private var launchAtLogin: Bool = false

    // MARK: - Localized Strings
    private var L: LocalizedStrings { localization.strings }

    var body: some View {
        VStack(spacing: 0) {
            // Content Area
            VStack(spacing: 16) {
                // MARK: - Controls Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        // Character Set
                        HStack {
                            Text(L.charset)
                                .frame(width: 100, alignment: .trailing)
                            Picker("", selection: $characterSetIndex) {
                                Text(L.charsetUnicode).tag(0)
                                Text(L.charsetVNI).tag(1)
                                Text(L.charsetTCVN3).tag(2)
                                Text("VIQR").tag(3)
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }

                        // Input Method
                        HStack {
                            Text(L.inputMethod)
                                .frame(width: 100, alignment: .trailing)
                            Picker("", selection: $inputMethodIndex) {
                                Text("Telex").tag(0)
                                Text("VNI").tag(1)
                                Text("VIQR").tag(2)
                                Text("Microsoft VI Layout").tag(3)
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .onChange(of: inputMethodIndex) { _ in
                                NotificationCenter.default.post(
                                    name: .inputMethodChanged,
                                    object: nil
                                )
                            }
                        }

                        // Switch Key
                        HStack {
                            Text(L.switchKey)
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
                    Text(L.controls)
                        .font(.headline)
                }

                HStack(alignment: .top, spacing: 16) {
                    // MARK: - Other Options
                    GroupBox {
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(L.freeMarking, isOn: $freeMarking)
                            Toggle(L.modernStyle, isOn: $modernStyle)
                            Toggle(
                                L.clipboardUnicode,
                                isOn: $clipboardForUnicode
                            )
                            Toggle(L.spellCheck, isOn: $spellCheck)
                            Toggle(L.autoRestore, isOn: $autoRestore)
                            Toggle(L.showNotification, isOn: $showNotification)
                        }
                        .padding(8)
                    } label: {
                        Text(L.otherOptions)
                            .font(.headline)
                    }
                    .frame(minWidth: 280)

                    VStack(spacing: 16) {
                        // MARK: - Macro Options
                        GroupBox {
                            VStack(alignment: .leading, spacing: 6) {
                                Toggle(L.enableMacro, isOn: $macroEnabled)
                                Toggle(
                                    L.macroWhenOff,
                                    isOn: $macroWhenVietnamese
                                )

                                Button(L.macroTable) {
                                    showMacroEditor()
                                }
                                .padding(.top, 4)
                            }
                            .padding(8)
                        } label: {
                            Text(L.macroOptions)
                                .font(.headline)
                        }

                        // MARK: - System
                        GroupBox {
                            VStack(alignment: .leading, spacing: 6) {
                                Toggle(
                                    L.showOnStartup,
                                    isOn: $showDialogOnStartup
                                )
                                Toggle(L.launchAtLogin, isOn: $launchAtLogin)
                                    .onChange(of: launchAtLogin) { newValue in
                                        updateLaunchAtLogin(enabled: newValue)
                                    }

                                // Language Picker
                                HStack {
                                    Text(L.language + ":")
                                    Picker(
                                        "",
                                        selection: Binding(
                                            get: {
                                                localization.currentLanguage
                                            },
                                            set: {
                                                localization.currentLanguage =
                                                    $0
                                            }
                                        )
                                    ) {
                                        Text("Tiếng Việt").tag(
                                            AppLanguage.vietnamese
                                        )
                                        Text("English").tag(AppLanguage.english)
                                    }
                                    .labelsHidden()
                                    .frame(width: 130)
                                }
                            }
                            .padding(8)
                        } label: {
                            Text(L.system)
                                .font(.headline)
                        }
                    }
                    .frame(minWidth: 280)
                }
            }
            .padding(20)

            Divider()

            // MARK: - Footer Buttons
            HStack {
                Button {
                    openHomePage()
                } label: {
                    Label(L.homePage, systemImage: "house")
                }

                Button(L.about) {
                    showAbout()
                }

                Spacer()

                Button(L.reset) {
                    resetToDefaults()
                }
            }
            .padding(16)
        }
        .frame(width: 640, height: 480)
        .id(localization.currentLanguage)  // Force refresh when language changes
    }

    // MARK: - Actions

    private func showMacroEditor() {
        MacroEditorWindowController.shared.showEditor()
    }

    private func openHomePage() {
        if let url = URL(string: "https://github.com/hieunguyen1053/Unikey") {
            NSWorkspace.shared.open(url)
        }
    }

    private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    private func updateLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
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
            NSLog("Unikey: Launch at login requires macOS 13.0 or later")
        }
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
        localization.currentLanguage = .vietnamese
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

class PreferencesWindowManager: NSObject, NSWindowDelegate {
    static let shared = PreferencesWindowManager()

    private(set) var window: NSWindow?

    func showPreferences() {
        if window == nil {
            let preferencesView = PreferencesView()
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window?.title = "Unikey"
            window?.contentView = NSHostingView(rootView: preferencesView)
            window?.center()
            window?.delegate = self
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closePreferences() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
