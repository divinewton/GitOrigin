//
//  GitLogParserTests.swift
//  GitOriginTests
//
//  Unit tests for GitLogParser oneline output.
//

import XCTest
@testable import GitOrigin

final class GitLogParserTests: XCTestCase {
    func testParsesOnelineLog() {
        let output = """
        abc1234 Initial commit
        def5678 Add README

        """
        let commits = GitLogParser.parse(output)
        XCTAssertEqual(commits.count, 2)
        XCTAssertEqual(commits[0].hash, "abc1234")
        XCTAssertEqual(commits[0].subject, "Initial commit")
        XCTAssertEqual(commits[1].subject, "Add README")
    }

    func testEmptyOutput() {
        XCTAssertTrue(GitLogParser.parse("").isEmpty)
    }
}
