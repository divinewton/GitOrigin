//
//  GitLocatorTests.swift
//  GitOriginTests
//
//  Integration test that locates a system Git binary (skipped if none).
//

import XCTest
@testable import GitOrigin

final class GitLocatorTests: XCTestCase {
    func testLocateGitExecutableFindsKnownPath() throws {
        guard let url = GitLocator.locateGitExecutable() else {
            throw XCTSkip("No git binary found on this machine.")
        }

        XCTAssertTrue(url.path.hasSuffix("/git"))
        XCTAssertNotEqual(url.path, "/usr/bin/git")
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: url.path))
    }
}
