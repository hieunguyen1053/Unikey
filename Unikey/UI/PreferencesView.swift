// PreferencesView.swift
// SwiftUI-based Preferences View matching Windows Unikey layout
// Unikey Vietnamese Input Method

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

    // MARK: - Constants
    private var characterSets: [String] {
        [
            "charset.unicode".localized,
            "charset.vni".localized,
            "charset.tcvn3".localized,
            "VIQR",
        ]
    }

    private var inputMethods: [String] {
        [
            "input.telex".localized,
            "input.vni".localized,
            "input.viqr".localized,
            "input.microsoft".localized,
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Content Area
            VStack(spacing: 16) {
                // MARK: - Controls Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        // Character Set
                        HStack {
                            Text("prefs.charset".localized)
                                .frame(width: 100, alignment: .trailing)
                            Picker("", selection: $characterSetIndex) {
                                ForEach(0..<characterSets.count, id: \.self) {
                                    index in
                                    Text(characterSets[index]).tag(index)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }

                        // Input Method
                        HStack {
                            Text("prefs.input_method".localized)
                                .frame(width: 100, alignment: .trailing)
                            Picker("", selection: $inputMethodIndex) {
                                ForEach(0..<inputMethods.count, id: \.self) {
                                    index in
                                    Text(inputMethods[index]).tag(index)
                                }
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
                            Text("prefs.switch_key".localized)
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
                    Text("prefs.controls".localized)
                        .font(.headline)
                }

                HStack(alignment: .top, spacing: 16) {
                    // MARK: - Other Options
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(
                                "prefs.free_marking".localized,
                                isOn: $freeMarking
                            )
                            Toggle(
                                "prefs.modern_style".localized,
                                isOn: $modernStyle
                            )
                            Toggle(
                                "prefs.clipboard_unicode".localized,
                                isOn: $clipboardForUnicode
                            )
                            Toggle(
                                "prefs.spell_check".localized,
                                isOn: $spellCheck
                            )
                            Toggle(
                                "prefs.auto_restore".localized,
                                isOn: $autoRestore
                            )
                            Toggle(
                                "prefs.show_notification".localized,
                                isOn: $showNotification
                            )
                        }
                        .padding(8)
                    } label: {
                        Text("prefs.other_options".localized)
                            .font(.headline)
                    }

                    VStack(spacing: 16) {
                        // MARK: - Macro Options
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(
                                    "prefs.enable_macro".localized,
                                    isOn: $macroEnabled
                                )
                                Toggle(
                                    "prefs.macro_when_off".localized,
                                    isOn: $macroWhenVietnamese
                                )

                                Button("prefs.macro_table".localized) {
                                    showMacroEditor()
                                }
                                .padding(.top, 4)
                            }
                            .padding(8)
                        } label: {
                            Text("prefs.macro_options".localized)
                                .font(.headline)
                        }

                        // MARK: - System
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(
                                    "prefs.show_on_startup".localized,
                                    isOn: $showDialogOnStartup
                                )
                                Toggle(
                                    "prefs.launch_at_login".localized,
                                    isOn: $launchAtLogin
                                )
                                .onChange(of: launchAtLogin) { newValue in
                                    updateLaunchAtLogin(enabled: newValue)
                                }

                                // Language Picker
                                HStack {
                                    Text("prefs.language".localized + ":")
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
                                        Text("lang.vietnamese".localized).tag(
                                            AppLanguage.vietnamese
                                        )
                                        Text("lang.english".localized).tag(
                                            AppLanguage.english
                                        )
                                    }
                                    .labelsHidden()
                                    .frame(width: 120)
                                }
                            }
                            .padding(8)
                        } label: {
                            Text("prefs.system".localized)
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
                    Label(
                        "prefs.help".localized,
                        systemImage: "questionmark.circle"
                    )
                }

                Button("prefs.about".localized) {
                    showAbout()
                }

                Spacer()

                Button("prefs.reset".localized) {
                    resetToDefaults()
                }
            }
            .padding(16)
        }
        .frame(width: 580, height: 450)
        .id(localization.currentLanguage)  // Force refresh when language changes
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

class PreferencesWindowManager {
    static let shared = PreferencesWindowManager()

    private var window: NSWindow?

    func showPreferences() {
        if window == nil {
            let preferencesView = PreferencesView()
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 580, height: 450),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window?.title = "prefs.title".localized
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
