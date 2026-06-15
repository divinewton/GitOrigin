//
//  RepositoryCatalogItem.swift
//  GitOrigin
//
//  One row in the repository sidebar — either a GitHub repo or a local folder on disk.
//

import Foundation

struct RepositoryCatalogItem: Identifiable, Equatable, Sendable {
    enum Source: Equatable, Sendable {
        case github
        case local
    }

    let id: String
    let title: String
    let subtitle: String?
    let fullName: String?
    let localURL: URL?
    let htmlURL: URL?
    let source: Source

    var isAvailableLocally: Bool { localURL != nil }
}
