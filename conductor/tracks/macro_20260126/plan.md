# Implementation Plan: Macro Support with Sorted Array Linear Search

## Phase 1: Core Engine & Persistence Refactoring
- [ ] Task: Refactor `MacroItem` and `MacroTable` to use Plist persistence
    - [ ] Write unit tests for `.plist` saving and loading in `UnikeyTests/MacroTests.swift`
    - [ ] Update `macroFilePath` to use `macros.plist`
    - [ ] Replace `JSONEncoder`/`JSONDecoder` with `PropertyListEncoder`/`PropertyListDecoder`
- [ ] Task: Refactor Core Logic for "Linear Search on Sorted Array"
    - [ ] Write unit tests for Linear Search behavior (specifically verifying it works correctly with lazy sorting)
    - [ ] Refactor `MacroTable.lookup` to perform a linear search (O(n))
    - [ ] Refactor `sortAndSave` to ensure sorting ONLY happens before saving to disk
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Core Engine & Persistence Refactoring' (Protocol in workflow.md)

## Phase 2: Input Method Integration
- [ ] Task: Integrate Macro Lookup into the Input Processor
    - [ ] Write unit tests for triggering macro replacement on Space/Enter in `UnikeyTests/MacroTriggerTests.swift`
    - [ ] Identify the correct hook in `UnikeyKeyProcessor.swift` or `UkEngine.swift` to intercept termination keys
    - [ ] Implement the expansion logic: if a macro exists for the current buffer, replace it and reset the buffer
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Input Method Integration' (Protocol in workflow.md)

## Phase 3: User Interface Enhancement
- [ ] Task: Polish the Macro Editor UI
    - [ ] Review `Unikey/UI/MacroEditorView.swift` (if exists) or create it
    - [ ] Ensure the UI allows adding/deleting macros and reflects the `MacroTable` state
    - [ ] Add "Export to Plist" and "Import from Plist" buttons to the UI
- [ ] Task: Final Quality Pass
    - [ ] Verify test coverage for all new macro logic (>80%)
    - [ ] Perform a full end-to-end test: Type a macro -> Space -> Replacement occurs
- [ ] Task: Conductor - User Manual Verification 'Phase 3: User Interface Enhancement' (Protocol in workflow.md)
