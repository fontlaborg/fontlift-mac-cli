// this_file: Tests/fontliftTests/HelperFunctionTests.swift
// Unit tests for helper functions

import XCTest
import Foundation
@testable import fontlift

final class HelperFunctionTests: XCTestCase {

    // MARK: - shellEscape() Tests

    func testShellEscapeSimplePath() throws {
        let result = shellEscape("/path/to/font.ttf")
        XCTAssertEqual(result, "'/path/to/font.ttf'", "Simple paths should be wrapped in single quotes")
    }

    func testShellEscapePathWithSpaces() throws {
        let result = shellEscape("/path/to/My Font.ttf")
        XCTAssertEqual(result, "'/path/to/My Font.ttf'", "Paths with spaces should be wrapped in single quotes")
    }

    func testShellEscapePathWithSingleQuote() throws {
        let result = shellEscape("/path/to/user's font.ttf")
        XCTAssertEqual(result, "'/path/to/user'\\''s font.ttf'", "Single quotes should be escaped using '\\''")
    }

    func testShellEscapeEmptyPath() throws {
        let result = shellEscape("")
        XCTAssertEqual(result, "''", "Empty paths should result in empty quoted string")
    }

    // MARK: - isSystemFontPath() Tests

    func testIsSystemFontPathSystemLibrary() throws {
        let url = URL(fileURLWithPath: "/System/Library/Fonts/Helvetica.ttc")
        XCTAssertTrue(isSystemFontPath(url), "Paths in /System/Library/Fonts/ should be identified as system fonts")
    }

    func testIsSystemFontPathLibrary() throws {
        let url = URL(fileURLWithPath: "/Library/Fonts/Arial.ttf")
        XCTAssertTrue(isSystemFontPath(url), "Paths in /Library/Fonts/ should be identified as system fonts")
    }

    func testIsSystemFontPathUserLibrary() throws {
        let url = URL(fileURLWithPath: "/Users/test/Library/Fonts/Custom.ttf")
        XCTAssertFalse(isSystemFontPath(url), "User library fonts should NOT be identified as system fonts")
    }

    func testIsSystemFontPathHomeDirectory() throws {
        let url = URL(fileURLWithPath: "~/Library/Fonts/MyFont.ttf")
        XCTAssertFalse(isSystemFontPath(url), "Home directory fonts should NOT be identified as system fonts")
    }

    func testIsSystemFontPathRelative() throws {
        let url = URL(fileURLWithPath: "fonts/test.ttf")
        XCTAssertFalse(isSystemFontPath(url), "Relative paths should NOT be identified as system fonts")
    }

    // MARK: - isValidFontExtension() Tests

    func testIsValidFontExtensionTTF() throws {
        XCTAssertTrue(isValidFontExtension("/path/to/font.ttf"), ".ttf files should be valid")
        XCTAssertTrue(isValidFontExtension("/path/to/font.TTF"), ".TTF files should be valid (case-insensitive)")
    }

    func testIsValidFontExtensionOTF() throws {
        XCTAssertTrue(isValidFontExtension("/path/to/font.otf"), ".otf files should be valid")
        XCTAssertTrue(isValidFontExtension("/path/to/font.OTF"), ".OTF files should be valid (case-insensitive)")
    }

    func testIsValidFontExtensionTTC() throws {
        XCTAssertTrue(isValidFontExtension("/path/to/font.ttc"), ".ttc files should be valid")
    }

    func testIsValidFontExtensionOTC() throws {
        XCTAssertTrue(isValidFontExtension("/path/to/font.otc"), ".otc files should be valid")
    }

    func testIsValidFontExtensionDFont() throws {
        XCTAssertTrue(isValidFontExtension("/path/to/font.dfont"), ".dfont files should be valid")
    }

    func testIsValidFontExtensionInvalidExtensions() throws {
        XCTAssertFalse(isValidFontExtension("/path/to/file.txt"), ".txt files should be invalid")
        XCTAssertFalse(isValidFontExtension("/path/to/file.pdf"), ".pdf files should be invalid")
        XCTAssertFalse(isValidFontExtension("/path/to/file.zip"), ".zip files should be invalid")
        XCTAssertFalse(isValidFontExtension("/path/to/file"), "Files without extension should be invalid")
    }

    func testIsValidFontExtensionNoExtension() throws {
        XCTAssertFalse(isValidFontExtension("/path/to/fontfile"), "Paths without extension should be invalid")
    }
    // MARK: - getFontFamilyName() Tests

    func testGetFontFamilyNameReturnsFamilyForSystemFont() throws {
        let helveticaURL = URL(fileURLWithPath: "/System/Library/Fonts/Helvetica.ttc")
        let familyName = getFontFamilyName(from: helveticaURL)
        XCTAssertEqual(
            familyName,
            "Helvetica",
            "Should extract Helvetica family name from system font"
        )
    }

    func testGetFontFamilyNameReturnsNilForInvalidFile() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("not-a-font.ttf")
        defer { try? FileManager.default.removeItem(at: tempURL) }
        try Data("not a real font".utf8).write(to: tempURL)

        let familyName = getFontFamilyName(from: tempURL)
        XCTAssertNil(familyName, "Invalid font file should return nil family name")
    }

    // MARK: - List Output Formatting

    func testListOutputIsSortedByDefaultForPaths() throws {
        let fontURLs = [
            URL(fileURLWithPath: "/Library/Fonts/Zeta.ttf"),
            URL(fileURLWithPath: "/Library/Fonts/Alpha.ttf"),
        ]

        let lines = buildListOutput(
            fontURLs: fontURLs,
            showPath: true,
            showName: false,
            dedupeAll: false
        )

        XCTAssertEqual(
            lines,
            ["/Library/Fonts/Alpha.ttf", "/Library/Fonts/Zeta.ttf"],
            "Path-only output should be alphabetically sorted by default"
        )
    }

    func testListOutputDedupesPathsByDefault() throws {
        let duplicatePath = "/Library/Fonts/Shared.ttf"
        let fontURLs = [
            URL(fileURLWithPath: duplicatePath),
            URL(fileURLWithPath: duplicatePath),
        ]

        let lines = buildListOutput(
            fontURLs: fontURLs,
            showPath: true,
            showName: false,
            dedupeAll: false
        )

        XCTAssertEqual(
            lines,
            [duplicatePath],
            "Path-only output should be deduplicated even without --sorted flag"
        )
    }

    func testListOutputDedupesWhenSortedFlagProvided() throws {
        let sharedPath = "/Library/Fonts/Shared.ttc"
        let fontURLs = [
            URL(fileURLWithPath: sharedPath),
            URL(fileURLWithPath: sharedPath),
        ]

        let lines = buildListOutput(
            fontURLs: fontURLs,
            showPath: true,
            showName: true,
            dedupeAll: true
        )

        XCTAssertEqual(
            lines,
            ["/Library/Fonts/Shared.ttc::Unknown"],
            "--sorted flag should deduplicate combined path::name output"
        )
    }
}
