//
//  DiffView.swift
//  GitOrigin
//
//  Renders parsed unified diff lines with addition/deletion/context styling.
//

import SwiftUI

struct DiffView: View {
    let lines: [DiffLine]
    let isLoading: Bool

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading diff…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if lines.isEmpty {
                ContentUnavailableView(
                    "No Diff",
                    systemImage: "doc.text",
                    description: Text("This file has no diff output to display.")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(lines) { line in
                            DiffLineRow(line: line)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .font(.system(.body, design: .monospaced))
        .textSelection(.enabled)
    }
}

private struct DiffLineRow: View {
    let line: DiffLine

    var body: some View {
        HStack(spacing: 0) {
            Text(gutterSymbol)
                .frame(width: 20, alignment: .center)
                .foregroundStyle(gutterColor)
                .accessibilityHidden(line.type == .header)

            Text(displayText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 1)
        .background(backgroundColor)
    }

    private var gutterSymbol: String {
        switch line.type {
        case .addition: "+"
        case .deletion: "-"
        case .context: " "
        case .header: ""
        }
    }

    private var displayText: String {
        switch line.type {
        case .header:
            return line.text
        case .addition, .deletion, .context:
            if line.text.isEmpty { return "" }
            if line.text.hasPrefix("+") || line.text.hasPrefix("-") || line.text.hasPrefix(" ") {
                return String(line.text.dropFirst())
            }
            return line.text
        }
    }

    private var backgroundColor: Color {
        switch line.type {
        case .addition:
            Color(nsColor: .systemGreen).opacity(0.18)
        case .deletion:
            Color(nsColor: .systemRed).opacity(0.18)
        case .header:
            Color(nsColor: .separatorColor).opacity(0.25)
        case .context:
            Color.clear
        }
    }

    private var gutterColor: Color {
        switch line.type {
        case .addition: Color(nsColor: .systemGreen)
        case .deletion: Color(nsColor: .systemRed)
        case .context, .header: Color.secondary
        }
    }
}

#Preview {
    DiffView(
        lines: RepositoryStore.previewWithChanges.currentDiff,
        isLoading: false
    )
    .frame(width: 640, height: 320)
}
