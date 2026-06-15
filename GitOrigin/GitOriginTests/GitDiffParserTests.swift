//
//  GitDiffParserTests.swift
//  GitOriginTests
//
//  Unit tests for GitDiffParser unified diff fixtures.
//

import XCTest
@testable import GitOrigin

final class GitDiffParserTests: XCTestCase {
    private let sampleDiff = """
    diff --git a/Sources/App.swift b/Sources/App.swift
    index 1234567..abcdefg 100644
    --- a/Sources/App.swift
    +++ b/Sources/App.swift
    @@ -1,3 +1,4 @@
     import SwiftUI
    +import Observation

     struct AppView: View {
         var body: some View {
    """

    func testParsesUnifiedDiffFixture() {
        let lines = GitDiffParser.parse(sampleDiff)

        XCTAssertFalse(lines.isEmpty)
        XCTAssertTrue(lines.contains { $0.type == .header && $0.text.hasPrefix("@@") })
        XCTAssertTrue(lines.contains { $0.type == .addition && $0.text.contains("Observation") })
        XCTAssertTrue(lines.contains { $0.type == .context })
    }

    func testAdditionDeletionAndHeaderLines() {
        let output = """
        --- a/file.swift
        +++ b/file.swift
        @@ -1 +1,2 @@
         context
        -removed
        +added
        """

        let lines = GitDiffParser.parse(output)
        XCTAssertEqual(lines.filter { $0.type == .header }.count, 3)
        XCTAssertEqual(lines.filter { $0.type == .addition }.count, 1)
        XCTAssertEqual(lines.filter { $0.type == .deletion }.count, 1)
        XCTAssertGreaterThanOrEqual(lines.filter { $0.type == .context }.count, 1)
    }

    func testEmptyOutput() {
        XCTAssertTrue(GitDiffParser.parse("").isEmpty)
    }

    func testLineIDsAreSequential() {
        let lines = GitDiffParser.parse("+one\n+two")
        XCTAssertEqual(lines.map(\.id), [0, 1])
    }
}
