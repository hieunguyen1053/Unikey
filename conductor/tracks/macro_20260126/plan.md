# Implementation Plan: Macro Support with Sorted Array Linear Search

## Phase 1: Core Engine & Persistence Refactoring
- [x] Task: Refactor `MacroItem` and `MacroTable` to use Plist persistence 586ee7c
    - [x] Write unit tests for `.plist` saving and loading in `UnikeyTests/MacroTests.swift`
    - [x] Update `macroFilePath` to use `macros.plist`
    - [x] Replace `JSONEncoder`/`JSONDecoder` with `PropertyListEncoder`/`PropertyListDecoder`
- [x] Task: Refactor Core Logic for "Linear Search on Sorted Array" 5636388
    - [x] Write unit tests for Linear Search behavior (specifically verifying it works correctly with lazy sorting)
    - [x] Refactor `MacroTable.lookup` to perform a linear search (O(n))
    - [x] Refactor `sortAndSave` to ensure sorting ONLY happens before saving to disk
- [x] Task: Conductor - User Manual Verification 'Phase 1: Core Engine & Persistence Refactoring' (Protocol in workflow.md) [checkpoint: 71498aa]

## Phase 2: Input Method Integration
- [x] Task: Integrate Macro Lookup into the Input Processor
    - [x] Write unit tests for triggering macro replacement on Space/Enter in `UnikeyTests/MacroTriggerTests.swift`
    - [x] Identify the correct hook in `UnikeyKeyProcessor.swift` or `UkEngine.swift` to intercept termination keys
    - [x] Implement the expansion logic: if a macro exists for the current buffer, replace it and reset the buffer
- [x] Task: Conductor - User Manual Verification 'Phase 2: Input Method Integration' (Protocol in workflow.md) [checkpoint: d221012]

## Phase 3: User Interface Enhancement
- [x] Task: Polish the Macro Editor UI
    - [x] Review `Unikey/UI/MacroEditorView.swift` (if exists) or create it
    - [x] Ensure the UI allows adding/deleting macros and reflects the `MacroTable` state
    - [x] Add "Export to Plist" and "Import from Plist" buttons to the UI
- [x] Task: Final Quality Pass
    - [x] Verify test coverage for all new macro logic (>80%)
    - [x] Perform a full end-to-end test: Type a macro -> Space -> Replacement occurs
- [ ] Task: Conductor - User Manual Verification 'Phase 3: User Interface Enhancement' (Protocol in workflow.md)
