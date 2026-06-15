//
//  BranchSwitcherMenu.swift
//  GitOrigin
//
//  Toolbar menu to switch branches, create a branch, and open related PRs.
//

import SwiftUI

struct BranchSwitcherMenu: View {
    @Bindable var store: RepositoryStore

    var body: some View {
        Menu {
            if store.localBranches.isEmpty && store.remoteBranches.isEmpty {
                Button("No Branches") {}
                    .disabled(true)
            }

            ForEach(store.localBranches) { branch in
                Button {
                    store.checkoutBranch(named: branch.name)
                } label: {
                    Text(branch.isCurrent ? "\(branch.name) ✓" : branch.name)
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

            Divider()

            Button("New Branch…") {
                store.presentCreateBranchSheet()
            }

            if store.githubRepository != nil {
                Divider()
                Button("Create Pull Request on GitHub…") {
                    store.openCreatePullRequestInBrowser()
                }
                if let pullRequest = store.pullRequestForCurrentBranch {
                    Button("Open Pull Request #\(pullRequest.number)") {
                        store.openPullRequestInBrowser(pullRequest)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.branch")
                Text(store.currentBranch ?? "Branch")
                    .lineLimit(1)
                if let summary = store.upstreamStatus.summary {
                    Text(summary)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(store.repoURL == nil)
    }
}
