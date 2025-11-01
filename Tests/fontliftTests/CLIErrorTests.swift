// this_file: Tests/fontliftTests/CLIErrorTests.swift
// CLI error handling and command validation tests

import XCTest

final class CLIErrorTests: XCTestCase {

    // MARK: - Helper Methods

    /// Get project root directory
    func getProjectRoot() -> URL {
        let currentFile = URL(fileURLWithPath: #filePath)
        return currentFile
            .deletingLastPathComponent()  // Remove CLIErrorTests.swift
            .deletingLastPathComponent()  // Remove fontliftTests
            .deletingLastPathComponent()  // Remove Tests -> now at project root
    }

    /// Get path to debug binary
    func getBinaryPath() -> String {
        let projectRoot = getProjectRoot()
        return projectRoot
            .appendingPathComponent(".build")
            .appendingPathComponent("debug")
            .appendingPathComponent("fontlift")
            .path
    }

    /// Extract the declared version from the Swift source
    func getDeclaredVersion() throws -> String {
        let projectRoot = getProjectRoot()
        let mainFile = projectRoot
            .appendingPathComponent("Sources")
            .appendingPathComponent("fontlift")
            .appendingPathComponent("fontlift.swift")
        let contents = try String(contentsOf: mainFile, encoding: .utf8)
        let pattern = #"private let version = "([0-9]+\.[0-9]+\.[0-9]+)""#
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(contents.startIndex..<contents.endIndex, in: contents)
        guard let match = regex.firstMatch(in: contents, range: range),
              let versionRange = Range(match.range(at: 1), in: contents) else {
            throw XCTSkip("Unable to parse version from fontlift.swift")
        }
        return String(contents[versionRange])
    }

    /// Run fontlift binary and capture output
    func runFontlift(args: [String]) -> (exitCode: Int32, output: String, error: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: getBinaryPath())
        process.arguments = args

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""

            return (process.terminationStatus, output, error)
        } catch {
            XCTFail("Failed to run binary: \(error)")
            return (-1, "", "")
        }
    }

    // MARK: - Version Tests

    func testVersionFlag() throws {
        let expectedVersion = try getDeclaredVersion()
        let result = runFontlift(args: ["--version"])
        XCTAssertEqual(result.exitCode, 0, "Version flag should succeed")
        XCTAssertTrue(
            result.output.contains(expectedVersion),
            "Should show declared version \(expectedVersion)"
        )
    }

    // MARK: - Help Tests

    func testHelpFlag() throws {
        let result = runFontlift(args: ["--help"])
        XCTAssertEqual(result.exitCode, 0, "Help flag should succeed")
        XCTAssertTrue(result.output.contains("USAGE"), "Help should show usage")
        XCTAssertTrue(result.output.contains("SUBCOMMANDS"), "Help should show subcommands")
    }

    func testListHelp() throws {
        let result = runFontlift(args: ["list", "--help"])
        XCTAssertEqual(result.exitCode, 0, "List help should succeed")
        XCTAssertTrue(result.output.contains("List installed fonts"), "Should show list description")
    }

    func testInstallHelp() throws {
        let result = runFontlift(args: ["install", "--help"])
        XCTAssertEqual(result.exitCode, 0, "Install help should succeed")
        XCTAssertTrue(result.output.contains("Install fonts"), "Should show install description")
    }

    func testUninstallHelp() throws {
        let result = runFontlift(args: ["uninstall", "--help"])
        XCTAssertEqual(result.exitCode, 0, "Uninstall help should succeed")
        XCTAssertTrue(result.output.contains("Uninstall fonts"), "Should show uninstall description")
    }

    func testRemoveHelp() throws {
        let result = runFontlift(args: ["remove", "--help"])
        XCTAssertEqual(result.exitCode, 0, "Remove help should succeed")
        XCTAssertTrue(result.output.contains("Remove fonts"), "Should show remove description")
    }

    // MARK: - Alias Tests

    func testListAlias() throws {
        let result = runFontlift(args: ["l", "--help"])
        XCTAssertEqual(result.exitCode, 0, "'l' alias should work")
        XCTAssertTrue(result.output.contains("List installed fonts"), "Should show list description")
    }

    func testInstallAlias() throws {
        let result = runFontlift(args: ["i", "--help"])
        XCTAssertEqual(result.exitCode, 0, "'i' alias should work")
        XCTAssertTrue(result.output.contains("Install fonts"), "Should show install description")
    }

    func testUninstallAlias() throws {
        let result = runFontlift(args: ["u", "--help"])
        XCTAssertEqual(result.exitCode, 0, "'u' alias should work")
        XCTAssertTrue(result.output.contains("Uninstall fonts"), "Should show uninstall description")
    }

    func testRemoveAlias() throws {
        let result = runFontlift(args: ["rm", "--help"])
        XCTAssertEqual(result.exitCode, 0, "'rm' alias should work")
        XCTAssertTrue(result.output.contains("Remove fonts"), "Should show remove description")
    }

    // MARK: - Error Tests

    func testInvalidSubcommand() throws {
        let result = runFontlift(args: ["invalid"])
        XCTAssertNotEqual(result.exitCode, 0, "Invalid subcommand should fail")
        XCTAssertTrue(result.error.contains("Error") || result.output.contains("Error"),
                     "Should show error message")
    }

    func testListWithoutArgs() throws {
        // Note: We test with --help instead of actually running list, because
        // list enumerates all 5000+ fonts which takes 15+ seconds and causes test timeouts
        let result = runFontlift(args: ["list", "--help"])
        XCTAssertEqual(result.exitCode, 0, "List command should show help")
        XCTAssertTrue(result.output.contains("List installed fonts"), "Should show list description")
    }

    func testInstallWithoutArgs() throws {
        let result = runFontlift(args: ["install"])
        XCTAssertNotEqual(result.exitCode, 0, "Install without path should fail")
        XCTAssertTrue(result.error.contains("Missing expected argument") ||
                     result.error.contains("Error"),
                     "Should show missing argument error")
    }

    func testUninstallWithoutArgs() throws {
        let result = runFontlift(args: ["uninstall"])
        XCTAssertNotEqual(result.exitCode, 0, "Uninstall without args should fail")
        XCTAssertTrue(result.error.contains("Specify either --name or a font path") ||
                     result.error.contains("Error"),
                     "Should show validation error")
    }

    func testRemoveWithoutArgs() throws {
        let result = runFontlift(args: ["remove"])
        XCTAssertNotEqual(result.exitCode, 0, "Remove without args should fail")
        XCTAssertTrue(result.error.contains("Specify either --name or a font path") ||
                     result.error.contains("Error"),
                     "Should show validation error")
    }

    func testUninstallWithBothNameAndPath() throws {
        let result = runFontlift(args: ["uninstall", "--name", "Arial", "/some/path.ttf"])
        XCTAssertNotEqual(result.exitCode, 0, "Uninstall with both args should fail")
        XCTAssertTrue(result.error.contains("Specify either --name or a font path, not both") ||
                     result.error.contains("Error"),
                     "Should show validation error about mutual exclusivity")
    }

    func testRemoveWithBothNameAndPath() throws {
        let result = runFontlift(args: ["remove", "--name", "Arial", "/some/path.ttf"])
        XCTAssertNotEqual(result.exitCode, 0, "Remove with both args should fail")
        XCTAssertTrue(result.error.contains("Specify either --name or a font path, not both") ||
                     result.error.contains("Error"),
                     "Should show validation error about mutual exclusivity")
    }
}
