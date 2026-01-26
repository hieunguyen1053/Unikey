# Implementation Plan: Fix Duplicate Characters in Spotlight (Telex)

## Phase 1: Investigation & Test Harnessing
In this phase, we will identify the precise timing and event sequence that causes the "ghost" character in Spotlight and build a simulation test.

- [ ] Task: Create a reproduction unit test suite
    - [ ] Create `Tests/MLKeyEngineSpotlightTests.swift`
    - [ ] Implement tests that simulate high-speed Telex sequences (e.g., `t-r-u-y-e-e-n-j`)
    - [ ] Use `XCTContext.runActivity` to trace event dispatch timing
- [ ] Task: Analyze existing EventTap dispatch logic
    - [ ] Review `MLKey/Core/EventTap.swift` (or equivalent) for event posting delays
    - [ ] Identify where `NSEvent` or `CGEvent` are posted back to the system
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Investigation & Test Harnessing' (Protocol in workflow.md)

## Phase 2: Core Engine Refinement
Refactor the event dispatch mechanism to ensure backspaces and replacements are treated as an atomic sequence or use a more robust delivery method.

- [ ] Task: Implement atomic event grouping
    - [ ] Modify the engine to group "delete + insert" operations into a single logical transaction if supported by the macOS API
    - [ ] Experiment with small, non-blocking delays (microseconds) between backspace and replacement character posting
- [ ] Task: Add context-specific handling for Spotlight
    - [ ] Implement detection for `com.apple.Spotlight` active process
    - [ ] Apply "Spotlight-safe" event dispatch parameters (e.g., increased event tap timeout)
- [ ] Task: Verify fix with unit tests
    - [ ] Run `MLKeyEngineSpotlightTests.swift` and ensure they pass under simulated speed
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Core Engine Refinement' (Protocol in workflow.md)

## Phase 3: Regression & Quality Assurance
Ensure the fix doesn't impact other applications and maintains performance.

- [ ] Task: Run full regression suite
    - [ ] Execute all existing engine tests to ensure no breakage in standard Telex/VNI logic
- [ ] Task: Performance benchmarking
    - [ ] Measure latency of the refined event dispatch logic to ensure it stays below the perception threshold
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Regression & Quality Assurance' (Protocol in workflow.md)
