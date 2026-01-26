// UnikeyTests/MacroTests.swift

import XCTest
@testable import Unikey

class MacroTests: XCTestCase {
    
    // Test helper for permission-less verification
    func testMacroPersistenceLogic() throws {
        let table = MacroTable()
        table.initTable()
        table.addItem(key: "vn", text: "Việt Nam")
        
        // Test Encoding
        // Note: encodeMacros is internal, so @testable import Unikey is required
        let data = try table.encodeMacros()
        
        // Verify XML signature
        let str = String(data: data, encoding: .utf8)
        XCTAssertTrue(str?.contains("<?xml") ?? false, "Encoded data should contain XML header")
        XCTAssertTrue(str?.contains("Việt Nam") ?? false, "Encoded data should contain macro text")
        
        // Test Decoding
        let newTable = MacroTable()
        try newTable.decodeMacros(from: data)
        XCTAssertEqual(newTable.count, 1)
        XCTAssertEqual(newTable.lookup(key: "vn"), "Việt Nam")
    }
    
    /* 
    // Integration test with File System (requires permission/environment setup)
    func testMacroTableUsesPlistPersistence() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testURL = tempDir.appendingPathComponent("test_macros_\(UUID()).plist")
        
        let table = MacroTable(fileURL: testURL)
        table.initTable()
        table.addItem(key: "vn", text: "Việt Nam")
        table.saveMacros()
        
        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: testURL.path))
        
        // Cleanup
        try? FileManager.default.removeItem(at: testURL)
    }
    */
}
