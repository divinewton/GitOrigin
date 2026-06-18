//
//  ExternalEditorDiscovery.swift
//  GitOrigin
//
//  Finds installed editors/IDEs and opens a repository folder in the chosen app.
//

import AppKit
import Foundation

struct ExternalEditor: Identifiable, Equatable {
    let id: String
    let name: String
    let applicationURL: URL
}

enum ExternalEditorDiscovery {
    private static let knownEditors: [(name: String, bundleID: String)] = [
        ("Cursor", "com.todesktop.230313mzl4w4u92"),
        ("Visual Studio Code", "com.microsoft.VSCode"),
        ("Visual Studio Code - Insiders", "com.microsoft.VSCodeInsiders"),
        ("Xcode", "com.apple.dt.Xcode"),
        ("Zed", "dev.zed.Zed"),
        ("IntelliJ IDEA", "com.jetbrains.intellij"),
        ("IntelliJ IDEA CE", "com.jetbrains.intellij.ce"),
        ("WebStorm", "com.jetbrains.webstorm"),
        ("PyCharm", "com.jetbrains.pycharm"),
        ("PyCharm CE", "com.jetbrains.pycharm.ce"),
        ("GoLand", "com.jetbrains.goland"),
        ("RubyMine", "com.jetbrains.rubymine"),
        ("CLion", "com.jetbrains.clion"),
        ("Fleet", "com.jetbrains.fleet"),
        ("Android Studio", "com.google.android.studio"),
        ("Nova", "com.panic.Nova"),
        ("Sublime Text", "com.sublimetext.4"),
        ("Sublime Text", "com.sublimetext.3"),
        ("BBEdit", "com.barebones.bbedit"),
        ("TextMate", "com.macromates.TextMate"),
    ]

    static func installedEditors() -> [ExternalEditor] {
        let workspace = NSWorkspace.shared
        var seenBundleIDs = Set<String>()

        return knownEditors.compactMap { candidate in
            guard !seenBundleIDs.contains(candidate.bundleID),
                  let url = workspace.urlForApplication(withBundleIdentifier: candidate.bundleID) else {
                return nil
            }
            seenBundleIDs.insert(candidate.bundleID)
            return ExternalEditor(id: candidate.bundleID, name: candidate.name, applicationURL: url)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func open(_ folderURL: URL, with editor: ExternalEditor) {
        openFiles([folderURL], with: editor)
    }

    static func openFile(_ fileURL: URL, with editor: ExternalEditor) {
        openFiles([fileURL], with: editor)
    }

    private static func openFiles(_ urls: [URL], with editor: ExternalEditor) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        Task {
            _ = try? await NSWorkspace.shared.open(
                urls,
                withApplicationAt: editor.applicationURL,
                configuration: configuration
            )
        }
    }
}
