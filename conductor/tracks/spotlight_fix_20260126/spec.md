# Specification: Fix Duplicate Characters in Spotlight (Telex)

## Overview
Users experience a "ghosting" character issue when typing quickly in macOS Spotlight search using the Telex input method. For example, typing "Truyện" (t-r-u-y-e-e-n-j) results in "Truyeện". The issue is most prevalent when Spotlight's suggestion/autocomplete UI is active.

## Problem Description
When the Unikey engine processes a character that should trigger a replacement (e.g., `ee` -> `ê` or `as` -> `á`), it typically sends backspaces to delete the previous character(s) before sending the new combined character. In Spotlight, if a suggestion appears, the text field state may change or the cursor may be moved/re-selected by the system. This causes the backspace events to be ignored or misaligned, leaving the original character behind.

## Functional Requirements
- **Reliable Replacement:** Ensure that character replacements (double-taps for circumflexes, tone mark keys) correctly replace the preceding character even when Spotlight suggestions are active.
- **Race Condition Mitigation:** Implement logic to handle or retry backspace operations if the system's text state is rapidly changing.
- **Context Awareness:** If possible, detect if the active application/field is Spotlight and apply specific event-handling optimizations.

## Non-Functional Requirements
- **Latency:** The fix must not introduce perceptible lag during fast typing.
- **Compatibility:** The fix must not break standard typing behavior in other applications like Notes, Browsers, or Terminals.

## Acceptance Criteria
- Typing "Truyện" at high speed in Spotlight search result in exactly "Truyện", not "Truyeện".
- Typing "đ", "â", "ê", "ô", "ư", "ơ" via Telex shortcuts in Spotlight works consistently.
- Tone marks (s, f, r, x, j) correctly transform words in Spotlight without leaving the marker key behind.
- No regression in typing performance or accuracy in other macOS applications.

## Out of Scope
- Fixing general Spotlight performance issues.
- Issues related to VNI (unless they share the same root cause and are trivial to fix alongside).
