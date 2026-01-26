// MacroEditorView.swift
// SwiftUI-based Macro Editor View for Unikey
// Vietnamese Input Method for macOS

import SwiftUI
import UniformTypeIdentifiers

// MARK: - MacroEditorView

/// Main view for editing macro shorthand table
struct MacroEditorView: View {
    // MARK: - Environment & State

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var macroTable = MacroTable.shared

    @State private var selectedMacros: Set<UUID> = []
    @State private var searchText: String = ""
    @State private var showingAddSheet = false
    @State private var showingImportAlert = false
    @State private var editingMacro: MacroItem? = nil
    @State private var sortOrder: [KeyPathComparator<MacroItem>] = [
        .init(\.key, order: .forward)
    ]

    private var L: LocalizedStrings { localization.strings }

    // MARK: - Computed Properties

    private var filteredMacros: [MacroItem] {
        if searchText.isEmpty {
            return macroTable.macros
        }
        let lowercased = searchText.lowercased()
        return macroTable.macros.filter {
            $0.key.lowercased().contains(lowercased)
                || $0.text.lowercased().contains(lowercased)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            contentView

            Divider()

            // Footer
            footerView
        }
        .frame(width: 700, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingAddSheet) {
            MacroItemEditorSheet(
                mode: .add,
                onSave: { key, text in
                    macroTable.addItem(key: key, text: text)
                }
            )
        }
        .sheet(item: $editingMacro) { macro in
            MacroItemEditorSheet(
                mode: .edit(macro),
                onSave: { key, text in
                    macroTable.updateItem(id: macro.id, key: key, text: text)
                }
            )
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 16) {
            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(
                    localization.currentLanguage == .vietnamese
                        ? "Bảng gõ tắt" : "Macro Table"
                )
                .font(.title2)
                .fontWeight(.semibold)

                Text(
                    localization.currentLanguage == .vietnamese
                        ? "\(macroTable.count) từ viết tắt"
                        : "\(macroTable.count) shortcuts"
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(
                    localization.currentLanguage == .vietnamese
                        ? "Tìm kiếm..." : "Search...",
                    text: $searchText
                )
                .textFieldStyle(.plain)
                .frame(width: 150)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarView

            // Table
            if filteredMacros.isEmpty {
                emptyStateView
            } else {
                tableView
            }
        }
    }

    // MARK: - Toolbar

    private var toolbarView: some View {
        HStack(spacing: 8) {
            // Add
            Button {
                showingAddSheet = true
            } label: {
                Label(
                    localization.currentLanguage == .vietnamese
                        ? "Thêm" : "Add",
                    systemImage: "plus"
                )
            }
            .buttonStyle(.bordered)

            // Edit
            Button {
                if let selected = selectedMacros.first,
                    let macro = macroTable.macros.first(where: {
                        $0.id == selected
                    })
                {
                    editingMacro = macro
                }
            } label: {
                Label(
                    localization.currentLanguage == .vietnamese
                        ? "Sửa" : "Edit",
                    systemImage: "pencil"
                )
            }
            .buttonStyle(.bordered)
            .disabled(selectedMacros.count != 1)

            // Delete
            Button {
                macroTable.deleteItems(ids: selectedMacros)
                selectedMacros.removeAll()
            } label: {
                Label(
                    localization.currentLanguage == .vietnamese
                        ? "Xóa" : "Delete",
                    systemImage: "trash"
                )
            }
            .buttonStyle(.bordered)
            .disabled(selectedMacros.isEmpty)

            Divider()
                .frame(height: 20)

            // Import
            Button {
                importMacros()
            } label: {
                Label(
                    localization.currentLanguage == .vietnamese
                        ? "Nhập" : "Import",
                    systemImage: "square.and.arrow.down"
                )
            }
            .buttonStyle(.bordered)

            // Export
            Button {
                exportMacros()
            } label: {
                Label(
                    localization.currentLanguage == .vietnamese
                        ? "Xuất" : "Export",
                    systemImage: "square.and.arrow.up"
                )
            }
            .buttonStyle(.bordered)
            .disabled(macroTable.macros.isEmpty)

            Spacer()

            // Clear All
            if !macroTable.macros.isEmpty {
                Button(role: .destructive) {
                    withAnimation {
                        macroTable.initTable()
                        macroTable.saveMacros()
                        selectedMacros.removeAll()
                    }
                } label: {
                    Text(
                        localization.currentLanguage == .vietnamese
                            ? "Xóa tất cả" : "Clear All"
                    )
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Table View

    private var tableView: some View {
        Table(filteredMacros, selection: $selectedMacros, sortOrder: $sortOrder)
        {
            TableColumn(
                localization.currentLanguage == .vietnamese
                    ? "Từ viết tắt" : "Shortcut",
                value: \.key
            ) { macro in
                Text(macro.key)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.accentColor)
            }
            .width(min: 100, ideal: 150, max: 200)

            TableColumn(
                localization.currentLanguage == .vietnamese
                    ? "Thay thế bằng" : "Replacement",
                value: \.text
            ) { macro in
                Text(macro.text)
                    .lineLimit(2)
            }
        }
        .contextMenu(forSelectionType: UUID.self) { selection in
            if selection.count == 1, let id = selection.first,
                let macro = macroTable.macros.first(where: { $0.id == id })
            {
                Button {
                    editingMacro = macro
                } label: {
                    Label(
                        localization.currentLanguage == .vietnamese
                            ? "Sửa..." : "Edit...",
                        systemImage: "pencil"
                    )
                }
            }

            if !selection.isEmpty {
                Button(role: .destructive) {
                    macroTable.deleteItems(ids: selection)
                    selectedMacros.removeAll()
                } label: {
                    Label(
                        localization.currentLanguage == .vietnamese
                            ? "Xóa" : "Delete",
                        systemImage: "trash"
                    )
                }
            }
        } primaryAction: { selection in
            if selection.count == 1, let id = selection.first,
                let macro = macroTable.macros.first(where: { $0.id == id })
            {
                editingMacro = macro
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            if searchText.isEmpty {
                Text(
                    localization.currentLanguage == .vietnamese
                        ? "Chưa có từ viết tắt nào"
                        : "No shortcuts yet"
                )
                .font(.title3)
                .foregroundColor(.secondary)

                Text(
                    localization.currentLanguage == .vietnamese
                        ? "Nhấn \"Thêm\" để thêm từ viết tắt mới"
                        : "Click \"Add\" to create a new shortcut"
                )
                .font(.caption)
                .foregroundColor(.secondary)

                Button {
                    showingAddSheet = true
                } label: {
                    Label(
                        localization.currentLanguage == .vietnamese
                            ? "Thêm từ viết tắt" : "Add Shortcut",
                        systemImage: "plus"
                    )
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            } else {
                Text(
                    localization.currentLanguage == .vietnamese
                        ? "Không tìm thấy kết quả"
                        : "No results found"
                )
                .font(.title3)
                .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer View

    private var footerView: some View {
        HStack {
            // Help text
            Text(
                localization.currentLanguage == .vietnamese
                    ? "Gõ từ viết tắt rồi nhấn Space để thay thế"
                    : "Type a shortcut and press Space to replace"
            )
            .font(.caption)
            .foregroundColor(.secondary)

            Spacer()

            Button(
                localization.currentLanguage == .vietnamese ? "Đóng" : "Close"
            ) {
                macroTable.saveMacros()
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Actions

    private func importMacros() {
        let panel = NSOpenPanel()
        panel.title =
            localization.currentLanguage == .vietnamese
            ? "Chọn file macro" : "Select Macro File"
        panel.allowedContentTypes = [.plainText, .json, .propertyList]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { response in
            if response == .OK, let url = panel.url {
                let ext = url.pathExtension.lowercased()
                
                if ext == "plist" {
                    // Plist format
                    if let data = try? Data(contentsOf: url),
                       let items = try? PropertyListDecoder().decode([MacroItem].self, from: data) {
                        for item in items {
                            macroTable.addItem(key: item.key, text: item.text)
                        }
                    }
                } else if ext == "json" {
                    // JSON format
                    if let data = try? Data(contentsOf: url),
                        let items = try? JSONDecoder().decode(
                            [MacroItem].self,
                            from: data
                        )
                    {
                        for item in items {
                            macroTable.addItem(key: item.key, text: item.text)
                        }
                    }
                } else {
                    // Text format
                    _ = macroTable.loadFromFile(url.path)
                }
            }
        }
    }

    private func exportMacros() {
        let panel = NSSavePanel()
        panel.title =
            localization.currentLanguage == .vietnamese
            ? "Lưu file macro" : "Save Macro File"
        panel.nameFieldStringValue = "unikey_macros"
        panel.allowedContentTypes = [.plainText, .propertyList]
        panel.isExtensionHidden = false

        panel.begin { response in
            if response == .OK, let url = panel.url {
                let ext = url.pathExtension.lowercased()
                if ext == "plist" {
                    // Export as Plist
                    if let data = try? PropertyListEncoder().encode(macroTable.macros) {
                        try? data.write(to: url)
                    }
                } else {
                    // Default to text
                    _ = macroTable.exportToFile(url.path)
                }
            }
        }
    }
}

// MARK: - MacroItemEditorSheet

/// Sheet for adding or editing a macro item
struct MacroItemEditorSheet: View {
    enum Mode: Identifiable {
        case add
        case edit(MacroItem)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let item): return item.id.uuidString
            }
        }
    }

    let mode: Mode
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var key: String = ""
    @State private var text: String = ""
    @State private var showError = false
    @State private var errorMessage = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text(
                isEditing
                    ? (localization.currentLanguage == .vietnamese
                        ? "Sửa từ viết tắt" : "Edit Shortcut")
                    : (localization.currentLanguage == .vietnamese
                        ? "Thêm từ viết tắt" : "Add Shortcut")
            )
            .font(.headline)

            // Form
            Form {
                TextField(
                    localization.currentLanguage == .vietnamese
                        ? "Từ viết tắt:" : "Shortcut:",
                    text: $key
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

                TextField(
                    localization.currentLanguage == .vietnamese
                        ? "Thay thế bằng:" : "Replacement:",
                    text: $text,
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)
                .frame(width: 300)
            }

            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Buttons
            HStack {
                Button(
                    localization.currentLanguage == .vietnamese
                        ? "Hủy" : "Cancel"
                ) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(
                    localization.currentLanguage == .vietnamese ? "Lưu" : "Save"
                ) {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(
                    key.trimmingCharacters(in: .whitespaces).isEmpty
                        || text.trimmingCharacters(in: .whitespaces).isEmpty
                )
            }
        }
        .padding(24)
        .frame(width: 400)
        .onAppear {
            if case .edit(let macro) = mode {
                key = macro.key
                text = macro.text
            }
        }
    }

    private func save() {
        let trimmedKey = key.trimmingCharacters(in: .whitespaces)
        let trimmedText = text.trimmingCharacters(in: .whitespaces)

        if trimmedKey.isEmpty {
            errorMessage =
                localization.currentLanguage == .vietnamese
                ? "Từ viết tắt không được để trống"
                : "Shortcut cannot be empty"
            showError = true
            return
        }

        if trimmedText.isEmpty {
            errorMessage =
                localization.currentLanguage == .vietnamese
                ? "Nội dung thay thế không được để trống"
                : "Replacement cannot be empty"
            showError = true
            return
        }

        // Check for duplicates when adding
        if case .add = mode {
            if MacroTable.shared.lookup(key: trimmedKey) != nil {
                errorMessage =
                    localization.currentLanguage == .vietnamese
                    ? "Từ viết tắt này đã tồn tại"
                    : "This shortcut already exists"
                showError = true
                return
            }
        }

        onSave(trimmedKey, trimmedText)
        dismiss()
    }
}

// MARK: - MacroEditorWindowController

/// Window controller for macro editor
class MacroEditorWindowController {
    static let shared = MacroEditorWindowController()

    private var window: NSWindow?

    func showEditor() {
        if window == nil {
            let macroEditorView = MacroEditorView()
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window?.isReleasedWhenClosed = false
            window?.title =
                LocalizationManager.shared.currentLanguage == .vietnamese
                ? "Bảng gõ tắt - Unikey"
                : "Macro Table - Unikey"
            window?.contentView = NSHostingView(rootView: macroEditorView)
            window?.center()
            window?.minSize = NSSize(width: 500, height: 400)
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeEditor() {
        window?.close()
    }
}

// MARK: - Preview

#Preview {
    MacroEditorView()
}
