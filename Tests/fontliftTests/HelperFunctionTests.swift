// this_file: Tests/fontliftTests/HelperFunctionTests.swift
// Unit tests for helper functions

import XCTest
import Foundation

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
}

// MARK: - Helper Function Imports
// These functions are defined in the main fontlift.swift file
// We need to make them accessible for testing

/// Escape a file path for safe use in shell commands
func shellEscape(_ path: String) -> String {
    let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
    return "'\(escaped)'"
}

/// Check if a font path is in a protected system directory
func isSystemFontPath(_ url: URL) -> Bool {
    let path = url.path
    return path.hasPrefix("/System/Library/Fonts/") || path.hasPrefix("/Library/Fonts/")
}

/// Validate that a file has a recognized font extension
func isValidFontExtension(_ path: String) -> Bool {
    let validExtensions = ["ttf", "otf", "ttc", "otc", "dfont"]
    let pathExtension = (path as NSString).pathExtension.lowercased()
    return validExtensions.contains(pathExtension)
}
