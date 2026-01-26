// Unikey Swift Engine
// Ported from x-unikey-1.0.4/src/ukengine/mactab.h
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Jules

import Combine
import Foundation

// MARK: - MacroItem Model

/// Represents a single macro item (key -> replacement text)
public struct MacroItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var key: String
    public var text: String

    public init(id: UUID = UUID(), key: String, text: String) {
        self.id = id
        self.key = key
        self.text = text
    }
}

// MARK: - MacroTable

/// Manages macro definitions for auto-text replacement
public class MacroTable: ObservableObject {
    // MARK: - Singleton

    public static let shared = MacroTable()

    // MARK: - Published Properties

    @Published public private(set) var macros: [MacroItem] = []

    // MARK: - Private Properties

    private let fileManager = FileManager.default
    private var macroFilePath: URL

    // Lookup cache for performance
    private var lookupCache: [String: String] = [:]

    // MARK: - Initialization

    public init(fileURL: URL? = nil) {
        if let url = fileURL {
            self.macroFilePath = url
        } else {
            let appSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            let unikeyDir = appSupport.appendingPathComponent(
                "Unikey",
                isDirectory: true
            )

            // Create directory if needed
            if !fileManager.fileExists(atPath: unikeyDir.path) {
                try? fileManager.createDirectory(
                    at: unikeyDir,
                    withIntermediateDirectories: true
                )
            }
            self.macroFilePath = unikeyDir.appendingPathComponent("macros.plist")
        }
        loadMacros()
    }

    // MARK: - Public Methods

    /// Initialize/clear table
    public func initTable() {
        macros.removeAll()
        lookupCache.removeAll()
    }

    /// Lookup macro by key (case-insensitive)
    public func lookup(key: String) -> String? {
        let keyLower = key.lowercased()

        // Check cache first
        if let cached = lookupCache[keyLower] {
            return cached
        }

        // Binary search since macros are sorted
        if let result = macros.first(where: { $0.key.lowercased() == keyLower }
        )?.text {
            lookupCache[keyLower] = result
            return result
        }

        return nil
    }

    /// Add a new macro
    public func addItem(key: String, text: String) {
        // Check if key already exists
        if let existingIndex = macros.firstIndex(where: {
            $0.key.lowercased() == key.lowercased()
        }) {
            // Update existing
            macros[existingIndex].text = text
        } else {
            // Add new
            macros.append(MacroItem(key: key, text: text))
        }
        sortAndSave()
    }

    /// Update an existing macro
    public func updateItem(id: UUID, key: String, text: String) {
        if let index = macros.firstIndex(where: { $0.id == id }) {
            macros[index].key = key
            macros[index].text = text
            sortAndSave()
        }
    }

    /// Delete a macro by ID
    public func deleteItem(id: UUID) {
        macros.removeAll { $0.id == id }
        sortAndSave()
    }

    /// Delete multiple macros
    public func deleteItems(ids: Set<UUID>) {
        macros.removeAll { ids.contains($0.id) }
        sortAndSave()
    }

    /// Get all macros
    public func getAllMacros() -> [MacroItem] {
        return macros
    }

    /// Get macro count
    public var count: Int {
        return macros.count
    }

    // MARK: - File Operations

    /// Load macros from Plist file
    public func loadMacros() {
        guard fileManager.fileExists(atPath: macroFilePath.path) else {
            NSLog("MacroTable: No macro file found at \(macroFilePath.path)")
            return
        }

        do {
            let data = try Data(contentsOf: macroFilePath)
            try decodeMacros(from: data)
            NSLog("MacroTable: Loaded \(macros.count) macros")
        } catch {
            NSLog("MacroTable: Failed to load macros: \(error)")
        }
    }

    /// Save macros to Plist file
    public func saveMacros() {
        do {
            let data = try encodeMacros()
            try data.write(to: macroFilePath)
            NSLog("MacroTable: Saved \(macros.count) macros")
        } catch {
            print("MacroTable: Failed to save macros: \(error)")
            NSLog("MacroTable: Failed to save macros: \(error)")
        }
    }
    
    // MARK: - Helpers for Testing
    
    internal func encodeMacros() throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml // XML for readability/debug, change to binary later if needed
        return try encoder.encode(macros)
    }
    
    internal func decodeMacros(from data: Data) throws {
        let decoder = PropertyListDecoder()
        macros = try decoder.decode([MacroItem].self, from: data)
        rebuildCache()
    }

    /// Load macros from a file (legacy format: key:text per line)
    public func loadFromFile(_ fname: String) -> Bool {
        let url = URL(fileURLWithPath: fname)

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            NSLog("MacroTable: Cannot read file \(fname)")
            return false
        }

        initTable()

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Format: key:text or key=text
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[..<colonIndex]).trimmingCharacters(
                    in: .whitespaces
                )
                let text = String(trimmed[trimmed.index(after: colonIndex)...])
                    .trimmingCharacters(
                        in: .whitespaces
                    )
                if !key.isEmpty && !text.isEmpty {
                    macros.append(MacroItem(key: key, text: text))
                }
            } else if let equalIndex = trimmed.firstIndex(of: "=") {
                let key = String(trimmed[..<equalIndex]).trimmingCharacters(
                    in: .whitespaces
                )
                let text = String(trimmed[trimmed.index(after: equalIndex)...])
                    .trimmingCharacters(
                        in: .whitespaces
                    )
                if !key.isEmpty && !text.isEmpty {
                    macros.append(MacroItem(key: key, text: text))
                }
            }
        }

        sortAndSave()
        NSLog("MacroTable: Imported \(macros.count) macros from \(fname)")
        return true
    }

    /// Export macros to a text file (legacy format)
    public func exportToFile(_ fname: String) -> Bool {
        var content = "# Unikey Macro File\n# Format: key:replacement_text\n\n"

        for macro in macros {
            content += "\(macro.key):\(macro.text)\n"
        }

        do {
            try content.write(toFile: fname, atomically: true, encoding: .utf8)
            NSLog("MacroTable: Exported \(macros.count) macros to \(fname)")
            return true
        } catch {
            NSLog("MacroTable: Failed to export macros: \(error)")
            return false
        }
    }

    /// Import macros from data (for paste operations)
    public func importFromText(_ text: String) -> Int {
        var imported = 0
        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Format: key:text, key=text, or key\ttext
            var key: String?
            var value: String?

            if let colonIndex = trimmed.firstIndex(of: ":") {
                key = String(trimmed[..<colonIndex]).trimmingCharacters(
                    in: .whitespaces
                )
                value = String(trimmed[trimmed.index(after: colonIndex)...])
                    .trimmingCharacters(
                        in: .whitespaces
                    )
            } else if let tabIndex = trimmed.firstIndex(of: "\t") {
                key = String(trimmed[..<tabIndex]).trimmingCharacters(
                    in: .whitespaces
                )
                value = String(trimmed[trimmed.index(after: tabIndex)...])
                    .trimmingCharacters(
                        in: .whitespaces
                    )
            } else if let equalIndex = trimmed.firstIndex(of: "=") {
                key = String(trimmed[..<equalIndex]).trimmingCharacters(
                    in: .whitespaces
                )
                value = String(trimmed[trimmed.index(after: equalIndex)...])
                    .trimmingCharacters(
                        in: .whitespaces
                    )
            }

            if let k = key, let v = value, !k.isEmpty, !v.isEmpty {
                addItem(key: k, text: v)
                imported += 1
            }
        }

        return imported
    }

    // MARK: - Private Methods

    private func sortAndSave() {
        macros.sort { $0.key.lowercased() < $1.key.lowercased() }
        rebuildCache()
        saveMacros()
    }

    private func rebuildCache() {
        lookupCache.removeAll()
        for macro in macros {
            lookupCache[macro.key.lowercased()] = macro.text
        }
    }
}
