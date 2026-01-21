// UnikeyInterface.swift
// Public interface for Unikey engine
// Mirrors ukinterface/unikey.h and unikey.cpp
// Copyright (C) 2000-2005 Pham Kim Long
// Swift port

import Foundation

/// Global output buffer type
public enum UnikeyOutputType {
    case normal
    case commit
    case noOutput
}

/// Public interface wrapper for Unikey engine
/// Mirrors unikey.h / unikey.cpp functions
public class UnikeyInterface {

    // MARK: - Singleton

    public static let shared = UnikeyInterface()

    // MARK: - Output Buffers (mirrors unikey.cpp globals)

    /// UnikeyBuf - output buffer
    public private(set) var ukBuffer: [UInt16] = []

    /// UnikeyBackspaces - number of backspaces needed
    public private(set) var ukBackspaces: Int = 0

    /// UnikeyBufChars - number of characters in buffer
    public private(set) var ukBufChars: Int = 0

    /// UnikeyOutput - output type
    public private(set) var ukOutput: UkOutputType = .normal

    // MARK: - Components

    private let engine: UkEngine
    private let sharedMem: UkSharedMem
    public let state: UnikeyState

    // MARK: - Initialization

    private init() {
        sharedMem = UkSharedMem()
        engine = UkEngine()
        state = UnikeyState()
    }

    // MARK: - Setup / Cleanup (unikey.cpp lines 118-138)

    /// Initialize Unikey module
    /// Mirrors: UnikeySetup()
    public func setup() {
        // Input is already initialized in UkSharedMem
        sharedMem.vietKey = 1
        engine.setCtrlInfo(sharedMem)
        setInputMethod(.telex)
        state.vietnameseEnabled = true

        // Set default options
        sharedMem.options.freeMarking = true
        sharedMem.options.modernStyle = false
        sharedMem.options.spellCheckEnabled = true
        sharedMem.options.autoNonVnRestore = false
        sharedMem.options.macroEnabled = true
    }

    /// Cleanup Unikey module
    /// Mirrors: UnikeyCleanup()
    public func cleanup() {
        // Nothing to deallocate in Swift
    }

    // MARK: - Options Properties

    /// Cho phép gõ tự do (đặt dấu ở bất kỳ vị trí nào)
    public var freeMarking: Bool {
        get { sharedMem.options.freeMarking }
        set { sharedMem.options.freeMarking = newValue }
    }

    /// Kiểu đặt dấu mới (hoà, uý) thay vì kiểu cũ (hòa, úy)
    public var modernStyle: Bool {
        get { sharedMem.options.modernStyle }
        set { sharedMem.options.modernStyle = newValue }
    }

    /// Bật kiểm tra chính tả
    public var spellCheckEnabled: Bool {
        get { sharedMem.options.spellCheckEnabled }
        set { sharedMem.options.spellCheckEnabled = newValue }
    }

    /// Tự động khôi phục phím với từ sai
    public var autoNonVnRestore: Bool {
        get { sharedMem.options.autoNonVnRestore }
        set { sharedMem.options.autoNonVnRestore = newValue }
    }

    /// Bật tính năng gõ tắt (macro)
    public var macroEnabled: Bool {
        get { sharedMem.options.macroEnabled }
        set { sharedMem.options.macroEnabled = newValue }
    }

    // MARK: - Key Filtering (unikey.cpp lines 141-153)

    /// Main character filter
    /// Mirrors: UnikeyFilter(unsigned int ch)
    public func filter(_ ch: UInt32) {
        ukBuffer = []
        ukBackspaces = 0
        ukBufChars = 0
        ukOutput = .normal

        var backs = 0
        var outBuf: [UInt16] = []
        var outSize = 0
        var outType: UkOutputType = .normal

        _ = engine.process(ch, &backs, &outBuf, &outSize, &outType)

        ukBackspaces = backs
        ukBuffer = outBuf
        ukBufChars = outSize
        ukOutput = outType
    }

    /// Put character without filtering
    /// Mirrors: UnikeyPutChar(unsigned int ch)
    public func putChar(_ ch: UInt32) {
        engine.pass(Int(ch))
        ukBuffer = []
        ukBackspaces = 0
        ukBufChars = 0
    }

    // MARK: - Backspace (unikey.cpp lines 168-173)

    /// Handle backspace press
    /// Mirrors: UnikeyBackspacePress()
    public func backspacePress() {
        ukBuffer = []
        ukBackspaces = 0
        ukBufChars = 0
        ukOutput = .normal

        var backs = 0
        var outBuf: [UInt16] = []
        var outSize = 0
        var outType: UkOutputType = .normal

        _ = engine.processBackspace(&backs, &outBuf, &outSize, &outType)

        ukBackspaces = backs
        ukBuffer = outBuf
        ukBufChars = outSize
        ukOutput = outType
    }

    // MARK: - Reset (unikey.cpp lines 156-159)

    /// Reset engine buffer
    /// Mirrors: UnikeyResetBuf()
    public func resetBuf() {
        engine.reset()
        state.reset()
    }

    // MARK: - Input Method (unikey.cpp lines 48-61)

    /// Set input method
    /// Mirrors: UnikeySetInputMethod(UkInputMethod im)
    public func setInputMethod(_ im: UkInputMethod) {
        sharedMem.input.setIM(im)
        engine.reset()
    }

    /// Get current input method
    public func getInputMethod() -> UkInputMethod {
        return sharedMem.input.getIM()
    }

    // MARK: - Caps State (unikey.cpp lines 65-70)

    /// Set caps state
    /// Mirrors: UnikeySetCapsState(int shiftPressed, int CapsLockOn)
    public func setCapsState(shiftPressed: Bool, capsLockOn: Bool) {
        state.setCapsState(shiftPressed: shiftPressed, capsLockOn: capsLockOn)
    }

    // MARK: - Options (unikey.cpp lines 81-96)

    /// Set options
    /// Mirrors: UnikeySetOptions(UnikeyOptions *pOpt)
    public func setOptions(
        freeMarking: Bool = true,
        modernStyle: Bool = false,
        spellCheckEnabled: Bool = true,
        autoNonVnRestore: Bool = false
    ) {
        sharedMem.options.freeMarking = freeMarking
        sharedMem.options.modernStyle = modernStyle
        sharedMem.options.spellCheckEnabled = spellCheckEnabled
        sharedMem.options.autoNonVnRestore = autoNonVnRestore
    }

    // MARK: - Restore (unikey.cpp lines 193-197)

    /// Restore key strokes
    /// Mirrors: UnikeyRestoreKeyStrokes()
    public func restoreKeyStrokes() {
        ukBuffer = []
        ukBackspaces = 0
        ukBufChars = 0
        ukOutput = .normal

        var backs = 0
        var outBuf: [UInt16] = []
        var outSize = 0
        var outType: UkOutputType = .normal

        _ = engine.restoreKeyStrokes(&backs, &outBuf, &outSize, &outType)

        ukBackspaces = backs
        ukBuffer = outBuf
        ukBufChars = outSize
        ukOutput = outType
    }

    // MARK: - Single Mode (unikey.cpp lines 162-165)

    /// Set single mode for typing Vietnamese in non-VN sequences
    /// Mirrors: UnikeySetSingleMode()
    public func setSingleMode() {
        engine.setSingleMode()
    }

    // MARK: - Accessors

    /// Get the engine instance
    public func getEngine() -> UkEngine {
        return engine
    }

    /// Get the shared memory instance
    public func getSharedMem() -> UkSharedMem {
        return sharedMem
    }

    /// Check if Vietnamese mode is enabled
    public var vietnameseEnabled: Bool {
        get { state.vietnameseEnabled }
        set { state.vietnameseEnabled = newValue }
    }
}
