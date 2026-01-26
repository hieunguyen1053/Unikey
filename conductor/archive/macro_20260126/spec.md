# Specification: Macro Support with Sorted Array Linear Search

## Overview
This track implements a full-featured Macro system for Unikey. Users can define short abbreviations (e.g., "vn") that automatically expand into full phrases (e.g., "Việt Nam") upon pressing a trigger key (Space or Enter).

## Functional Requirements
- **Core Logic:**
  - Store macros in a `MacroTable` class using an array of `MacroEntry` structs.
  - Implementation of "Linear Search on Sorted Array": The search algorithm will perform a linear scan. While the array is intended to be sorted for potential future optimizations (like early exit), it will be sorted lazily on load and save.
- **Trigger Behavior:**
  - Expansion occurs immediately when a termination key (Space, Enter, or punctuation) is detected.
- **Persistence:**
  - Macro definitions will be saved to and loaded from a `.plist` file in the application support directory.
- **UI/UX:**
  - A dedicated "Macro Editor" view in the Preferences window.
  - Users can add, delete, and modify macro entries.
  - Changes are saved to disk upon closing the editor or manual save.

## Non-Functional Requirements
- **Performance:** Macro lookup must be instantaneous (<10ms) to avoid typing lag.
- **Reliability:** File I/O for persistence should handle edge cases like corrupted files or restricted permissions gracefully.

## Acceptance Criteria
1. Typing a defined macro abbreviation followed by Space expands the text correctly.
2. Macros added via the UI persist after the application is restarted.
3. The internal search logic uses the specified Linear Search approach.
4. The macro list in the UI is sorted alphabetically by abbreviation.

## Out of Scope
- Complex macro scripting or variables (e.g., date/time insertion).
- Multi-word abbreviations.
