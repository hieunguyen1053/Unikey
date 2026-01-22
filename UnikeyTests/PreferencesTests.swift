import XCTest
import Cocoa
@testable import Unikey

class PreferencesTests: XCTestCase {

    func testReopeningPreferencesWindow() {
        let manager = PreferencesWindowManager.shared

        // Ensure clean state
        if let currentWindow = manager.window {
            NotificationCenter.default.post(name: NSWindow.willCloseNotification, object: currentWindow)
        }

        // 1. Open Preferences for the first time
        manager.showPreferences()

        guard let firstWindow = manager.window else {
            XCTFail("Window should be created after showPreferences")
            return
        }
        XCTAssertNotNil(firstWindow)

        // 2. Simulate closing the window
        // In a real app, AppKit sends this notification when the window is closed.
        // We simulate it here to verify our delegate logic handles it.
        NotificationCenter.default.post(name: NSWindow.willCloseNotification, object: firstWindow)

        // 3. Verify reference is cleared
        XCTAssertNil(manager.window, "Window reference should be cleared after closing")

        // 4. Open Preferences again
        manager.showPreferences()

        guard let secondWindow = manager.window else {
            XCTFail("Window should be created again after showPreferences")
            return
        }
        XCTAssertNotNil(secondWindow)

        // Optional: Verify it's a new window or at least a valid one
        XCTAssertNotEqual(firstWindow, secondWindow, "A new window instance should be created")
    }
}
