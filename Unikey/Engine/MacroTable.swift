// Unikey Swift Engine
// Ported from x-unikey-1.0.4/src/ukengine/mactab.h
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port by Jules

import Foundation

// Assuming StdVnChar is UInt16 or similar (Unicode)
// In Swift we can use String or [UInt16]

public class MacroTable {
    private struct MacroDef {
        var key: String
        var text: String
    }

    private var macros: [MacroDef] = []

    public init() {
    }

    public func initTable() {
        macros.removeAll()
    }

    // In C++: const StdVnChar *lookup(StdVnChar *key);
    // Swift: lookup(key: String) -> String?
    public func lookup(key: String) -> String? {
        // C++ uses bsearch. We can use dictionary or linear search for simplicity,
        // or binary search if sorted.
        // C++ sorts the table.
        // Let's optimize if needed, but linear for now or dict.
        // C++ keeps it sorted.
        // Note: C++ uses case-insensitive lookup (STD_TO_LOWER).

        let keyLower = key.lowercased()
        // Binary search?
        // Let's assume sorted.
        // Or just firstMatch.
        for m in macros {
            if m.key.lowercased() == keyLower {
                return m.text
            }
        }
        return nil
    }

    public func loadFromFile(_ fname: String) -> Bool {
        // Stub implementation
        return false
    }

    public func addItem(key: String, text: String) {
        macros.append(MacroDef(key: key, text: text))
        // Should sort
        macros.sort { $0.key.lowercased() < $1.key.lowercased() }
    }
}
