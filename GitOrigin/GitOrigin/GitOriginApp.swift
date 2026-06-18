//
//  GitOriginApp.swift
//  GitOrigin
//
//  App entry point and menu commands.
//

import AppKit
import SwiftUI

@main
struct GitOriginApp: App {
    @State private var auth = GitHubAuthService()
    @State private var store: RepositoryStore

    init() {
        let auth = GitHubAuthService()
        _auth = State(initialValue: auth)
        _store = State(initialValue: RepositoryStore(auth: auth))
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store, auth: auth)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Existing Repository…") {
                    store.presentAddExistingSheet()
                }
                .disabled(!auth.isSignedIn)

                Button("Clone Repository…") {
                    store.presentCloneSheetIfReady()
                }
                .disabled(!auth.isSignedIn)

                Button("Create Repository…") {
                    store.presentCreateSheet()
                }
                .disabled(!auth.isSignedIn)
            }

            CommandMenu("Repository") {
                Menu("Open Recent") {
                    if store.recentRepositories.isEmpty {
                        Button("No Recent Repositories") {}
                            .disabled(true)
                    } else {
                        ForEach(store.recentRepositories.prefix(12), id: \.path) { url in
                            Button(url.lastPathComponent) {
                                Task { await store.openRepository(at: url) }
                            }
                        }
                    }
                }
                .disabled(!auth.isSignedIn)

                Button("Close Repository") {
                    store.closeRepository()
                }
                .disabled(!auth.isSignedIn || store.repoURL == nil)

                Button("Reveal in Finder") {
                    revealCurrentRepositoryInFinder()
                }
                .disabled(!auth.isSignedIn || store.repoURL == nil)

                Divider()

                Button("Refresh Status") {
                    Task { await store.refreshStatus(userInitiated: true) }
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!auth.isSignedIn || store.repoURL == nil)

                Divider()

                Button("Fetch") {
                    Task { await store.fetch() }
                }
                .disabled(!auth.isSignedIn || store.repoURL == nil || store.isSyncing)

                Button("Pull") {
                    Task { await store.pull() }
                }
                .disabled(!auth.isSignedIn || store.repoURL == nil || store.isSyncing)

                Button("Push") {
                    Task { await store.push() }
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(!auth.isSignedIn || store.repoURL == nil || store.isSyncing)
            }

            CommandMenu("Changes") {
                Button("Stage All") {
                    Task { await store.stageAll() }
                }
                .disabled(!auth.isSignedIn || store.repoURL == nil || store.changedFiles.isEmpty)

                Button("Unstage All") {
                    Task { await store.unstageAll() }
                }
                .disabled(!auth.isSignedIn || store.repoURL == nil || store.changedFiles.isEmpty)

                Divider()

                Button("Discard Changes in Selected File") {
                    Task {
                        if let file = store.selectedFile {
                            await store.discardChanges(for: file)
                        }
                    }
                }
                .disabled(!auth.isSignedIn || store.selectedFile == nil || store.repoURL == nil)

                Divider()

                Button("Commit") {
                    Task { await store.commit() }
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!canCommitFromMenu)
            }

            CommandMenu("Branch") {
                Button("New Branch…") {
                    store.presentCreateBranchSheet()
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
                .disabled(!auth.isSignedIn || store.repoURL == nil)

                Menu("Switch Branch") {
                    if store.localBranches.isEmpty && store.remoteBranches.isEmpty {
                        Button("No Branches") {}
                            .disabled(true)
                    } else {
                        ForEach(store.localBranches) { branch in
                            Button(branchMenuTitle(for: branch)) {
                                store.checkoutBranch(named: branch.name)
                            }
                            .disabled(branch.isCurrent)
                        }

                        if !store.localBranches.isEmpty && !store.remoteBranches.isEmpty {
                            Divider()
                        }

                        ForEach(store.remoteBranches) { branch in
                            Button(branch.name) {
                                store.requestCheckout(branch: branch)
                            }
                        }
                    }
                }
                .disabled(!auth.isSignedIn || store.repoURL == nil)

                Menu("View History") {
                    ForEach(store.localBranches) { branch in
                        Button(branch.name) {
                            store.viewHistory(for: branch.name)
                        }
                    }
                    if !store.remoteBranches.isEmpty {
                        Divider()
                        ForEach(store.remoteBranches) { branch in
                            Button(branch.name) {
                                store.viewHistory(for: branch.name)
                            }
                        }
                    }
                }
                .disabled(!auth.isSignedIn || store.repoURL == nil)

                Divider()

                Menu("Pull Requests") {
                    if store.isLoadingPullRequests {
                        Button("Loading…") {}
                            .disabled(true)
                    } else if store.pullRequests.isEmpty {
                        Button("No Open Pull Requests") {}
                            .disabled(true)
                    } else {
                        ForEach(store.pullRequests) { pullRequest in
                            Button("#\(pullRequest.number) \(pullRequest.title)") {
                                store.openPullRequestInBrowser(pullRequest)
                            }
                        }
                    }

                    Divider()

                    Button("Refresh Pull Requests") {
                        Task { await store.refreshPullRequests() }
                    }

                    Button("Create Pull Request on GitHub…") {
                        store.openCreatePullRequestInBrowser()
                    }
                    .disabled(store.githubRepository == nil)

                    if let pullRequest = store.pullRequestForCurrentBranch {
                        Button("Open Current Branch PR #\(pullRequest.number)") {
                            store.openPullRequestInBrowser(pullRequest)
                        }
                    }
                }
                .disabled(!auth.isSignedIn || store.repoURL == nil)
            }
        }

        Settings {
            SettingsView(auth: auth, store: store)
        }
    }

    private var canCommitFromMenu: Bool {
        auth.isSignedIn
            && store.isCommitFieldFocused
            && !store.commitSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && store.repoURL != nil
            && !store.isCommitting
    }

    private func branchMenuTitle(for branch: GitBranch) -> String {
        branch.isCurrent ? "\(branch.name) ✓" : branch.name
    }

    private func revealCurrentRepositoryInFinder() {
        guard let repoURL = store.repoURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([repoURL])
    }
}
