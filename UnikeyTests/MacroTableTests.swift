import XCTest
@testable import Unikey

class MacroTableTests: XCTestCase {
    var macroTable: MacroTable!

    override func setUp() {
        super.setUp()
        macroTable = MacroTable()
        macroTable.initTable()
    }

    override func tearDown() {
        macroTable = nil
        super.tearDown()
    }

    func testLookup_ExistingMacro() {
        macroTable.addItem(key: "test", text: "replacement")
        XCTAssertEqual(macroTable.lookup(key: "test"), "replacement")
    }

    func testLookup_NonExistentMacro() {
        XCTAssertNil(macroTable.lookup(key: "nonexistent"))
    }

    func testLookup_CaseInsensitive() {
        macroTable.addItem(key: "TestKey", text: "CaseReplacement")
        XCTAssertEqual(macroTable.lookup(key: "testkey"), "CaseReplacement")
        XCTAssertEqual(macroTable.lookup(key: "TESTKEY"), "CaseReplacement")
        XCTAssertEqual(macroTable.lookup(key: "TestKey"), "CaseReplacement")
    }

}
