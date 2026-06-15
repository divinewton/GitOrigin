//
//  DiffLine.swift
//  GitOrigin
//
//  Single line in a unified diff with type (context/addition/deletion/header).
//

import Foundation

enum LineType: Hashable, Sendable {
    case addition
    case deletion
    case header
    case context
}

struct DiffLine: Identifiable, Hashable, Sendable {
    let id: Int
    let text: String
    let type: LineType
}
