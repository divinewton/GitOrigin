//
//  GitOriginApp.swift
//  GitOrigin
//
//  App entry point and menu commands (open repo, sync, stage, commit, branches).
//

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
                Button("Open Repository…") {
                    Task { await store.openRepositoryViaPanel() }
                }
                .keyboardShortcut("o", modifiers: .command)
                .disabled(!auth.isSignedIn)
            }

            CommandMenu("Repository") {
                Button("Open Repository…") {
                    Task { await store.openRepositoryViaPanel() }
                }
                .keyboardShortcut("o", modifiers: .command)
                .disabled(!auth.isSignedIn)

                Menu("Open Recent") {
                    if store.recentRepositories.isEmpty {
                        Button("No Recent Repositories") {}
                            .disabled(true)
                    } else {
                        ForEach(store.recentRepositories, id: \.path) { url in
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

                Divider()

                Button("Stage Selected File") {
                    Task { await store.stageSelectedFile() }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(!auth.isSignedIn || store.selectedFile == nil || store.repoURL == nil)

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
}
