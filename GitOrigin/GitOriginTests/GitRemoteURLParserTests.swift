//
//  GitRemoteURLParserTests.swift
//  GitOriginTests
//
//  Unit tests for GitHub remote URL parsing and PR URLs.
//

import XCTest
@testable import GitOrigin

final class GitRemoteURLParserTests: XCTestCase {
    func testParseHTTPSRemote() {
        let parsed = GitRemoteURLParser.parseGitHubRepository(from: "https://github.com/octocat/Hello-World.git")
        XCTAssertEqual(parsed?.owner, "octocat")
        XCTAssertEqual(parsed?.name, "Hello-World")
    }

    func testParseSSHRemote() {
        let parsed = GitRemoteURLParser.parseGitHubRepository(from: "git@github.com:octocat/Hello-World.git")
        XCTAssertEqual(parsed?.owner, "octocat")
        XCTAssertEqual(parsed?.name, "Hello-World")
    }

    func testCreatePullRequestURL() {
        let repo = GitHubRepository(owner: "octocat", name: "Hello-World", defaultBranch: "main")
        let url = GitRemoteURLParser.createPullRequestURL(repository: repo, headBranch: "feature")
        XCTAssertEqual(
            url.absoluteString,
            "https://github.com/octocat/Hello-World/compare/main...feature?expand=1"
        )
    }
}
