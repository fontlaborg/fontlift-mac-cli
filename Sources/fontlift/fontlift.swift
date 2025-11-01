// this_file: Sources/fontlift/fontlift.swift
// fontlift - macOS CLI tool for font installation and management

import ArgumentParser
import CoreText
import Foundation

// MARK: - Version Management
/// Current version of fontlift
/// When updating, also update:
/// - CHANGELOG.md (add new version section)
/// - Git tag (git tag vX.Y.Z)
private let version = "1.1.21"

// MARK: - Font Management Helpers

/// Get the PostScript name of a font from its file URL
func getFontName(from url: URL) -> String? {
    guard let fontDataProvider = CGDataProvider(url: url as CFURL),
          let font = CGFont(fontDataProvider),
          let postScriptName = font.postScriptName as String? else {
        return nil
    }
    return postScriptName
}

/// Get the full font name (display name) from a URL
func getFullFontName(from url: URL) -> String? {
    guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
          let descriptor = descriptors.first else {
        return nil
    }

    let font = CTFontCreateWithFontDescriptor(descriptor, 0, nil)
    return CTFontCopyFullName(font) as String?
}

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
    /// List all installed fonts on the system
    ///
    /// This command enumerates fonts using `CTFontManagerCopyAvailableFontURLs()`,
    /// which returns fonts from system, user, and library directories.
    ///
    /// Output modes:
    /// - Default (`-p`): Font file paths only
    /// - Names (`-n`): Internal font names (PostScript or display names)
    /// - Both (`-p -n`): Combined format as `path;name`
    /// - Sorted (`-s`): Alphabetically sorted with duplicates removed
    ///
    /// The output is pure data (no headers/footers) for pipe-friendly usage.
    ///
    /// Example usage:
    /// ```bash
    /// fontlift list              # List all font paths
    /// fontlift list -n           # List all font names
    /// fontlift list -p -n        # List path;name pairs
    /// fontlift list -n -s        # List unique font names, sorted
    /// fontlift list | wc -l      # Count total fonts
    /// ```
    ///
    /// **Output Modes:**
    /// - Default (no flags): Lists font file paths only
    /// - `-n` / `--name`: Lists internal font names only
    /// - `-p -n`: Lists both in format "path;name"
    /// - `-s` / `--sorted`: Sorts output and removes duplicates
    ///
    /// **Examples:**
    /// ```bash
    /// fontlift list                    # List all font paths
    /// fontlift list -n                 # List all font names
    /// fontlift list -p -n              # List path;name pairs
    /// fontlift list -n -s              # List unique sorted names
    /// fontlift l                       # Same as 'list' (alias)
    /// ```
    ///
    /// **Note:** Output is pure data without headers/footers for pipe-friendly usage.
    /// Typical systems have 5000+ fonts installed.
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

        @Flag(name: .shortAndLong, help: "Sort output and remove duplicates")
        var sorted = false

        func run() throws {
            // Default to showing paths if no flags specified
            // This provides backwards compatibility and sensible defaults
            let showPath = path || !name
            let showName = name

            // Query Core Text for all available font URLs in the system
            // This includes fonts from /System/Library/Fonts, /Library/Fonts, ~/Library/Fonts
            guard let fontURLs = CTFontManagerCopyAvailableFontURLs() as? [URL] else {
                throw ExitCode.failure
            }

            // Collect output lines for batch processing
            // Building array first allows sorting if requested
            var lines: [String] = []

            // Process each font URL and format output based on flags
            for fontURL in fontURLs {
                if showPath && showName {
                    // Combined mode: output both path and name separated by semicolon
                    // Format: /path/to/font.ttf;FontName
                    let fontName = getFontName(from: fontURL) ?? getFullFontName(from: fontURL) ?? "Unknown"
                    lines.append("\(fontURL.path);\(fontName)")
                } else if showPath {
                    // Path-only mode: just the file system path
                    lines.append(fontURL.path)
                } else {
                    // Name-only mode: extract and output PostScript or display name
                    // Skip fonts where name can't be extracted
                    if let fontName = getFontName(from: fontURL) ?? getFullFontName(from: fontURL) {
                        lines.append(fontName)
                    }
                }
            }

            // Sort and deduplicate if requested
            // Useful for reducing 5000+ font names to unique set (~1000-1500 names)
            if sorted {
                let uniqueLines = Set(lines)
                lines = uniqueLines.sorted()
            }

            // Output pure data only - no headers or footers
            for line in lines {
                print(line)
            }
        }
    }
}

// MARK: - Install Command
extension Fontlift {
    /// Install a font file to the system.
    ///
    /// Registers the font with macOS using `CTFontManagerRegisterFontsForURL()` at user scope.
    /// This makes the font available to all applications without requiring administrator privileges.
    ///
    /// The font file remains in its original location - this command only registers it with
    /// the system font manager. Use the remove command to both unregister and delete the file.
    ///
    /// Supports individual font files and font collections (.ttc/.otc).
    ///
    /// Example usage:
    /// ```bash
    /// fontlift install ~/Downloads/CustomFont.ttf
    /// fontlift i /path/to/font.otf
    /// ```
    struct Install: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "install",
            abstract: "Install fonts from file paths",
            aliases: ["i"]
        )

        @Argument(help: "Font file path to install")
        var fontPath: String

        func run() throws {
            let url = URL(fileURLWithPath: fontPath)

            // Check if file exists
            guard FileManager.default.fileExists(atPath: fontPath) else {
                print("❌ Error: Font file not found at path: \(fontPath)")
                throw ExitCode.failure
            }

            print("Installing font from: \(fontPath)")

            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(url as CFURL, .user, &error)

            if success {
                if let fontName = getFontName(from: url) ?? getFullFontName(from: url) {
                    print("✅ Successfully installed: \(fontName)")
                } else {
                    print("✅ Successfully installed font")
                }
            } else {
                if let error = error?.takeRetainedValue() {
                    let errorDesc = CFErrorCopyDescription(error) as String
                    print("❌ Error installing font: \(errorDesc)")
                    throw ExitCode.failure
                } else {
                    print("❌ Error: Failed to install font")
                    throw ExitCode.failure
                }
            }
        }
    }
}

// MARK: - Uninstall Command
extension Fontlift {
    /// Uninstall a font from the system while keeping the file.
    ///
    /// Deregisters the font using `CTFontManagerUnregisterFontsForURL()` but leaves the
    /// font file in place. The font will no longer appear in applications' font pickers.
    ///
    /// You can specify the font either by:
    /// - File path: `fontlift uninstall /path/to/font.ttf`
    /// - Font name: `fontlift uninstall -n "Arial"`
    ///
    /// When using `-n`, the command searches all installed fonts to find a matching name.
    /// If the font file no longer exists but is still registered, uninstall will attempt
    /// to deregister it anyway.
    ///
    /// Use the remove command if you want to both unregister and delete the file.
    ///
    /// Example usage:
    /// ```bash
    /// fontlift uninstall ~/Downloads/CustomFont.ttf
    /// fontlift u -n "Helvetica Neue"
    /// ```
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
            if let fontName = name {
                // Find font by name
                print("Uninstalling font by name: \(fontName)")

                guard let fontURLs = CTFontManagerCopyAvailableFontURLs() as? [URL] else {
                    print("❌ Error: Could not retrieve font list")
                    throw ExitCode.failure
                }

                var foundURL: URL?
                for url in fontURLs {
                    if let urlFontName = getFontName(from: url) ?? getFullFontName(from: url),
                       urlFontName == fontName {
                        foundURL = url
                        break
                    }
                }

                guard let url = foundURL else {
                    print("❌ Error: Font '\(fontName)' not found in installed fonts")
                    throw ExitCode.failure
                }

                try unregisterFont(at: url)

            } else if let path = fontPath {
                let url = URL(fileURLWithPath: path)

                if !FileManager.default.fileExists(atPath: path) {
                    print("⚠️  Warning: Font file not found at path: \(path)")
                    print("Attempting to uninstall anyway...")
                }

                print("Uninstalling font from path: \(path)")
                try unregisterFont(at: url)
            }
        }

        private func unregisterFont(at url: URL) throws {
            var error: Unmanaged<CFError>?
            let success = CTFontManagerUnregisterFontsForURL(url as CFURL, .user, &error)

            if success {
                if let fontName = getFontName(from: url) ?? getFullFontName(from: url) {
                    print("✅ Successfully uninstalled: \(fontName)")
                } else {
                    print("✅ Successfully uninstalled font")
                }
            } else {
                if let error = error?.takeRetainedValue() {
                    let errorDesc = CFErrorCopyDescription(error) as String
                    print("❌ Error uninstalling font: \(errorDesc)")
                    throw ExitCode.failure
                } else {
                    print("❌ Error: Failed to uninstall font")
                    throw ExitCode.failure
                }
            }
        }
    }
}

// MARK: - Remove Command
extension Fontlift {
    /// Remove a font from the system and delete the file.
    ///
    /// This command performs two operations:
    /// 1. Deregisters the font from the system (like uninstall)
    /// 2. Deletes the font file from disk
    ///
    /// ⚠️ Warning: This is a destructive operation. The font file will be permanently deleted.
    ///
    /// You can specify the font either by:
    /// - File path: `fontlift remove /path/to/font.ttf`
    /// - Font name: `fontlift remove -n "Arial"`
    ///
    /// When using `-n`, the command searches all installed fonts to find the file location,
    /// then unregisters and deletes it.
    ///
    /// If unregistration fails, the command will still attempt to delete the file.
    /// Use uninstall if you only want to deregister without deleting.
    ///
    /// Example usage:
    /// ```bash
    /// fontlift remove ~/Downloads/CustomFont.ttf
    /// fontlift rm -n "Helvetica Neue"
    /// ```
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
            if let fontName = name {
                // Find font by name
                print("Removing font by name: \(fontName)")

                guard let fontURLs = CTFontManagerCopyAvailableFontURLs() as? [URL] else {
                    print("❌ Error: Could not retrieve font list")
                    throw ExitCode.failure
                }

                var foundURL: URL?
                for url in fontURLs {
                    if let urlFontName = getFontName(from: url) ?? getFullFontName(from: url),
                       urlFontName == fontName {
                        foundURL = url
                        break
                    }
                }

                guard let url = foundURL else {
                    print("❌ Error: Font '\(fontName)' not found in installed fonts")
                    throw ExitCode.failure
                }

                try removeFont(at: url)

            } else if let path = fontPath {
                let url = URL(fileURLWithPath: path)

                guard FileManager.default.fileExists(atPath: path) else {
                    print("❌ Error: Font file not found at path: \(path)")
                    throw ExitCode.failure
                }

                print("Removing font from path: \(path)")
                try removeFont(at: url)
            }
        }

        private func removeFont(at url: URL) throws {
            // First unregister the font
            var error: Unmanaged<CFError>?
            let unregistered = CTFontManagerUnregisterFontsForURL(url as CFURL, .user, &error)

            if !unregistered {
                if let error = error?.takeRetainedValue() {
                    let errorDesc = CFErrorCopyDescription(error) as String
                    print("⚠️  Warning: Error unregistering font: \(errorDesc)")
                }
            }

            // Then delete the file
            do {
                try FileManager.default.removeItem(at: url)
                if let fontName = getFontName(from: url) ?? getFullFontName(from: url) {
                    print("✅ Successfully removed: \(fontName)")
                } else {
                    print("✅ Successfully removed font file")
                }
            } catch {
                print("❌ Error deleting font file: \(error.localizedDescription)")
                throw ExitCode.failure
            }
        }
    }
}
