//
//  ChangedFilesListView.swift
//  GitOrigin
//
//  Selectable list of porcelain status entries for the open repository.
//

import SwiftUI

struct ChangedFilesListView: View {
    @Bindable var store: RepositoryStore

    var body: some View {
        if store.repoURL == nil {
            ContentUnavailableView(
                "No Repository",
                systemImage: "folder",
                description: Text("Choose a repository from the sidebar or open a folder.")
            )
        } else if store.changedFiles.isEmpty {
            ContentUnavailableView(
                "No Changes",
                systemImage: "checkmark.circle",
                description: Text("Working tree is clean on \(store.currentBranch ?? "this branch").")
            )
        } else {
            List(store.changedFiles, selection: selectedFileID) { file in
                HStack(spacing: 8) {
                    ChangedFileBadge(file: file)
                    Text(file.filepath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .tag(file.id)
                .contextMenu {
                    Button("Stage") {
                        Task { await store.stage(file: file) }
                    }
                    Button("Unstage") {
                        Task { await store.unstage(file: file) }
                    }
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
        }
    }

    private var selectedFileID: Binding<String?> {
        Binding(
            get: { store.selectedFile?.id },
            set: { store.selectFile(id: $0) }
        )
    }
}
