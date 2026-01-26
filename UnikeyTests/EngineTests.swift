//
//  EngineTests.swift
//  UnikeyTests
//
//  Comprehensive Unit Tests for Unikey Engine
//  Inspired by XKey's VNEngineTests
//

import XCTest

@testable import Unikey

final class EngineTests: XCTestCase {

    var engine: UkEngine!
    var sharedMem: UkSharedMem!

    override func setUp() {
        super.setUp()
        // Initialize shared memory with default options
        sharedMem = UkSharedMem()
        sharedMem.vietKey = 1
        sharedMem.options.vietKeyEnabled = true
        sharedMem.options.freeMarking = true
        sharedMem.options.spellCheckEnabled = true
        sharedMem.options.modernStyle = true

        // Initialize engine
        engine = UkEngine()
        engine.setCtrlInfo(sharedMem)

        // Default to Telex
        sharedMem.input.setIM(.telex)
    }

    override func tearDown() {
        engine = nil
        sharedMem = nil
        super.tearDown()
    }

    /// Simulates typing and returns the result
    func typeAndGetResult(_ input: String, method: UkInputMethod = .telex)
        -> String
    {
        if sharedMem.input.getIM() != method {
            sharedMem.input.setIM(method)
        }
        engine.reset()

        var currentText = ""

        for char in input {
            let keyCode = UInt32(char.asciiValue ?? 0)
            var backs = 0
            var outBuf: [UInt16] = []
            var outSize = 0
            var outType: UkOutputType = .normal

            let ret = engine.process(
                keyCode,
                &backs,
                &outBuf,
                &outSize,
                &outType
            )

            if ret != 0 {
                if backs > 0 && backs <= currentText.count {
                    currentText.removeLast(backs)
                } else if backs > currentText.count {
                    currentText = ""
                }

                if outSize > 0 {
                    currentText += String(
                        utf16CodeUnits: outBuf,
                        count: outSize
                    )
                }
            } else {
                currentText.append(char)
            }
        }

        return currentText
    }

    // MARK: - Helper Methods

    /// Simulates typing a string and asserts the final output matches expectation.
    /// - Parameters:
    ///   - input: The string of characters to simulate typing.
    ///   - expected: The expected resulting string.
    ///   - method: The input method to use (default: .telex).
    ///   - file: The file where assertion is made (for error reporting).
    ///   - line: The line where assertion is made (for error reporting).
    func assertInput(
        _ input: String,
        produces expected: String,
        method: UkInputMethod = .telex,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Setup input method
        if sharedMem.input.getIM() != method {
            sharedMem.input.setIM(method)
        }
        engine.reset()

        var currentText = ""

        for char in input {
            let keyCode = UInt32(char.asciiValue ?? 0)
            var backs = 0
            var outBuf: [UInt16] = []
            var outSize = 0
            var outType: UkOutputType = .normal

            let ret = engine.process(
                keyCode,
                &backs,
                &outBuf,
                &outSize,
                &outType
            )

            // Simulate editor behavior
            if ret != 0 {
                // Apply backspaces
                if backs > 0 {
                    if backs > currentText.count {
                        // In unit test context, we shouldn't backspace beyond empty,
                        // but if engine requests it, it means our tracking is out of sync or engine logic expects context.
                        // For these simple word tests, we expect correct sync.
                        currentText = ""
                    } else {
                        currentText.removeLast(backs)
                    }
                }

                // Append new text
                if outSize > 0 {
                    let outString = String(
                        utf16CodeUnits: outBuf,
                        count: outSize
                    )
                    currentText += outString
                }
            } else {
                // Engine didn't handle -> System inserts character
                currentText.append(char)
            }
        }

        XCTAssertEqual(
            currentText,
            expected,
            "Input '\(input)' should produce '\(expected)'",
            file: file,
            line: line
        )
    }

    // ===========================================================================

    func testTL_VowelGemination_AA_Circumflex() {
        // a + a -> â (Circumflex)
        assertInput("aa", produces: "â")
    }

    func testTL_VowelGemination_EE_Circumflex() {
        // e + e -> ê (Circumflex)
        assertInput("ee", produces: "ê")
    }

    func testTL_VowelGemination_OO_Circumflex() {
        // o + o -> ô (Circumflex)
        assertInput("oo", produces: "ô")
    }

    func testTL_VowelGemination_DD_Barred() {
        // d + d -> đ (Barred D)
        assertInput("dd", produces: "đ")
    }

    func testTL_VowelModifier_AW_Breve() {
        // a + w -> ă (Breve)
        assertInput("aw", produces: "ă")
    }

    func testTL_VowelModifier_OW_Horn() {
        // o + w -> ơ (Horn)
        assertInput("ow", produces: "ơ")
    }

    func testTL_VowelModifier_UW_Horn() {
        // u + w -> ư (Horn)
        assertInput("uw", produces: "ư")
    }

    // ===========================================================================
    // MARK: - Section 3.1.2: Telex Tone Mapping
    // Test Matrix: Telex Tone Application
    // ===========================================================================

    func testTL_Tone_Sac_S() {
        // l + a + s -> lá (Acute/Sắc)
        assertInput("las", produces: "lá")
    }

    func testTL_Tone_Huyen_F() {
        // l + a + f -> là (Grave/Huyền)
        assertInput("laf", produces: "là")
    }

    func testTL_Tone_Hoi_R() {
        // l + a + r -> lả (Hook/Hỏi)
        assertInput("lar", produces: "lả")
    }

    func testTL_Tone_Nga_X() {
        // l + a + x -> lã (Tilde/Ngã)
        assertInput("lax", produces: "lã")
    }

    func testTL_Tone_Nang_J() {
        // l + a + j -> lạ (Dot Below/Nặng)
        assertInput("laj", produces: "lạ")
    }

    func testTL_Tone_Removal_Z() {
        // l + a + s + z -> la (Remove tone with Z)
        assertInput("lasz", produces: "la")
    }

    // ===========================================================================
    // MARK: - Section 3.1.2: Telex Ambiguity Resolution
    // Test Case TL-02: Double-tap escape for English words
    // ===========================================================================

    func testTL_AmbiguityResolution_DoubleToneEscape() {
        // Typing "pass" - second 's' should undo the tone
        // p + a + s -> pá, then + s -> pas
        assertInput("pass", produces: "pas")
    }

    func testTL_AmbiguityResolution_TripleDEscape() {
        // d + d + d -> dd (đ reverts to dd)
        assertInput("ddd", produces: "dd")
    }

    func testTL_AmbiguityResolution_TripleAEscape() {
        // a + a + a -> restore to aa
        assertInput("aaa", produces: "aa")
    }

    // ===========================================================================
    // MARK: - Section 3.2: VNI Input Method Validation
    // Test Matrix: VNI Transformations
    // ===========================================================================

    func testVN_Tone_Sac_1() {
        // a + 1 -> á (Sắc)
        assertInput("a1", produces: "á", method: .vni)
    }

    func testVN_Tone_Huyen_2() {
        // a + 2 -> à (Huyền)
        assertInput("a2", produces: "à", method: .vni)
    }

    func testVN_Tone_Hoi_3() {
        // a + 3 -> ả (Hỏi)
        assertInput("a3", produces: "ả", method: .vni)
    }

    func testVN_Tone_Nga_4() {
        // a + 4 -> ã (Ngã)
        assertInput("a4", produces: "ã", method: .vni)
    }

    func testVN_Tone_Nang_5() {
        // a + 5 -> ạ (Nặng)
        assertInput("a5", produces: "ạ", method: .vni)
    }

    func testVN_Mark_Circumflex_6() {
        // a + 6 -> â (Circumflex)
        assertInput("a6", produces: "â", method: .vni)
        assertInput("e6", produces: "ê", method: .vni)
        assertInput("o6", produces: "ô", method: .vni)
    }

    func testVN_Mark_Horn_7() {
        // o + 7 -> ơ, u + 7 -> ư (Horn)
        assertInput("o7", produces: "ơ", method: .vni)
        assertInput("u7", produces: "ư", method: .vni)
    }

    func testVN_Mark_Breve_8() {
        // a + 8 -> ă (Breve)
        assertInput("a8", produces: "ă", method: .vni)
    }

    func testVN_Mark_BarredD_9() {
        // d + 9 -> đ (Barred D)
        assertInput("d9", produces: "đ", method: .vni)
    }

    func testVN_Complex_Duoc() {
        // đ + ư + ợ + c -> được
        assertInput("d9uo75c", produces: "được", method: .vni)
    }

    // ===========================================================================
    // MARK: - Section 4.1: Diphthong Matrix
    // Extensive Diphthong Tests
    // ===========================================================================

    func testDP_AI_Mai() {
        // mái (roof) - Tone on 'a'
        assertInput("mais", produces: "mái")
    }

    func testDP_AO_Chao() {
        // cháo (porridge) - Tone on 'a'
        assertInput("chaos", produces: "cháo")
    }

    func testDP_AU_Mau() {
        // máu (blood) - Tone on 'a'
        assertInput("maus", produces: "máu")
    }

    func testDP_AU_Trau() {
        // trâu (buffalo) - Circumflex on 'a'
        assertInput("traau", produces: "trâu")
    }

    func testDP_AY_May() {
        // máy (machine) - Tone on 'a'
        assertInput("mays", produces: "máy")
    }

    func testDP_AY_Cay() {
        // cây (tree) - Circumflex on 'a'
        assertInput("caay", produces: "cây")
    }

    func testDP_EO_Meo() {
        // mèo (cat) - Tone on 'e'
        assertInput("meof", produces: "mèo")
    }

    func testDP_EU_Leu() {
        // lều (tent) - Circumflex ê with grave tone
        assertInput("leeuf", produces: "lều")
    }

    func testDP_IA_Mia() {
        // mía (sugarcane) - Tone on 'i'
        assertInput("mias", produces: "mía")
    }

    func testDP_IE_Bien() {
        // biển (sea) - Circumflex ê with hook tone
        assertInput("bieenr", produces: "biển")
    }

    func testDP_UA_Cua() {
        // cua (crab) - No tone
        assertInput("cua", produces: "cua")
    }

    func testDP_UA_Quan() {
        // quân (army) - Circumflex on 'a'
        assertInput("quaan", produces: "quân")
    }

    func testDP_UA_Mua() {
        // mưa (rain) - Horn on 'u'
        assertInput("muwa", produces: "mưa")
    }

    func testDP_UO_Muon() {
        // muốn (want) - Circumflex ô with acute tone
        assertInput("muoons", produces: "muốn")
    }

    func testDP_UY_Tuy() {
        // túy (marrow) - Old style: tone on 'u'
        sharedMem.options.modernStyle = false
        assertInput("tuys", produces: "túy")
    }

    func testDP_UO_Luon() {
        // lươn (eel) - Horn on both u and o
        assertInput("luown", produces: "lươn")
    }

    // ===========================================================================
    // MARK: - Section 4.1.2: Triphthong Matrix
    // ===========================================================================

    func testTP_IEU_Chieu() {
        // chiều (afternoon) - Tone on ê
        assertInput("chieeuf", produces: "chiều")
    }

    func testTP_YEU_Yeu() {
        // yêu (love) - Circumflex on e
        assertInput("yeeu", produces: "yêu")
    }

    func testTP_OAI_Oai() {
        // oải (weary) - Tone on a
        assertInput("oair", produces: "oải")
    }

    func testTP_OAY_Xoay() {
        // xoay (rotate) - No tone
        assertInput("xoay", produces: "xoay")
    }

    func testTP_UOI_Chuoi() {
        // chuối (banana) - Circumflex ô with acute tone
        assertInput("chuoois", produces: "chuối")
    }

    func testTP_UOI_Nguoi() {
        // người (person) - Horn on ư, ơ. Tone on ơ
        assertInput("nguowif", produces: "người")
    }

    func testTP_UOU_Ruou() {
        // rượu (alcohol) - Horn on ư, ơ. Dot below on ơ
        assertInput("ruowuj", produces: "rượu")
    }

    func testTP_UYA_Khuya() {
        // khuya (late night) - No tone
        assertInput("khuya", produces: "khuya")
    }

    func testTP_UYE_Chuyen() {
        // chuyện (story) - Circumflex ê with dot below
        assertInput("chuyeenj", produces: "chuyện")
    }

    // ===========================================================================
    // MARK: - Section 4.2: Tone Placement Old Style vs New Style
    // Test Matrix for Tone Placement Toggle
    // ===========================================================================

    func testTS_NewStyle_Hoa() {
        // New Style: hoà -> tone on 'a' (second vowel)
        sharedMem.options.modernStyle = true
        assertInput("hoaf", produces: "hoà")
    }

    func testTS_OldStyle_Hoa() {
        // Old Style: hòa -> tone on 'o' (first vowel)
        sharedMem.options.modernStyle = false
        assertInput("hoaf", produces: "hòa")
    }

    func testTS_NewStyle_Thuy() {
        // New Style: thuỷ -> tone on 'y'
        sharedMem.options.modernStyle = true
        assertInput("thuyr", produces: "thuỷ")
    }

    func testTS_OldStyle_Thuy() {
        // Old Style: thủy -> tone on 'u'
        sharedMem.options.modernStyle = false
        assertInput("thuyr", produces: "thủy")
    }

    func testTS_NewStyle_Toa() {
        // New Style: toà
        sharedMem.options.modernStyle = true
        assertInput("toaf", produces: "toà")
    }

    func testTS_OldStyle_Toa() {
        // Old Style: tòa
        sharedMem.options.modernStyle = false
        assertInput("toaf", produces: "tòa")
    }

    func testTS_NewStyle_Hoa_Dot() {
        // New Style: hoạ
        sharedMem.options.modernStyle = true
        assertInput("hoaj", produces: "hoạ")
    }

    func testTS_OldStyle_Hoa_Dot() {
        // Old Style: họa
        sharedMem.options.modernStyle = false
        assertInput("hoaj", produces: "họa")
    }

    func testTS_NewStyle_Loa() {
        // New Style: loá
        sharedMem.options.modernStyle = true
        assertInput("loas", produces: "loá")
    }

    func testTS_OldStyle_Loa() {
        // Old Style: lóa
        sharedMem.options.modernStyle = false
        assertInput("loas", produces: "lóa")
    }

    func testTS_NewStyle_Xoe() {
        // New Style: xoè
        sharedMem.options.modernStyle = true
        assertInput("xoef", produces: "xoè")
    }

    func testTS_OldStyle_Xoe() {
        // Old Style: xòe
        sharedMem.options.modernStyle = false
        assertInput("xoef", produces: "xòe")
    }

    func testTS_NewStyle_Uy() {
        // New Style: uý -> tone on y
        sharedMem.options.modernStyle = true
        assertInput("uys", produces: "uý")
    }

    func testTS_OldStyle_Uy() {
        // Old Style: úy -> tone on u
        sharedMem.options.modernStyle = false
        assertInput("uys", produces: "úy")
    }

    // ===========================================================================
    // MARK: - Section 4.3: Gi and Qu Ambiguity
    // ===========================================================================

    func testGQ_Gi_WithVowel_Gia() {
        // gi + a -> gia (i is part of consonant)
        // gi + a + f -> già (tone on 'a', NOT 'i')
        assertInput("giaf", produces: "già")
    }

    func testGQ_Gi_AsRhyme_Gi() {
        // gì - i is the vowel here
        assertInput("gif", produces: "gì")
    }

    func testGQ_Gi_WithE_Gieng() {
        // giếng - i is part of consonant, ê is vowel
        assertInput("gieengs", produces: "giếng")
    }

    func testGQ_Qu_WithA_Qua() {
        // quá - u is glide, a is vowel
        assertInput("quas", produces: "quá")
    }

    func testGQ_Qu_WithY_Quy() {
        // quý - u is glide, y is vowel
        assertInput("quys", produces: "quý")
    }

    func testGQ_Qu_WithE_Que() {
        // quế - u is glide, e is vowel
        assertInput("quees", produces: "quế")
    }

    func testGQ_Gi_Complex_Giang() {
        // giang - gi consonant, a vowel
        assertInput("giang", produces: "giang")
    }

    func testGQ_Gi_Complex_Giup() {
        // giúp - gi consonant, u vowel
        assertInput("giups", produces: "giúp")
    }

    // ===========================================================================
    // MARK: - Section 5.1: Smart Tone Positioning
    // In-fix vs Post-fix Tone
    // ===========================================================================

    func testSF_InfixTone_Toan() {
        // Infix: t o a s n -> toán (tone after 'a', before 'n')
        assertInput("toasn", produces: "toán")
    }

    func testSF_PostfixTone_Toan() {
        // Postfix: t o a n s -> toán (tone after word completion)
        assertInput("toans", produces: "toán")
    }

    func testSF_SmartTone_Truong() {
        // trường - complex horn vowel with tone
        assertInput("truowngf", produces: "trường")
    }

    func testSF_SmartTone_Duong() {
        // đường - đ + horn vowel + tone
        assertInput("dduowngf", produces: "đường")
    }

    // ===========================================================================
    // MARK: - Section 5.2: Auto-Restore Logic
    // ===========================================================================

    func testSF_AutoRestore_BackspaceRemovesTone() {
        // Type "tói", backspace should remove tone first
        // This tests the operation history stack
        let result1 = typeAndGetResult("tois")
        XCTAssertEqual(result1, "tói")

        // Note: Full backspace test requires different approach
        // as we'd need to simulate backspace key
    }

    func testSF_Restore_TripleType() {
        // Typing ooo should restore to oo (ô -> oo)
        assertInput("ooo", produces: "oo")
    }

    // ===========================================================================
    // MARK: - Section 5.5: The "W" Logic - Simple vs Standard Telex
    // ===========================================================================

    func testSF_W_Standard_Standalone() {
        // In standard Telex, standalone w -> ư
        assertInput("w", produces: "ư")
    }

    func testSF_W_AsModifier_Duong() {
        // w as modifier in đương
        assertInput("dduowng", produces: "đương")
    }

    func testSF_W_UW_Combination() {
        // u + w -> ư
        assertInput("tuw", produces: "tư")
    }

    func testSF_W_AW_Combination() {
        // a + w -> ă
        assertInput("taw", produces: "tă")
    }

    // ===========================================================================
    // MARK: - Section 8.2: Difficult Word List
    // Edge Cases
    // ===========================================================================

    func testEC_Khuya() {
        // khuya - Triphthong uya, no tone
        assertInput("khuya", produces: "khuya")
    }

    func testEC_NguechNgoac() {
        // nguệch - Complex rhyme with tone
        assertInput("ngueechj", produces: "nguệch")
    }

    func testEC_Khuyu() {
        // khuỷu - Triphthong with hook tone
        assertInput("khuyur", produces: "khuỷu")
    }

    // ===========================================================================
    // MARK: - Section 8.1: Vietnamese Pangram
    // Full coverage test
    // ===========================================================================

    func testEC_Pangram_Partial() {
        // Testing parts of the pangram
        // "Do bạch kim rất quý nên sẽ dùng để lắp vô xương"
        assertInput("ddo", produces: "đo")
        assertInput("bachj", produces: "bạch")
        assertInput("kim", produces: "kim")
        assertInput("raats", produces: "rất")
        assertInput("quys", produces: "quý")
        assertInput("neen", produces: "nên")
        assertInput("sex", produces: "sẽ")
        assertInput("dungf", produces: "dùng")
        assertInput("ddeer", produces: "để")
        assertInput("lawps", produces: "lắp")
        assertInput("voo", produces: "vô")
        assertInput("xuowng", produces: "xương")
    }

    // ===========================================================================
    // MARK: - Unicode Normalization Awareness
    // Section 6: NFC vs NFD
    // ===========================================================================

    func testUnicode_OutputIsValid() {
        // Verify that output is valid Unicode
        let result = typeAndGetResult("vieets")
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result, "viết")

        // Check it's proper UTF-16
        let utf16Array = Array(result.utf16)
        XCTAssertTrue(utf16Array.count > 0)
    }

    func testUnicode_ComplexCharacter() {
        // ệ = U+1EC7 (NFC precomposed)
        let result = typeAndGetResult("vieetj")
        XCTAssertEqual(result, "việt")

        // Verify the character count
        XCTAssertEqual(result.count, 4, "việt should have 4 grapheme clusters")
    }

    // ===========================================================================
    // MARK: - Performance Test
    // ===========================================================================

    func testPerformance_BulkTyping() {
        measure {
            for _ in 0..<100 {
                _ = typeAndGetResult("xin chao viet nam")
                engine.reset()
            }
        }
    }

    // ===========================================================================
    // MARK: - Complete Word Tests
    // Real Vietnamese words
    // ===========================================================================

    func testWord_XinChao() {
        assertInput("xin", produces: "xin")
        engine.reset()
        assertInput("chaof", produces: "chào")
    }

    func testWord_VietNam() {
        assertInput("vieetj", produces: "việt")
        engine.reset()
        assertInput("nam", produces: "nam")
    }

    func testWord_CamOn() {
        assertInput("carm", produces: "cảm")
        engine.reset()
        assertInput("own", produces: "ơn")
    }

    func testWord_TotLanh() {
        assertInput("toots", produces: "tốt")
        engine.reset()
        assertInput("lanhj", produces: "lạnh")
    }

    func testWord_HocSinh() {
        assertInput("hocj", produces: "học")
        engine.reset()
        assertInput("sinh", produces: "sinh")
    }

    func testWord_GiaoVien() {
        assertInput("giaos", produces: "giáo")
        engine.reset()
        assertInput("vieen", produces: "viên")
    }

    func testWord_DaiHoc() {
        assertInput("ddaij", produces: "đại")
        engine.reset()
        assertInput("hocj", produces: "học")
    }

    func testWord_ThanhPho() {
        assertInput("thanhf", produces: "thành")
        engine.reset()
        assertInput("phoos", produces: "phố")
    }

    func testWord_HaNoi() {
        assertInput("haf", produces: "hà")
        engine.reset()
        assertInput("nooji", produces: "nội")
    }

        func testWord_SaiGon() {

            assertInput("saif", produces: "sài")

            engine.reset()

            assertInput("gonf", produces: "gòn")

        }

    

    }

