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
private let version = "1.1.29"

// MARK: - Font Management Helpers

/// Escape a file path for safe use in shell commands
///
/// Wraps paths containing special characters in single quotes and escapes any single quotes within.
/// This ensures suggested shell commands (like "sudo fontlift remove '/path/to/file'") work correctly
/// even when paths contain spaces, quotes, or other shell metacharacters.
///
/// - Parameter path: The file path to escape
/// - Returns: Shell-safe escaped path string
///
/// **Examples:**
/// - "~/Downloads/My Font.ttf" → "'~/Downloads/My Font.ttf'"
/// - "/path/with'quote.ttf" → "'/path/with'\''quote.ttf'"
/// - "/simple/path.ttf" → "'/simple/path.ttf'"
func shellEscape(_ path: String) -> String {
    // Replace single quotes with '\'' (end quote, escaped quote, start quote)
    let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
    return "'\(escaped)'"
}

/// Check if a font path is in a protected system directory
///
/// Prevents modification of system fonts that are critical for macOS stability.
/// System font directories include:
/// - `/System/Library/Fonts/` - Core macOS system fonts
/// - `/Library/Fonts/` - System-wide fonts (requires admin privileges)
///
/// - Parameter url: The font file URL to check
/// - Returns: `true` if the path is in a protected system directory; `false` otherwise
func isSystemFontPath(_ url: URL) -> Bool {
    let path = url.path
    return path.hasPrefix("/System/Library/Fonts/") || path.hasPrefix("/Library/Fonts/")
}

/// Validate that a file has a recognized font extension
///
/// Checks if the file extension matches known font formats supported by macOS Core Text.
/// This provides early validation before attempting font operations.
///
/// - Parameter path: The file path to validate
/// - Returns: `true` if the file has a valid font extension; `false` otherwise
///
/// Supported formats:
/// - .ttf (TrueType Font)
/// - .otf (OpenType Font)
/// - .ttc (TrueType Collection)
/// - .otc (OpenType Collection)
/// - .dfont (macOS Data Fork Font)
func isValidFontExtension(_ path: String) -> Bool {
    let validExtensions = ["ttf", "otf", "ttc", "otc", "dfont"]
    let pathExtension = (path as NSString).pathExtension.lowercased()
    return validExtensions.contains(pathExtension)
}

/// Validate that a file path exists, is readable, and is a regular file
///
/// Performs comprehensive validation before font operations to provide clear error messages.
/// This defensive check prevents cryptic Core Text errors by catching common mistakes early.
///
/// - Parameter path: The file path to validate (absolute or relative)
/// - Returns: `true` if the path is valid and readable; `false` if validation fails (with error printed to stdout)
///
/// **Validation checks performed:**
/// 1. File exists at the specified path
/// 2. Path points to a regular file (not a directory)
/// 3. File is readable by the current user
///
/// **Example:**
/// ```swift
/// guard validateFilePath("/path/to/font.ttf") else {
///     throw ExitCode.failure
/// }
/// ```
func validateFilePath(_ path: String) -> Bool {
    let fileManager = FileManager.default

    // Check if path exists
    guard fileManager.fileExists(atPath: path) else {
        print("❌ Error: File not found at path: \(path)")
        print("   Please check that the path is correct and the file exists")
        return false
    }

    // Check if it's a regular file (not a directory)
    var isDirectory: ObjCBool = false
    fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
    guard !isDirectory.boolValue else {
        print("❌ Error: Path is a directory, not a file: \(path)")
        print("   Please specify a font file (.ttf, .otf, .ttc, .otc)")
        return false
    }

    // Check if file is readable
    guard fileManager.isReadableFile(atPath: path) else {
        print("❌ Error: File is not readable: \(path)")
        print("   Please check file permissions")
        return false
    }

    // Check if file has a valid font extension
    guard isValidFontExtension(path) else {
        print("❌ Error: Invalid font file format: \(path)")
        print("   Supported formats: .ttf, .otf, .ttc, .otc, .dfont")
        print("")
        print("   Common issues:")
        print("   - File is not a font file")
        print("   - File has wrong extension")
        print("   - File is corrupted or renamed")
        return false
    }

    return true
}

/// Get the PostScript name of a font from its file URL
///
/// Extracts the PostScript name using Core Graphics APIs. The PostScript name is the
/// technical identifier used internally by the font system (e.g., "Helvetica-Bold").
/// This is preferred over display names for font identification as it's more reliable.
///
/// **Core Text API Flow:**
/// 1. `CGDataProvider` - Creates a data provider from the font file URL
/// 2. `CGFont` - Parses the font file to create a font object
/// 3. `postScriptName` - Extracts the PostScript name property
///
/// - Parameter url: File URL pointing to a font file (.ttf, .otf, .ttc, .otc)
/// - Returns: PostScript name string if successful; `nil` if the file can't be read or parsed
///
/// **Example PostScript names:**
/// - "HelveticaNeue-Bold"
/// - "TimesNewRomanPS-BoldMT"
/// - "Arial-ItalicMT"
func getFontName(from url: URL) -> String? {
    guard let fontDataProvider = CGDataProvider(url: url as CFURL),
          let font = CGFont(fontDataProvider),
          let postScriptName = font.postScriptName as String? else {
        return nil
    }
    return postScriptName
}

/// Get the full font name (display name) from a URL
///
/// Extracts the human-readable display name using Core Text APIs. The full name is what users
/// see in font menus (e.g., "Helvetica Neue Bold"). This is used as a fallback when PostScript
/// names aren't available.
///
/// **Core Text API Flow:**
/// 1. `CTFontManagerCreateFontDescriptorsFromURL` - Creates font descriptors from file
/// 2. Uses first descriptor (font collections may contain multiple fonts)
/// 3. `CTFontCreateWithFontDescriptor` - Creates font object from descriptor
/// 4. `CTFontCopyFullName` - Extracts the full display name
///
/// - Parameter url: File URL pointing to a font file (.ttf, .otf, .ttc, .otc)
/// - Returns: Display name string if successful; `nil` if the file can't be read or has no display name
///
/// **Example display names:**
/// - "Helvetica Neue Bold"
/// - "Times New Roman Bold Italic"
/// - "Arial"
///
/// **Note:** For font collections (.ttc/.otc), this returns the name of the first font in the collection.
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
                print("❌ Error: Could not retrieve font list from system")
                print("   This may indicate a system font database issue")
                print("")
                print("   Troubleshooting:")
                print("   - Restart your Mac to rebuild font cache")
                print("   - Run: atsutil databases -remove")
                print("   - Check Console.app for system font errors")
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
            // Validate file path before attempting installation
            guard validateFilePath(fontPath) else {
                throw ExitCode.failure
            }

            let url = URL(fileURLWithPath: fontPath)
            print("Installing font from: \(fontPath)")

            var error: Unmanaged<CFError>?
            // Register font at .user scope (doesn't require sudo, available to current user only)
            // Alternative: .system scope (requires sudo, available to all users)
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

                    // Check if this is a duplicate registration error
                    if errorDesc.contains("already activated") || errorDesc.contains("already registered") {
                        if let fontName = getFontName(from: url) ?? getFullFontName(from: url) {
                            print("ℹ️  Font already installed: \(fontName)")
                            print("   File: \(fontPath)")
                        } else {
                            print("ℹ️  Font already installed")
                            print("   File: \(fontPath)")
                        }
                        print("")
                        print("   Use 'fontlift list' to see all installed fonts")
                        print("   Use 'fontlift uninstall' to remove before reinstalling")
                        throw ExitCode.failure
                    }

                    // Generic error handling for other failures
                    print("❌ Error installing font: \(errorDesc)")
                    print("   File: \(fontPath)")
                    print("")
                    print("   Common causes:")
                    print("   - Invalid or corrupted font file")
                    print("   - Font format not supported (.ttf, .otf, .ttc, .otc)")
                    print("   - Permission issues (try with sudo for system-level install)")
                    throw ExitCode.failure
                } else {
                    print("❌ Error: Failed to install font")
                    print("   File: \(fontPath)")
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
                    print("❌ Error: Could not retrieve font list from system")
                    print("   This may indicate a system font database issue")
                    print("")
                    print("   Troubleshooting:")
                    print("   - Restart your Mac to rebuild font cache")
                    print("   - Run: atsutil databases -remove")
                    print("   - Check Console.app for system font errors")
                    throw ExitCode.failure
                }

                var matchingURLs: [URL] = []
                for url in fontURLs {
                    if let urlFontName = getFontName(from: url) ?? getFullFontName(from: url),
                       urlFontName == fontName {
                        matchingURLs.append(url)
                    }
                }

                guard !matchingURLs.isEmpty else {
                    print("❌ Error: Font '\(fontName)' not found in installed fonts")
                    print("   Font name: \(fontName)")
                    print("")
                    print("   Suggestions:")
                    print("   - Use 'fontlift list -n' to see all installed font names")
                    print("   - Check spelling and case (font names are case-sensitive)")
                    print("   - Font may have already been uninstalled")
                    throw ExitCode.failure
                }

                guard matchingURLs.count == 1 else {
                    print("❌ Error: Ambiguous font name '\(fontName)' matches \(matchingURLs.count) fonts")
                    print("")
                    print("   Matching fonts:")
                    for (index, url) in matchingURLs.enumerated() {
                        print("   \(index + 1). \(url.path)")
                        print("        fontlift uninstall \(shellEscape(url.path))")
                    }
                    print("")
                    print("   Copy and run one of the commands above to uninstall the specific font.")
                    throw ExitCode.failure
                }

                let url = matchingURLs[0]

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
            // Protect system fonts from accidental modification
            if isSystemFontPath(url) {
                print("❌ Error: Cannot uninstall system font")
                print("   Path: \(url.path)")
                print("")
                print("   System fonts in /System/Library/Fonts/ and /Library/Fonts/")
                print("   are critical for macOS stability and cannot be modified.")
                print("")
                print("   If you need to manage a font, copy it to ~/Library/Fonts/ first.")
                throw ExitCode.failure
            }

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
                    print("   File: \(url.path)")
                    print("")
                    print("   Common causes:")
                    print("   - Font not currently installed")
                    print("   - Font installed at system level (try with sudo)")
                    print("   - Permission issues")
                    throw ExitCode.failure
                } else {
                    print("❌ Error: Failed to uninstall font")
                    print("   File: \(url.path)")
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
                    print("❌ Error: Could not retrieve font list from system")
                    print("   This may indicate a system font database issue")
                    print("")
                    print("   Troubleshooting:")
                    print("   - Restart your Mac to rebuild font cache")
                    print("   - Run: atsutil databases -remove")
                    print("   - Check Console.app for system font errors")
                    throw ExitCode.failure
                }

                var matchingURLs: [URL] = []
                for url in fontURLs {
                    if let urlFontName = getFontName(from: url) ?? getFullFontName(from: url),
                       urlFontName == fontName {
                        matchingURLs.append(url)
                    }
                }

                guard !matchingURLs.isEmpty else {
                    print("❌ Error: Font '\(fontName)' not found in installed fonts")
                    print("   Font name: \(fontName)")
                    print("")
                    print("   Suggestions:")
                    print("   - Use 'fontlift list -n' to see all installed font names")
                    print("   - Check spelling and case (font names are case-sensitive)")
                    print("   - Font may have already been removed")
                    throw ExitCode.failure
                }

                guard matchingURLs.count == 1 else {
                    print("❌ Error: Ambiguous font name '\(fontName)' matches \(matchingURLs.count) fonts")
                    print("")
                    print("   Matching fonts:")
                    for (index, url) in matchingURLs.enumerated() {
                        print("   \(index + 1). \(url.path)")
                        print("        fontlift remove \(shellEscape(url.path))")
                    }
                    print("")
                    print("   Copy and run one of the commands above to remove the specific font.")
                    throw ExitCode.failure
                }

                let url = matchingURLs[0]

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
            // Protect system fonts from accidental modification
            if isSystemFontPath(url) {
                print("❌ Error: Cannot remove system font")
                print("   Path: \(url.path)")
                print("")
                print("   System fonts in /System/Library/Fonts/ and /Library/Fonts/")
                print("   are critical for macOS stability and cannot be removed.")
                print("")
                print("   If you need to manage a font, copy it to ~/Library/Fonts/ first.")
                throw ExitCode.failure
            }

            // Get font name before deletion (file must exist to read metadata)
            let fontName = getFontName(from: url) ?? getFullFontName(from: url)

            // First unregister the font
            var error: Unmanaged<CFError>?
            let unregistered = CTFontManagerUnregisterFontsForURL(url as CFURL, .user, &error)

            if !unregistered {
                if let error = error?.takeRetainedValue() {
                    let errorDesc = CFErrorCopyDescription(error) as String
                    print("⚠️  Warning: Error unregistering font: \(errorDesc)")
                }
            }

            // Verify file still exists before deletion (race condition protection)
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("⚠️  Warning: Font file no longer exists at: \(url.path)")
                print("   File may have been removed by another process")
                print("   Font was unregistered successfully (if it was registered)")
                return
            }

            // Then delete the file
            do {
                try FileManager.default.removeItem(at: url)
                if let name = fontName {
                    print("✅ Successfully removed: \(name)")
                } else {
                    print("✅ Successfully removed font file: \(url.lastPathComponent)")
                }
            } catch let error as NSError {
                // Provide specific error guidance based on error type
                print("❌ Error deleting font file: \(error.localizedDescription)")
                print("   File: \(url.path)")
                print("")

                // Check for specific error codes to provide targeted guidance
                if error.domain == NSCocoaErrorDomain {
                    switch error.code {
                    case NSFileNoSuchFileError:
                        print("   File was removed by another process between validation and deletion")
                        print("   This is not an error - the file is already gone")
                        return  // Success - file is already deleted
                    case NSFileWriteNoPermissionError:
                        print("   Permission denied - you don't have write access to this file")
                        print("   Try running: sudo fontlift remove \(shellEscape(url.path))")
                    case NSFileReadNoSuchFileError:
                        print("   Parent directory no longer exists")
                    default:
                        print("   Common causes:")
                        print("   - File is read-only or protected")
                        print("   - Permission denied (try with sudo)")
                        print("   - File is in use by another process")
                        print("   - File is in a protected system directory")
                    }
                }

                throw ExitCode.failure
            }
        }
    }
}

