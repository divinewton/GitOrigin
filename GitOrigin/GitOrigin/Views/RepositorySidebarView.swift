//
//  RepositorySidebarView.swift
//  GitOrigin
//
//  Collapsible list of GitHub repos and local folders the user can open.
//

import AppKit
import SwiftUI

struct RepositorySidebarView: View {
    @Bindable var store: RepositoryStore

    var body: some View {
        List {
            Section {
                Button {
                    Task { await store.openRepositoryViaPanel() }
                } label: {
                    Label("Open Folder…", systemImage: "folder.badge.plus")
                }

                Button {
                    Task { await store.refreshRepositoryCatalog() }
                } label: {
                    Label("Refresh List", systemImage: "arrow.clockwise")
                }
            }

            if !githubItems.isEmpty {
                Section("GitHub") {
                    ForEach(githubItems) { item in
                        repositoryRow(item)
                    }
                }
            }

            if !localItems.isEmpty {
                Section("On This Mac") {
                    ForEach(localItems) { item in
                        repositoryRow(item)
                    }
                }
            }

            if store.isLoadingCatalog && store.catalogItems.isEmpty {
                Section {
                    ProgressView("Loading repositories…")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Repositories")
    }

    private var githubItems: [RepositoryCatalogItem] {
        store.catalogItems.filter { $0.source == .github }
    }

    private var localItems: [RepositoryCatalogItem] {
        store.catalogItems.filter { $0.source == .local }
    }

    @ViewBuilder
    private func repositoryRow(_ item: RepositoryCatalogItem) -> some View {
        Button {
            Task { await store.openCatalogItem(item) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .fontWeight(isSelected(item) ? .semibold : .regular)
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if item.isAvailableLocally {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .help("Available on this Mac")
                } else {
                    Image(systemName: "icloud")
                        .foregroundStyle(.tertiary)
                        .help("Open on GitHub or locate local folder")
                }
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(isSelected(item) ? Color.accentColor.opacity(0.12) : Color.clear)
        .contextMenu {
            if let htmlURL = item.htmlURL {
                Button("Open on GitHub") {
                    NSWorkspace.shared.open(htmlURL)
                }
            }
            if item.isAvailableLocally, let url = item.localURL {
                Button("Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
        }
    }

    private func isSelected(_ item: RepositoryCatalogItem) -> Bool {
        guard let localURL = item.localURL, let repoURL = store.repoURL else { return false }
        return localURL.standardizedFileURL == repoURL.standardizedFileURL
    }
}
