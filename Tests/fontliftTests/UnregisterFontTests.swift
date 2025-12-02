// this_file: Tests/fontliftTests/UnregisterFontTests.swift
// Tests for unregisterFont scope handling

import ArgumentParser
import CoreText
import Foundation
import XCTest
@testable import fontlift

final class UnregisterFontTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        fontManagerUnregisterFontsForURL = CTFontManagerUnregisterFontsForURL
    }

    func testUnregisterFontAttemptsUserAndSystemScopes() throws {
        var scopesAttempted: [CTFontManagerScope] = []
        fontManagerUnregisterFontsForURL = { _, scope, _ in
            scopesAttempted.append(scope)
            return scope == .session
        }

        let url = URL(fileURLWithPath: "/Users/test/Library/Fonts/Example.ttf")

        try unregisterFont(at: url, admin: false, silent: true)

        XCTAssertEqual(scopesAttempted, [.user, .session], "Should attempt both user and system scopes")
    }

    func testUnregisterFontFailsWhenBothScopesFail() throws {
        fontManagerUnregisterFontsForURL = { _, _, _ in false }

        let url = URL(fileURLWithPath: "/Users/test/Library/Fonts/Fail.ttf")

        XCTAssertThrowsError(try unregisterFont(at: url, admin: false, silent: true)) { error in
            XCTAssertEqual(error as? ExitCode, ExitCode.failure, "Should throw failure when all scopes fail")
        }
    }
}
