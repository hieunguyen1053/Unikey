# Product Definition: Unikey for macOS

## Initial Concept
Unikey for macOS is an open-source Vietnamese input method (IME) for macOS, ported from the legendary UniKey C++ engine to native Swift. It aims to provide a fast, reliable, and transparent typing experience that respects legacy behavior while leveraging modern macOS capabilities.

## Target Audience
- **General macOS Users:** Individuals who need to type Vietnamese in everyday applications (browsers, office suites, messaging) using standard Telex or VNI methods.
- **Privacy-Conscious Users:** Users who prioritize transparency and security, seeking an open-source alternative to closed-source IMEs to ensure their keystrokes remain private.

## Vision & Core Goals
- **Native Performance:** Deliver a seamless, low-latency typing experience by using native Swift and optimized Apple APIs (EventTaps).
- **Legacy Compatibility:** Maintain faithful adherence to the original UniKey engine's behavior, ensuring a familiar experience for long-time users.
- **Transparency:** Provide an open-source codebase that allows for community auditing and contribution.

## Key Features
- **Robust Input Engines:** Complete support for Telex and VNI input methods with intelligent tone placement.
- **System Integration:** A lightweight menu bar application with "Start at Login" support and global state management.
- **Advanced Typing Aids:** Macro support for shorthand typing, basic spell checking, and automatic restoration of invalid words.
- **Localization:** Full support for both Vietnamese and English interfaces.

## User Experience Goals
- **Minimalist & "Invisible":** The application lives in the menu bar and stays out of the way, appearing only when configuration or status checks are needed.
- **Highly Configurable:** Offer power users granular control over engine logic, macro tables, and typing behaviors through a clean SwiftUI preferences interface.
