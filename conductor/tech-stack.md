# Tech Stack: Unikey for macOS

## Language & Core
- **Swift:** Primary programming language, leveraging modern concurrency and safety features.
- **macOS SDK:** Native application targeting macOS 13.0+ (Ventura).

## Frameworks & UI
- **SwiftUI:** Used for building modern, declarative user interfaces for preferences and onboarding.
- **Cocoa / AppKit:** Utilized for lifecycle management (`AppDelegate`) and deep system integration.

## System Integration
- **Core Graphics (CGEventTap):** The core mechanism for intercepting and processing global keyboard events.
- **Accessibility API:** Required for the Event Tap to function correctly across applications.

## Tools & Infrastructure
- **Xcode:** Primary development environment and build system (`.xcodeproj`).
- **XCTest:** Built-in framework for unit testing the engine and engine processing logic.
- **GitHub Actions:** CI/CD for automated builds and testing.
