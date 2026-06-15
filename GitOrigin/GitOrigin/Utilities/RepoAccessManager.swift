//
//  RepoAccessManager.swift
//  GitOrigin
//
//  NSOpenPanel for choosing a repo folder, security-scoped bookmark persistence,
//  and write-access probe. Required for App Sandbox + Mac App Store distribution.
//

import AppKit
import Foundation

@MainActor
final class RepoAccessManager {
    private static let recentBookmarksKey = "recentRepositoryBookmarks"
    private static let maxRecentCount = 12

    /// The repository URL that currently holds an active security-scoped grant.
    private var activeURL: URL?

    /// Presents a folder picker. The returned URL must be passed to `beginAccess(to:)`.
    func promptForRepository() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Open Git Repository"
        panel.message = "Choose a folder that contains a Git repository."
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = "Open"

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        return url.standardizedFileURL
    }

    /// Starts security-scoped access for `url`. Returns nil if the app cannot read the folder.
    func beginAccess(to url: URL) -> URL? {
        endAccess()

        let standardized = url.standardizedFileURL

        if let bookmarkURL = resolveSavedBookmark(matching: standardized) {
            activeURL = bookmarkURL
            return bookmarkURL
        }

        guard standardized.startAccessingSecurityScopedResource() else {
            return nil
        }

        activeURL = standardized
        return standardized
    }

    /// Releases the active security-scoped grant when closing a repository.
    func endAccess() {
        guard let activeURL else { return }
        activeURL.stopAccessingSecurityScopedResource()
        self.activeURL = nil
    }

    /// Persists a security-scoped bookmark so the repo can be reopened after relaunch.
    func addRecentRepository(_ url: URL) {
        guard let bookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else {
            return
        }

        var bookmarks = loadRecentBookmarks()
        bookmarks.removeAll { existing in
            guard let resolved = resolveBookmarkData(existing) else { return false }
            defer { resolved.stopAccessingSecurityScopedResource() }
            return resolved.standardizedFileURL == url.standardizedFileURL
        }

        bookmarks.insert(bookmark, at: 0)
        if bookmarks.count > Self.maxRecentCount {
            bookmarks = Array(bookmarks.prefix(Self.maxRecentCount))
        }

        UserDefaults.standard.set(bookmarks, forKey: Self.recentBookmarksKey)
    }

    /// Resolves saved bookmarks without starting long-lived access (for menus and catalog matching).
    func recentRepositories() -> [URL] {
        loadRecentBookmarks().compactMap { data in
            guard let url = resolveBookmarkData(data) else { return nil }
            defer { url.stopAccessingSecurityScopedResource() }
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return url.standardizedFileURL
        }
    }

    /// Opens the most recently used repository bookmark, if still available.
    func restoreRecentRepository() -> URL? {
        for data in loadRecentBookmarks() {
            guard let url = resolveBookmarkData(data) else { continue }
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            if let accessed = beginAccess(to: url) {
                return accessed
            }
        }
        return nil
    }

    func canWriteToGitDirectory(at repoURL: URL) -> Bool {
        let gitDirectory = repoURL.appendingPathComponent(".git", isDirectory: true)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: gitDirectory.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return false
        }

        let probeURL = gitDirectory.appendingPathComponent(".gitorigin-write-probe")
        do {
            try Data().write(to: probeURL, options: .atomic)
            try FileManager.default.removeItem(at: probeURL)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Bookmarks

    private func loadRecentBookmarks() -> [Data] {
        UserDefaults.standard.array(forKey: Self.recentBookmarksKey) as? [Data] ?? []
    }

    private func resolveSavedBookmark(matching url: URL) -> URL? {
        let target = url.standardizedFileURL

        for data in loadRecentBookmarks() {
            guard let resolved = resolveBookmarkData(data) else { continue }
            guard resolved.standardizedFileURL == target else {
                resolved.stopAccessingSecurityScopedResource()
                continue
            }
            guard resolved.startAccessingSecurityScopedResource() else {
                resolved.stopAccessingSecurityScopedResource()
                return nil
            }
            return resolved
        }

        return nil
    }

    private func resolveBookmarkData(_ data: Data) -> URL? {
        var isStale = false
        return try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }
}
