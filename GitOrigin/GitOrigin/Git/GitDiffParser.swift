//
//  GitDiffParser.swift
//  GitOrigin
//
//  Parses unified diff text into DiffLine models for DiffView.
//

import Foundation

enum GitDiffParser {
    static func parse(_ output: String) -> [DiffLine] {
        guard !output.isEmpty else { return [] }

        var lines: [DiffLine] = []
        var index = 0

        for rawLine in output.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            lines.append(DiffLine(id: index, text: line, type: lineType(for: line)))
            index += 1
        }

        return lines
    }

    private static func lineType(for line: String) -> LineType {
        if line.hasPrefix("+++")
            || line.hasPrefix("---")
            || line.hasPrefix("diff ")
            || line.hasPrefix("index ")
            || line.hasPrefix("@@")
            || line.hasPrefix("\\") {
            return .header
        }
        if line.hasPrefix("+") { return .addition }
        if line.hasPrefix("-") { return .deletion }
        return .context
    }
}
