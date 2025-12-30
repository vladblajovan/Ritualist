//
//  AppBrandHeaderViewLogicTests.swift
//  RitualistTests
//
//  Unit tests for AppBrandHeaderViewLogic
//

import XCTest
@testable import Ritualist

final class AppBrandHeaderViewLogicTests: XCTestCase {

    // MARK: - avatarContentType Tests

    func test_avatarContentType_withImage_returnsImage() {
        let result = AppBrandHeaderViewLogic.avatarContentType(hasAvatarImage: true, name: "")
        XCTAssertEqual(result, .image, "Should show image when avatar image is available")
    }

    func test_avatarContentType_withImageAndName_returnsImage() {
        let result = AppBrandHeaderViewLogic.avatarContentType(hasAvatarImage: true, name: "John Doe")
        XCTAssertEqual(result, .image, "Image takes precedence over name")
    }

    func test_avatarContentType_withNameOnly_returnsInitials() {
        let result = AppBrandHeaderViewLogic.avatarContentType(hasAvatarImage: false, name: "John")
        XCTAssertEqual(result, .initials, "Should show initials when name is available")
    }

    func test_avatarContentType_withFullName_returnsInitials() {
        let result = AppBrandHeaderViewLogic.avatarContentType(hasAvatarImage: false, name: "John Doe")
        XCTAssertEqual(result, .initials, "Should show initials when full name is available")
    }

    func test_avatarContentType_withEmptyName_returnsEmpty() {
        let result = AppBrandHeaderViewLogic.avatarContentType(hasAvatarImage: false, name: "")
        XCTAssertEqual(result, .empty, "Should show empty when no image and empty name")
    }

    func test_avatarContentType_withWhitespaceOnlyName_returnsEmpty() {
        let result = AppBrandHeaderViewLogic.avatarContentType(hasAvatarImage: false, name: "   ")
        XCTAssertEqual(result, .empty, "Should show empty when name is only whitespace")
    }

    func test_avatarContentType_withNewlinesOnlyName_returnsEmpty() {
        let result = AppBrandHeaderViewLogic.avatarContentType(hasAvatarImage: false, name: "\n\t\n")
        XCTAssertEqual(result, .empty, "Should show empty when name is only whitespace characters")
    }

    // MARK: - avatarInitials Tests

    func test_avatarInitials_withTwoWords_returnsTwoInitials() {
        let result = AppBrandHeaderViewLogic.avatarInitials(from: "John Doe")
        XCTAssertEqual(result, "JD")
    }

    func test_avatarInitials_withThreeWords_returnsFirstTwoInitials() {
        let result = AppBrandHeaderViewLogic.avatarInitials(from: "John Michael Doe")
        XCTAssertEqual(result, "JM")
    }

    func test_avatarInitials_withSingleWord_returnsTwoCharacters() {
        let result = AppBrandHeaderViewLogic.avatarInitials(from: "John")
        XCTAssertEqual(result, "JO")
    }

    func test_avatarInitials_withSingleCharacter_returnsOneCharacter() {
        let result = AppBrandHeaderViewLogic.avatarInitials(from: "J")
        XCTAssertEqual(result, "J")
    }

    func test_avatarInitials_withEmptyString_returnsEmpty() {
        let result = AppBrandHeaderViewLogic.avatarInitials(from: "")
        XCTAssertEqual(result, "")
    }

    func test_avatarInitials_withWhitespaceOnly_returnsEmpty() {
        let result = AppBrandHeaderViewLogic.avatarInitials(from: "   ")
        XCTAssertEqual(result, "")
    }

    func test_avatarInitials_withLowercaseName_returnsUppercase() {
        let result = AppBrandHeaderViewLogic.avatarInitials(from: "john doe")
        XCTAssertEqual(result, "JD")
    }

    func test_avatarInitials_withExtraWhitespace_handlesCorrectly() {
        let result = AppBrandHeaderViewLogic.avatarInitials(from: "  John   Doe  ")
        XCTAssertEqual(result, "JD")
    }

    func test_avatarInitials_withMixedCase_returnsUppercase() {
        let result = AppBrandHeaderViewLogic.avatarInitials(from: "jOhN dOe")
        XCTAssertEqual(result, "JD")
    }
}
