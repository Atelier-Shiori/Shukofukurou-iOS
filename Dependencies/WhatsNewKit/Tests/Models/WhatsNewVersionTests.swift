//
//  WhatsNewVersionTests.swift
//  WhatsNewKit-iOS Tests
//
//  Created by Sven Tiigi on 24.05.18.
//  Copyright © 2018 WhatsNewKit. All rights reserved.
//

import XCTest
@testable import WhatsNewKit

class WhatsNewVersionTests: BaseTests {
    
    func testStringLiteral() {
        let major = self.generateRandomInt()
        let minor = self.generateRandomInt()
        let patch = self.generateRandomInt()
        let versionString = "\(major).\(minor).\(patch)"
        let version = WhatsNew.Version(stringLiteral: versionString)
        XCTAssertEqual(major, version.major)
        XCTAssertEqual(minor, version.minor)
        XCTAssertEqual(patch, version.patch)
        XCTAssertEqual(versionString, version.description)
    }
    
    func testInvalidStringLiteral() {
        let version = WhatsNew.Version(stringLiteral: "")
        XCTAssertEqual(0, version.major)
        XCTAssertEqual(0, version.minor)
        XCTAssertEqual(0, version.patch)
    }
    
    func testCurrentInBundle() {
        class FakeBundle: Bundle {
            override var infoDictionary: [String : Any]? {
                return ["CFBundleShortVersionString": self.version]
            }
            var version: String = ""
        }
        let major = self.generateRandomInt()
        let minor = self.generateRandomInt()
        let patch = self.generateRandomInt()
        let versionString = "\(major).\(minor).\(patch)"
        let fakeBundle = FakeBundle()
        fakeBundle.version = versionString
        let version = WhatsNew.Version.current(inBundle: fakeBundle)
        XCTAssertEqual(major, version.major)
        XCTAssertEqual(minor, version.minor)
        XCTAssertEqual(patch, version.patch)
        XCTAssertEqual(versionString, version.description)
    }
    
    func testCurrentInBundleUnavailable() {
        class FakeBundle: Bundle {
            override var infoDictionary: [String : Any]? {
                return nil
            }
        }
        let fakeBundle = FakeBundle()
        let version = WhatsNew.Version.current(inBundle: fakeBundle)
        XCTAssertEqual(0, version.major)
        XCTAssertEqual(0, version.minor)
        XCTAssertEqual(0, version.patch)
        XCTAssertEqual("0.0.0", version.description)
    }
    
    func testComparable() {
        let version0 = WhatsNew.Version(major: 0, minor: 0, patch: 1)
        let version1 = WhatsNew.Version(major: 1, minor: 0, patch: 0)
        XCTAssert(version0 < version1)
        XCTAssert(version1 > version0)
    }
    
    func testLargeMinorVersionComparable() {
        let version0 = WhatsNew.Version(major: 3, minor: 17, patch: 7)
        let version1 = WhatsNew.Version(major: 4, minor: 7, patch: 7)
        XCTAssertTrue(version0 < version1)
        XCTAssertTrue(version1 > version0)
        XCTAssertFalse(version1 == version0)
    }
    
    func testEquality() {
        let version0 = WhatsNew.Version(major: 1, minor: 0, patch: 0)
        let version1 = WhatsNew.Version(major: 1, minor: 0, patch: 0)
        XCTAssertFalse(version0 < version1)
        XCTAssertFalse(version1 > version0)
        XCTAssertTrue(version1 == version0)
    }
    
}
