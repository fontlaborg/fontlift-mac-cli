// this_file: Tests/fontliftTests/ProjectValidationTests.swift
// Basic project validation tests

import XCTest

final class ProjectValidationTests: XCTestCase {

    // Helper to get project root
    func getProjectRoot() -> URL {
        // Start from current file's directory and navigate up
        // #file gives us Tests/fontliftTests/ProjectValidationTests.swift
        let currentFile = URL(fileURLWithPath: #filePath)
        // Go up to project root: remove /Tests/fontliftTests/ProjectValidationTests.swift
        return currentFile
            .deletingLastPathComponent()  // Remove ProjectValidationTests.swift
            .deletingLastPathComponent()  // Remove fontliftTests
            .deletingLastPathComponent()  // Remove Tests -> now at project root
    }

    func testPackageExists() throws {
        let packagePath = getProjectRoot().appendingPathComponent("Package.swift")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: packagePath.path),
            "Package.swift should exist at \(packagePath.path)"
        )
    }

    func testReadmeExists() throws {
        let readmePath = getProjectRoot().appendingPathComponent("README.md")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: readmePath.path),
            "README.md should exist at \(readmePath.path)"
        )
    }

    func testPrinciplesExists() throws {
        let principlesPath = getProjectRoot().appendingPathComponent("PRINCIPLES.md")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: principlesPath.path),
            "PRINCIPLES.md should exist (required by project principles)"
        )
    }

    func testBuildScriptExists() throws {
        let buildScript = getProjectRoot().appendingPathComponent("build.sh")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: buildScript.path),
            "build.sh should exist (required by PRINCIPLES.md)"
        )
        // Verify it's executable
        XCTAssertTrue(
            FileManager.default.isExecutableFile(atPath: buildScript.path),
            "build.sh should be executable"
        )
    }

    func testTestScriptExists() throws {
        let testScript = getProjectRoot().appendingPathComponent("test.sh")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: testScript.path),
            "test.sh should exist (required by development guidelines)"
        )
        XCTAssertTrue(
            FileManager.default.isExecutableFile(atPath: testScript.path),
            "test.sh should be executable"
        )
    }

    func testPublishScriptExists() throws {
        let publishScript = getProjectRoot().appendingPathComponent("publish.sh")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: publishScript.path),
            "publish.sh should exist (required by PRINCIPLES.md)"
        )
        XCTAssertTrue(
            FileManager.default.isExecutableFile(atPath: publishScript.path),
            "publish.sh should be executable"
        )
    }
}
