// this_file: Sources/fontlift/fontlift.swift
// fontlift-mac - macOS CLI tool for font installation and management

import ArgumentParser
import CoreText
import Foundation
import Darwin

// MARK: - Version Management
/// Current version of fontlift-mac
/// When updating, also update:
/// - CHANGELOG.md (add new version section)
/// - Git tag (git tag vX.Y.Z)
private let fontLabAttribution = "made by FontLab https://www.fontlab.com/"
private let version = "2.0.0"
private let binaryName = "fontlift-mac"
private let fakeRegistrationMode = ProcessInfo.processInfo.environment["FONTLIFT_FAKE_REGISTRATION"] == "1"
private let overrideUserLibraryPath = ProcessInfo.processInfo.environment["FONTLIFT_OVERRIDE_USER_LIBRARY"]
private let overrideSystemLibraryPath = ProcessInfo.processInfo.environment["FONTLIFT_OVERRIDE_SYSTEM_LIBRARY"]
var fontManagerUnregisterFontsForURL: (CFURL, CTFontManagerScope, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> Bool = CTFontManagerUnregisterFontsForURL

private struct ThirdPartyCacheSummary {
    let userRemoved: Int
    let systemRemoved: Int
    let warnings: [String]
}

private let adobeCacheRegex = try! NSRegularExpression(pattern: "^(Adobe|Acro|Illustrator)Fnt.*\\.lst$", options: .caseInsensitive)
private let officeCacheRegex = try! NSRegularExpression(pattern: "^Office Font Cache.*$", options: .caseInsensitive)

private func resolvedUserLibraryURL() -> URL {
    if let overrideUserLibraryPath, !overrideUserLibraryPath.isEmpty {
        return URL(fileURLWithPath: overrideUserLibraryPath, isDirectory: true)
    }
    return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library", isDirectory: true)
}

private func resolvedSystemLibraryURL() -> URL {
    if let overrideSystemLibraryPath, !overrideSystemLibraryPath.isEmpty {
        return URL(fileURLWithPath: overrideSystemLibraryPath, isDirectory: true)
    }
    return URL(fileURLWithPath: "/Library", isDirectory: true)
}

private func regexMatches(_ regex: NSRegularExpression, string: String) -> Bool {
    let range = NSRange(location: 0, length: (string as NSString).length)
    return regex.firstMatch(in: string, options: [], range: range) != nil
}

private struct FakeFontRegistry: Codable {
    private var fontsByName: [String: [String]] = [:]

    mutating func register(name: String, path: String) {
        var paths = fontsByName[name] ?? []
        if !paths.contains(path) {
            paths.append(path)
            fontsByName[name] = paths
        }
    }

    mutating func unregister(path: String) -> Bool {
        var removed = false
        for (name, var paths) in fontsByName {
            if let index = paths.firstIndex(of: path) {
                paths.remove(at: index)
                removed = true
                if paths.isEmpty {
                    fontsByName.removeValue(forKey: name)
                } else {
                    fontsByName[name] = paths
                }
                break
            }
        }
        return removed
    }

    func paths(for name: String) -> [String] {
        fontsByName[name] ?? []
    }

    func allPaths() -> [String] {
        fontsByName.values.flatMap { $0 }
    }
}

private var fakeFontRegistry = FakeFontRegistry()
private let fakeRegistryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("fontlift-fake-registry.json")
private var isFakeRegistryLoaded = false
private func persistFakeRegistry() {
    guard fakeRegistrationMode else { return }
    ensureFakeRegistryLoaded()
    if let data = try? JSONEncoder().encode(fakeFontRegistry) {
        try? data.write(to: fakeRegistryURL, options: .atomic)
    }
}
private func ensureFakeRegistryLoaded(reload: Bool = false) {
    guard fakeRegistrationMode else { return }
    if !isFakeRegistryLoaded || reload {
        if FileManager.default.fileExists(atPath: fakeRegistryURL.path),
           let data = try? Data(contentsOf: fakeRegistryURL),
           let registry = try? JSONDecoder().decode(FakeFontRegistry.self, from: data) {
            fakeFontRegistry = registry
        }
        atexit {
            guard fakeRegistrationMode else { return }
            persistFakeRegistry()
        }
        isFakeRegistryLoaded = true
    }
}

// MARK: - Font Management Helpers

/// Escape a file path for safe use in shell commands
///
/// Wraps paths containing special characters in single quotes and escapes any single quotes within.
/// This ensures suggested shell commands (like "sudo fontlift-mac remove '/path/to/file'") work correctly
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

/// Get the font family name from a URL
///
/// Extracts the human-readable family name (e.g., "Helvetica") using Core Text APIs.
/// This differs from the PostScript name which includes weight/style (e.g., "Helvetica-Bold").
///
/// - Parameter url: File URL pointing to a font file (.ttf, .otf, .ttc, .otc)
/// - Returns: Family name string if successful; `nil` otherwise
func getFontFamilyName(from url: URL) -> String? {
    guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
          let descriptor = descriptors.first else {
        return nil
    }

    return CTFontDescriptorCopyAttribute(descriptor, kCTFontFamilyNameAttribute) as? String
}

/// Run a shell command and capture output/status.
///
/// Used for lightweight system maintenance commands (e.g., clearing font caches).
/// Returns combined stdout/stderr output trimmed of trailing whitespace.
///
/// - Parameter command: Command string executed via `/bin/zsh -c`
/// - Returns: Tuple of optional output string and process exit status
func shell(_ command: String) -> (String?, Int32) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", command]

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    do {
        try process.run()
    } catch {
        return ("Failed to launch command: \(error.localizedDescription)", -1)
    }

    process.waitUntilExit()

    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

    let stdout = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let stderr = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    let combined = [stdout, stderr].filter { !$0.isEmpty }.joined(separator: "\n")
    return (combined.isEmpty ? nil : combined, process.terminationStatus)
}

/// Unregister a font from the system with shared safety checks.
///
/// - Parameters:
///   - url: Font file URL to unregister
///   - admin: When `true`, unregisters at `.session` scope (requires sudo). Otherwise `.user`.
///   - silent: When `true`, suppresses informational logging (still throws on failures).
/// - Throws: `ExitCode.failure` when unregistration is blocked or fails.
func unregisterFont(at url: URL, admin: Bool, silent: Bool = false) throws {
    if isSystemFontPath(url) {
        if !silent {
            print("❌ Error: Cannot uninstall system font.")
            print("   Path: \(url.path)")
            print("   System fonts in /System/Library/Fonts/ and /Library/Fonts/ are protected for macOS stability.")
            print("   Operations on these directories are blocked for safety.")
        }
        throw ExitCode.failure
    }

    if fakeRegistrationMode {
        ensureFakeRegistryLoaded()
        let removed = fakeFontRegistry.unregister(path: url.path)
        persistFakeRegistry()
        guard !silent else { return }

        let scopeDescription = "user-level and system-level (simulated)"
        if let fontName = getFontName(from: url) ?? getFullFontName(from: url) {
            if removed {
                print("✅ [Simulated] Unregistered '\(fontName)' (\(scopeDescription))")
            } else {
                print("ℹ️  [Simulated] No registration found for '\(fontName)' (\(scopeDescription))")
            }
        } else {
            if removed {
                print("✅ [Simulated] Unregistered font at \(url.path) (\(scopeDescription))")
            } else {
                print("ℹ️  [Simulated] No registration found at \(url.path) (\(scopeDescription))")
            }
        }
        return
    }

    func attemptUnregister(scope: CTFontManagerScope) -> (Bool, String?) {
        var error: Unmanaged<CFError>?
        let success = fontManagerUnregisterFontsForURL(url as CFURL, scope, &error)

        if success {
            return (true, nil)
        }

        if let error = error?.takeRetainedValue() {
            return (false, CFErrorCopyDescription(error) as String)
        }

        return (false, "Failed to unregister font due to unknown Core Text error.")
    }

    let (userSuccess, userError) = attemptUnregister(scope: .user)
    let (systemSuccess, systemError) = attemptUnregister(scope: .session)

    if userSuccess || systemSuccess {
        guard !silent else { return }

        let scopeDescription: String
        switch (userSuccess, systemSuccess) {
        case (true, true):
            scopeDescription = "user-level and system-level"
        case (true, false):
            scopeDescription = "user-level"
        case (false, true):
            scopeDescription = "system-level"
        case (false, false):
            scopeDescription = "unknown scope"
        }

        if let fontName = getFontName(from: url) ?? getFullFontName(from: url) {
            print("✅ Successfully unregistered '\(fontName)' (\(scopeDescription))")
        } else {
            print("✅ Successfully unregistered font at \(url.path) (\(scopeDescription))")
        }
        return
    }

    print("❌ Error: Unable to unregister font in user or system scope.")
    print("   File: \(url.path)")
    if let userError {
        print("   User scope: \(userError)")
    }
    if let systemError {
        print("   System scope: \(systemError)")
    }
    if geteuid() != 0 && !admin {
        print("   Tip: Try running with sudo and the --admin flag to remove system-level registrations.")
    }
    throw ExitCode.failure
}

/// Build formatted list output for the `list` command.
///
/// - Parameters:
///   - fontURLs: Font file URLs returned by Core Text.
///   - showPath: Include file paths in output.
///   - showName: Include font names in output.
///   - dedupeAll: When true, deduplicates all output lines. Paths are always deduplicated when shown alone.
/// - Returns: Sorted array of formatted output lines.
func buildListOutput(
    fontURLs: [URL],
    showPath: Bool,
    showName: Bool,
    dedupeAll: Bool
) -> [String] {
    var lines: [String] = []

    for fontURL in fontURLs {
        if showPath && showName {
            let fontName = getFontName(from: fontURL) ?? getFullFontName(from: fontURL) ?? "Unknown"
            lines.append("\(fontURL.path)::\(fontName)")
        } else if showPath {
            lines.append(fontURL.path)
        } else if let fontName = getFontName(from: fontURL) ?? getFullFontName(from: fontURL) {
            lines.append(fontName)
        }
    }

    let shouldDedupe = dedupeAll || (showPath && !showName)
    if shouldDedupe {
        lines = Array(Set(lines))
    }

    return lines.sorted()
}

@main
struct Fontlift: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: binaryName,
        abstract: "Install, uninstall, list, and remove fonts on macOS",
        discussion: fontLabAttribution,
        version: "\(version) - \(fontLabAttribution)",
        subcommands: [
            List.self,
            Install.self,
            Uninstall.self,
            Remove.self,
            Cleanup.self
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
    /// Behavior:
    /// - Output is always alphabetically sorted.
    /// - Path-only output is automatically deduplicated.
    /// - `-s` / `--sorted` additionally deduplicates name and `path::name` output.
    ///
    /// Output modes (all sorted):
    /// - Default (`-p`): Font file paths only (deduped)
    /// - Names (`-n`): Internal font names (may repeat without `-s`)
    /// - Both (`-p -n`): Combined format as `path::name` (deduped with `-s`)
    ///
    /// The output is pure data (no headers/footers) for pipe-friendly usage.
    ///
    /// Examples:
    /// ```bash
    /// fontlift-mac list              # Sorted, deduped font paths
    /// fontlift-mac list -n           # Sorted font names (dedupe with -s if needed)
    /// fontlift-mac list -p -n        # Sorted path::name pairs
    /// fontlift-mac list -n -s        # Sorted, deduped font names
    /// fontlift-mac list | wc -l      # Count total fonts
    /// fontlift-mac l                 # Same as 'list' (alias)
    /// ```
    ///
    /// Typical systems have 5000+ fonts installed.
    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List installed fonts",
            discussion: fontLabAttribution,
            aliases: ["l"]
        )

        @Flag(name: .shortAndLong, help: "Show font file paths")
        var path = false

        @Flag(name: .shortAndLong, help: "Show internal font names")
        var name = false

        @Flag(name: .shortAndLong, help: "Deduplicate names or path::name output (paths are deduped automatically)")
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

            let lines = buildListOutput(
                fontURLs: fontURLs,
                showPath: showPath,
                showName: showName,
                dedupeAll: sorted
            )

            // Output pure data only - no headers or footers
            for line in lines {
                print(line)
            }
        }
    }
}

// MARK: - Cleanup Command
extension Fontlift {
    /// Maintenance command to prune missing registrations and clear caches.
    struct Cleanup: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "cleanup",
            abstract: "Prune missing fonts and clear font caches",
            discussion: fontLabAttribution,
            aliases: ["c"]
        )

        @Flag(help: "Only prune missing font file registrations.")
        var pruneOnly = false

        @Flag(help: "Only clear font caches.")
        var cacheOnly = false

        @Flag(name: .shortAndLong, help: "Perform system-level cleanup (all users, requires sudo)")
        var admin = false

        func run() throws {
            let runBoth = (!pruneOnly && !cacheOnly) || (pruneOnly && cacheOnly)
            let doPrune = runBoth || pruneOnly
            let doCache = runBoth || cacheOnly
            let scopeDescription = admin ? "system-level (all users)" : "user-level (current user)"

            print("Scope: \(scopeDescription)")

            var hadErrors = false

            if doPrune {
                print("--- Pruning Missing Fonts ---")
                do {
                    try pruneMissingFonts(admin: admin)
                } catch {
                    hadErrors = true
                    print("❌ Pruning missing fonts failed.")
                }
                print("")
            }

            if doCache {
                print("--- Clearing Font Caches ---")
                do {
                    try clearFontCaches(admin: admin)
                } catch {
                    hadErrors = true
                    print("❌ Cache clearing failed.")
                }
                print("")
            }

            print("✅ Cleanup complete.")
            if hadErrors {
                throw ExitCode.failure
            }
        }

        /// Scan all registered fonts and remove entries whose files are missing.
        private func pruneMissingFonts(admin: Bool) throws {
            print("Scanning for missing font registrations...")

            if fakeRegistrationMode {
                var registry = FakeFontRegistry()
                if let data = try? Data(contentsOf: fakeRegistryURL),
                   let decoded = try? JSONDecoder().decode(FakeFontRegistry.self, from: data) {
                    registry = decoded
                }

                let paths = registry.allPaths()
                var prunedCount = 0
                var checkedCount = 0

                for path in paths {
                    checkedCount += 1
                    if FileManager.default.fileExists(atPath: path) {
                        continue
                    }

                    print("🗑️ Pruning missing font registration: \(path)")
                    _ = registry.unregister(path: path)
                    prunedCount += 1
                }

                fakeFontRegistry = registry
                if let encoded = try? JSONEncoder().encode(registry) {
                    try? encoded.write(to: fakeRegistryURL, options: .atomic)
                }

                print("Scan complete. Checked \(checkedCount) fonts, pruned \(prunedCount) registrations.")
                return
            }

            guard let fontURLs = CTFontManagerCopyAvailableFontURLs() as? [URL] else {
                print("❌ Error: Could not retrieve font list from system.")
                throw ExitCode.failure
            }

            var prunedCount = 0
            var checkedCount = 0

            for url in fontURLs {
                checkedCount += 1

                if isSystemFontPath(url) {
                    continue
                }

                guard url.isFileURL else {
                    continue
                }

                if FileManager.default.fileExists(atPath: url.path) {
                    continue
                }

                print("🗑️ Pruning missing font registration: \(url.path)")

                if fakeRegistrationMode {
                    prunedCount += 1
                    continue
                }

                var userError: Unmanaged<CFError>?
                let userSuccess = CTFontManagerUnregisterFontsForURL(url as CFURL, .user, &userError)

                var sessionSuccess = false
                var sessionError: Unmanaged<CFError>?
                if admin {
                    sessionSuccess = CTFontManagerUnregisterFontsForURL(url as CFURL, .session, &sessionError)
                }

                if !userSuccess, let error = userError?.takeRetainedValue() {
                    let description = CFErrorCopyDescription(error) as String
                    print("   ⚠️ Unable to unregister user scope: \(description)")
                }

                if admin, !sessionSuccess, let error = sessionError?.takeRetainedValue() {
                    let description = CFErrorCopyDescription(error) as String
                    print("   ⚠️ Unable to unregister system scope: \(description)")
                }

                if userSuccess || (admin && sessionSuccess) {
                    prunedCount += 1
                } else {
                    print("   ⚠️ Font remains registered; manual intervention may be required.")
                }
            }

            print("Scan complete. Checked \(checkedCount) fonts, pruned \(prunedCount) registrations.")
        }

        /// Clear Core Text font caches via atsutil and purge third-party caches.
        private func clearFontCaches(admin: Bool) throws {
            let scopeLabel = admin ? "system" : "user"
            print("Clearing \(scopeLabel) font cache...")

            if fakeRegistrationMode {
                let message = admin ? "✅ [Simulated] System font cache cleared successfully." : "✅ [Simulated] User font cache cleared successfully."
                print(message)
            } else {
                if admin && geteuid() != 0 {
                    print("❌ Error: System-level cache clearing requires administrator privileges.")
                    print("   Run with sudo: sudo fontlift-mac cleanup --admin --cache-only")
                    throw ExitCode.failure
                }

                let command = admin ? "atsutil databases -remove" : "atsutil databases -removeUser"
                let (output, status) = shell(command)

                if status != 0 {
                    print("❌ Error: Failed to clear font cache (status \(status)).")
                    if let output {
                        print("   Details: \(output)")
                    }
                    throw ExitCode.failure
                }

                let successMessage = admin ? "✅ System font cache cleared successfully." : "✅ User font cache cleared successfully."
                print(successMessage)

                if admin {
                    let (_, shutdownStatus) = shell("atsutil server -shutdown")
                    if shutdownStatus != 0 {
                        print("   ⚠️ Warning: Unable to restart ATS server automatically. A reboot will rebuild caches.")
                    } else {
                        _ = shell("atsutil server -ping")
                    }
                }
            }

            print("   A logout or reboot may be required for changes to apply.")
            let summary = clearThirdPartyCaches(admin: admin)
            reportThirdPartySummary(summary, admin: admin)
        }

        private func clearThirdPartyCaches(admin: Bool) -> ThirdPartyCacheSummary {
            var warnings: [String] = []
            let userRemoved = removeThirdPartyCaches(in: resolvedUserLibraryURL(), scopeDescription: "user", warnings: &warnings)

            var systemRemoved = 0
            if admin {
                systemRemoved = removeThirdPartyCaches(in: resolvedSystemLibraryURL(), scopeDescription: "system", warnings: &warnings)
            }

            return ThirdPartyCacheSummary(userRemoved: userRemoved, systemRemoved: systemRemoved, warnings: warnings)
        }

        private func reportThirdPartySummary(_ summary: ThirdPartyCacheSummary, admin: Bool) {
            let totalRemoved = summary.userRemoved + summary.systemRemoved

            if totalRemoved == 0 {
                print("   No third-party font cache files were found.")
            } else if admin {
                print("   Removed \(summary.userRemoved) user and \(summary.systemRemoved) system third-party cache file(s) (Adobe, Microsoft).")
            } else {
                print("   Removed \(summary.userRemoved) third-party cache file(s) (Adobe, Microsoft).")
            }

            for warning in summary.warnings {
                print("   ⚠️ \(warning)")
            }
        }

        private func removeThirdPartyCaches(in library: URL, scopeDescription: String, warnings: inout [String]) -> Int {
            let fileManager = FileManager.default
            var removed = 0
            var localWarnings = warnings

            let directDirectories = [
                library.appendingPathComponent("Caches/com.adobe.fonts", isDirectory: true),
                library.appendingPathComponent("Caches/com.apple.iwork.fonts", isDirectory: true)
            ]

            for directory in directDirectories {
                if fileManager.fileExists(atPath: directory.path) {
                    do {
                        try fileManager.removeItem(at: directory)
                        removed += 1
                    } catch {
                        localWarnings.append("Failed to remove \(scopeDescription) cache at \(directory.path): \(error.localizedDescription)")
                    }
                }
            }

            let searchDirectories = [
                library.appendingPathComponent("Application Support/Adobe", isDirectory: true),
                library.appendingPathComponent("Caches/Adobe", isDirectory: true),
                library.appendingPathComponent("Preferences/Adobe", isDirectory: true),
                library.appendingPathComponent("Preferences/Microsoft", isDirectory: true)
            ]

            for directory in searchDirectories {
                guard fileManager.fileExists(atPath: directory.path) else {
                    continue
                }

                let enumerator = fileManager.enumerator(
                    at: directory,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsPackageDescendants, .skipsHiddenFiles],
                    errorHandler: { url, error -> Bool in
                        localWarnings.append("Failed to enumerate \(url.path) while clearing \(scopeDescription) caches: \(error.localizedDescription)")
                        return true
                    }
                )

                while let url = enumerator?.nextObject() as? URL {
                    let resourceValues: URLResourceValues
                    do {
                        resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
                    } catch {
                        localWarnings.append("Failed to read attributes for \(url.path): \(error.localizedDescription)")
                        continue
                    }

                    if resourceValues.isDirectory == true {
                        continue
                    }

                    let name = url.lastPathComponent
                    let isAdobeCache = regexMatches(adobeCacheRegex, string: name)
                    let isOfficeCache = regexMatches(officeCacheRegex, string: name)

                    if isAdobeCache || isOfficeCache {
                        do {
                            try fileManager.removeItem(at: url)
                            removed += 1
                        } catch {
                            localWarnings.append("Failed to remove \(scopeDescription) cache file \(url.path): \(error.localizedDescription)")
                        }
                    }
                }
            }

            warnings = localWarnings
            return removed
        }
    }
}

// MARK: - Install Command
extension Fontlift {
    /// Install a font file to the system.
    ///
    /// Registers the font with macOS using `CTFontManagerRegisterFontsForURL()` at user scope
    /// (default) or system scope (with `--admin` flag).
    ///
    /// **User-level installation (default):**
    /// - Font available only to the current user
    /// - No administrator privileges required
    /// - Font registered at `.user` scope
    ///
    /// **System-level installation (--admin flag):**
    /// - Font available to all users in the current login session
    /// - Requires administrator privileges (run with `sudo`)
    /// - Font registered at `.session` scope
    ///
    /// The font file remains in its original location - this command only registers it with
    /// the system font manager. Use the remove command to both unregister and delete the file.
    ///
    /// Supports individual font files and font collections (.ttc/.otc).
    ///
    /// Example usage:
    /// ```bash
    /// fontlift-mac install ~/Downloads/CustomFont.ttf        # User-level
    /// fontlift-mac i /path/to/font.otf                       # User-level
    /// sudo fontlift-mac install --admin /path/to/font.ttf    # System-level (all users)
    /// sudo fontlift-mac i -a /path/to/font.ttf               # System-level (shorthand)
    /// ```
    struct Install: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "install",
            abstract: "Install fonts from file paths",
            discussion: fontLabAttribution,
            aliases: ["i"]
        )

        @Argument(help: "Font file path to install")
        var fontPath: String

        @Flag(name: .shortAndLong, help: "Install at system level (all users, requires sudo)")
        var admin = false

        func run() throws {
            // Validate file path before attempting installation
            guard validateFilePath(fontPath) else {
                throw ExitCode.failure
            }

            let url = URL(fileURLWithPath: fontPath)
            let scope: CTFontManagerScope = admin ? .session : .user
            let scopeDesc = admin ? "system-level (all users)" : "user-level"

            guard let newPostScriptName = getFontName(from: url) else {
                print("❌ Error: Could not read PostScript name from font file.")
                print("   File: \(fontPath)")
                print("   The file may be invalid or corrupted.")
                throw ExitCode.failure
            }

            let familyName = getFontFamilyName(from: url)

            print("Installing font from: \(fontPath)")
            print("Scope: \(scopeDesc)")
            if let familyName {
                print("PostScript: \(newPostScriptName) • Family: \(familyName)")
            } else {
                print("PostScript: \(newPostScriptName) • Family: Unknown")
            }

            // Attempt to find and remove conflicting registrations first
            if let existingFontURLs = CTFontManagerCopyAvailableFontURLs() as? [URL] {
                print("Checking for existing versions...")
                for existingURL in existingFontURLs {
                    if existingURL.path == url.path {
                        continue
                    }

                    guard let existingPostScript = getFontName(from: existingURL) else {
                        continue
                    }

                    if existingPostScript == newPostScriptName {
                        if isSystemFontPath(existingURL) {
                            print("❌ Error: Cannot replace protected system font.")
                            print("   Path: \(existingURL.path)")
                            print("   Installation aborted to prevent system instability.")
                            throw ExitCode.failure
                        }

                        print("Auto-uninstalling older version at: \(existingURL.path)")
                        do {
                            try unregisterFont(at: existingURL, admin: admin)
                        } catch {
                            print("⚠️ Warning: Unable to unregister older version at \(existingURL.path).")
                            print("   Proceeding with installation may leave duplicate registrations.")
                        }
                    }
                }
            } else {
                print("⚠️ Warning: Could not enumerate installed fonts. Skipping auto-uninstall check.")
            }

            if fakeRegistrationMode {
                ensureFakeRegistryLoaded()
                var existingPaths = fakeFontRegistry.paths(for: newPostScriptName).filter { $0 != url.path }
                if existingPaths.isEmpty {
                    existingPaths = fakeFontRegistry.allPaths().filter { candidatePath in
                        guard candidatePath != url.path else { return false }
                        let candidateURL = URL(fileURLWithPath: candidatePath)
                        return (getFontName(from: candidateURL) ?? getFullFontName(from: candidateURL)) == newPostScriptName
                    }
                }

                for path in existingPaths {
                    print("Auto-uninstalling older version at: \(path)")
                    do {
                        try unregisterFont(at: URL(fileURLWithPath: path), admin: admin)
                    } catch {
                        // In simulated mode, failures are already reported.
                    }
                }
                fakeFontRegistry.register(name: newPostScriptName, path: url.path)
                persistFakeRegistry()
                print("✅ [Simulated] Installed: \(newPostScriptName)")
                return
            }

            var error: Unmanaged<CFError>?
            // Register font at .user scope (doesn't require sudo, available to current user only)
            // Or .session scope (requires sudo, available to all users in current login session)
            let success = CTFontManagerRegisterFontsForURL(url as CFURL, scope, &error)

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
                        print("   Use 'fontlift-mac list' to see all installed fonts")
                        print("   Use 'fontlift-mac uninstall' to remove before reinstalling")
                        throw ExitCode.failure
                    }

                    // Generic error handling for other failures
                    print("❌ Error installing font: \(errorDesc)")
                    print("   File: \(fontPath)")
                    print("")
                    print("   Common causes:")
                    print("   - Invalid or corrupted font file")
                    print("   - Font format not supported (.ttf, .otf, .ttc, .otc)")

                    if admin {
                        print("   - Permission denied (ensure you're running with sudo)")
                        print("   - System-level installation requires administrator privileges")
                    } else {
                        print("   - Permission issues (try with --admin flag and sudo for system-level install)")
                    }
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
    /// **User-level uninstallation (default):**
    /// - Removes font registration for the current user only
    /// - No administrator privileges required
    /// - Font deregistered at `.user` scope
    ///
    /// **System-level uninstallation (--admin flag):**
    /// - Removes font registration for all users in the current login session
    /// - Requires administrator privileges (run with `sudo`)
    /// - Font deregistered at `.session` scope
    ///
    /// You can specify the font either by:
    /// - File path: `fontlift-mac uninstall /path/to/font.ttf`
    /// - Font name: `fontlift-mac uninstall -n "Arial"`
    ///
    /// When using `-n`, the command searches all installed fonts to find a matching name.
    /// If the font file no longer exists but is still registered, uninstall will attempt
    /// to deregister it anyway.
    ///
    /// Use the remove command if you want to both unregister and delete the file.
    ///
    /// Example usage:
    /// ```bash
    /// fontlift-mac uninstall ~/Downloads/CustomFont.ttf        # User-level
    /// fontlift-mac u -n "Helvetica Neue"                       # User-level
    /// sudo fontlift-mac uninstall --admin /path/to/font.ttf    # System-level (all users)
    /// sudo fontlift-mac u -a -n "Arial"                        # System-level (shorthand)
    /// ```
    struct Uninstall: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "uninstall",
            abstract: "Uninstall fonts (keeping files)",
            discussion: fontLabAttribution,
            aliases: ["u"]
        )

        @Option(name: .shortAndLong, help: "Font name to uninstall")
        var name: String?

        @Argument(help: "Font file path to uninstall")
        var fontPath: String?

        @Flag(name: .shortAndLong, help: "Uninstall at system level (all users, requires sudo)")
        var admin = false

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
                    print("   - Use 'fontlift-mac list -n' to see all installed font names")
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
                        print("        fontlift-mac uninstall \(shellEscape(url.path))")
                    }
                    print("")
                    print("   Copy and run one of the commands above to uninstall the specific font.")
                    throw ExitCode.failure
                }

                let url = matchingURLs[0]

                let scopeDesc = admin ? "system-level (all users)" : "user-level"
                print("Scope: \(scopeDesc)")
                try unregisterFont(at: url, admin: admin)

            } else if let path = fontPath {
                let url = URL(fileURLWithPath: path)

                if !FileManager.default.fileExists(atPath: path) {
                    print("⚠️  Warning: Font file not found at path: \(path)")
                    print("Attempting to uninstall anyway...")
                }

                print("Uninstalling font from path: \(path)")
                let scopeDesc = admin ? "system-level (all users)" : "user-level"
                print("Scope: \(scopeDesc)")
                try unregisterFont(at: url, admin: admin)
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
    /// **User-level removal (default):**
    /// - Removes font registration for the current user only
    /// - Deletes the font file (requires write permission to file)
    /// - No administrator privileges required for deregistration
    /// - Font deregistered at `.user` scope
    ///
    /// **System-level removal (--admin flag):**
    /// - Removes font registration for all users in the current login session
    /// - Deletes the font file (requires write permission to file)
    /// - Requires administrator privileges (run with `sudo`)
    /// - Font deregistered at `.session` scope
    ///
    /// You can specify the font either by:
    /// - File path: `fontlift-mac remove /path/to/font.ttf`
    /// - Font name: `fontlift-mac remove -n "Arial"`
    ///
    /// When using `-n`, the command searches all installed fonts to find the file location,
    /// then unregisters and deletes it.
    ///
    /// If unregistration fails, the command will still attempt to delete the file.
    /// Use uninstall if you only want to deregister without deleting.
    ///
    /// Example usage:
    /// ```bash
    /// fontlift-mac remove ~/Downloads/CustomFont.ttf        # User-level
    /// fontlift-mac rm -n "Helvetica Neue"                   # User-level
    /// sudo fontlift-mac remove --admin /path/to/font.ttf    # System-level (all users)
    /// sudo fontlift-mac rm -a -n "Arial"                    # System-level (shorthand)
    /// ```
    struct Remove: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "remove",
            abstract: "Remove fonts (uninstall and delete files)",
            discussion: fontLabAttribution,
            aliases: ["rm"]
        )

        @Option(name: .shortAndLong, help: "Font name to remove")
        var name: String?

        @Argument(help: "Font file path to remove")
        var fontPath: String?

        @Flag(name: .shortAndLong, help: "Remove at system level (all users, requires sudo)")
        var admin = false

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
                    print("   - Use 'fontlift-mac list -n' to see all installed font names")
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
                        print("        fontlift-mac remove \(shellEscape(url.path))")
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

            let scopeDesc = admin ? "system-level (all users)" : "user-level"
            print("Scope: \(scopeDesc)")

            // Get font name before deletion (file must exist to read metadata)
            let fontName = getFontName(from: url) ?? getFullFontName(from: url)

            do {
                try unregisterFont(at: url, admin: admin, silent: true)
            } catch {
                print("⚠️  Warning: Font unregistration failed. Proceeding with file deletion.")
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
                        print("   Try running: sudo fontlift-mac remove \(shellEscape(url.path))")
                    case NSFileReadNoSuchFileError:
                        print("   Parent directory no longer exists")
                    default:
                        print("   Common causes:")
                        print("   - File is read-only or protected")

                        if admin {
                            print("   - Ensure you're running with sudo for system-level operations")
                        } else {
                            print("   - Permission denied (try with sudo)")
                        }

                        print("   - File is in use by another process")
                        print("   - File is in a protected system directory")
                    }
                }

                throw ExitCode.failure
            }
        }
    }
}
