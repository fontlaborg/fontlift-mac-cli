// this_file: Sources/fontlift/fontlift.swift
// fontlift - macOS CLI tool for font installation and management

import ArgumentParser
import Foundation

// MARK: - Version Management
/// Current version of fontlift
/// When updating, also update:
/// - CHANGELOG.md (add new version section)
/// - Git tag (git tag vX.Y.Z)
private let version = "0.1.0"

@main
struct Fontlift: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fontlift",
        abstract: "Install, uninstall, list, and remove fonts on macOS",
        version: version,
        subcommands: [
            List.self,
            Install.self,
            Uninstall.self,
            Remove.self
        ]
    )
}

// MARK: - List Command
extension Fontlift {
    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List installed fonts",
            aliases: ["l"]
        )

        @Flag(name: .shortAndLong, help: "Show font file paths")
        var path = false

        @Flag(name: .shortAndLong, help: "Show internal font names")
        var name = false

        func run() throws {
            // Default to path if neither flag specified
            let showPath = path || !name
            let showName = name

            if showPath && showName {
                print("Listing fonts (path;name format)...")
            } else if showPath {
                print("Listing font paths...")
            } else {
                print("Listing font names...")
            }

            // Implementation placeholder
            print("(Font listing not yet implemented)")
        }
    }
}

// MARK: - Install Command
extension Fontlift {
    struct Install: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "install",
            abstract: "Install fonts from file paths",
            aliases: ["i"]
        )

        @Argument(help: "Font file path to install")
        var fontPath: String

        func run() throws {
            print("Installing font from: \(fontPath)")
            print("(Font installation not yet implemented)")
        }
    }
}

// MARK: - Uninstall Command
extension Fontlift {
    struct Uninstall: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "uninstall",
            abstract: "Uninstall fonts (keeping files)",
            aliases: ["u"]
        )

        @Option(name: .shortAndLong, help: "Font name to uninstall")
        var name: String?

        @Argument(help: "Font file path to uninstall")
        var fontPath: String?

        func validate() throws {
            if name == nil && fontPath == nil {
                throw ValidationError("Specify either --name or a font path")
            }
            if name != nil && fontPath != nil {
                throw ValidationError("Specify either --name or a font path, not both")
            }
        }

        func run() throws {
            if let name = name {
                print("Uninstalling font by name: \(name)")
            } else if let path = fontPath {
                print("Uninstalling font from path: \(path)")
            }
            print("(Font uninstallation not yet implemented)")
        }
    }
}

// MARK: - Remove Command
extension Fontlift {
    struct Remove: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "remove",
            abstract: "Remove fonts (uninstall and delete files)",
            aliases: ["rm"]
        )

        @Option(name: .shortAndLong, help: "Font name to remove")
        var name: String?

        @Argument(help: "Font file path to remove")
        var fontPath: String?

        func validate() throws {
            if name == nil && fontPath == nil {
                throw ValidationError("Specify either --name or a font path")
            }
            if name != nil && fontPath != nil {
                throw ValidationError("Specify either --name or a font path, not both")
            }
        }

        func run() throws {
            if let name = name {
                print("Removing font by name: \(name)")
            } else if let path = fontPath {
                print("Removing font from path: \(path)")
            }
            print("(Font removal not yet implemented)")
        }
    }
}
