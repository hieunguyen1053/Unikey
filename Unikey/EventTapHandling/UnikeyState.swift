// UnikeyState.swift
// State management for Unikey event handling
// Mirrors xim.c state variables (lines 100-106)
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port

import Foundation

/// Global state management for Unikey event handling
/// Based on xim.c state variables
public class UnikeyState {

  // MARK: - Commit State (xim.c lines 101-104)

  /// PendingCommit - waiting for commit confirmation
  public var pendingCommit: Bool = false

  /// PostponeKeyEv - whether to postpone key events
  public var postponeKeyEv: Bool = false

  /// PostponeCount - count of postponed events
  public var postponeCount: Int = 0

  /// DataCommit - whether there's data to commit
  public var dataCommit: Bool = false

  // MARK: - Mode State

  /// UkTriggering - currently processing a trigger key
  public var ukTriggering: Bool = false

  /// Vietnamese mode enabled (GlobalOpt.enabled)
  public var vietnameseEnabled: Bool = true

  // MARK: - Caps State (xim.c: UnikeyCapsLockOn, UnikeyShiftPressed)

  /// Whether CapsLock is on
  public var capsLockOn: Bool = false

  /// Whether Shift is pressed
  public var shiftPressed: Bool = false

  // MARK: - Initialization

  public init() {}

  // MARK: - Methods

  /// Reset state to initial values
  /// Mirrors xim.c: resetState() (lines 1303-1310)
  public func reset() {
    pendingCommit = false
    postponeKeyEv = false
    postponeCount = 0
    dataCommit = false
  }

  /// Update caps state
  /// Mirrors xim.c: UnikeySetCapsState() from unikey.cpp
  public func setCapsState(shiftPressed: Bool, capsLockOn: Bool) {
    self.shiftPressed = shiftPressed
    self.capsLockOn = capsLockOn
  }
}
