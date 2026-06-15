//
//  RootView.swift
//  GitOrigin
//
//  Routes between session restore, sign-in gate, and the main ContentView.
//

import SwiftUI

struct RootView: View {
    @Bindable var store: RepositoryStore
    @Bindable var auth: GitHubAuthService

    var body: some View {
        Group {
            if auth.isRestoringSession {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if auth.isSignedIn {
                ContentView(store: store, auth: auth)
            } else {
                GitHubSignInGateView(auth: auth)
            }
        }
        .frame(minWidth: 980, minHeight: 620)
        .task {
            await auth.restoreSessionIfAvailable()
            if auth.isSignedIn {
                await store.refreshRepositoryCatalog()
                await store.restoreRecentRepositoryIfAvailable()
            }
        }
        .onChange(of: auth.isSignedIn) { wasSignedIn, isSignedIn in
            if isSignedIn, !wasSignedIn {
                Task {
                    await store.refreshRepositoryCatalog()
                    await store.restoreRecentRepositoryIfAvailable()
                }
            } else if !isSignedIn {
                store.closeRepository()
            }
        }
    }
}
