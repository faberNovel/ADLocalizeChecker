//
//  LocalizeCheckerCoreTests.swift
//  Commander
//
//  Created by Pierre Felgines on 15/06/2018.
//

import Foundation
import XCTest
@testable import LocalizeCheckerCore

class LocalizeCheckerCoreTests: XCTestCase {

    private let valid = [
        "regular_key_2",
        "regular_key_3",
        "regular_key_4",
        "formatted_key_redundant_call",
        "ad_utils_attributed_string_two_args_format",
        "ad_utils_attributed_string_three_args_format",
        "ad_utils_attributed_string_four_args_format",
        "ad_utils_attributed_string_single_arg_format",
    ]
    private let bypassed = ["key_to_bypass_2"]
    private let unusedBypassed = ["unusued_key_2"]
    private let badFormat = [
        "bad_format_key",
        "bad_format_key_2",
        "bad_format_key_3"
    ]
    private let badArgumentsFormat = [
        "bad_arguments_format",
        "bad_arguments_format_2"
    ]
    private let badArguments = [
        "bad_arguments_count_key",
        "bad_arguments_count_key_2",
        "ad_utils_attributed_string_format_bad_arguments_count"
    ]
    private let badUsage = ["bad_formatted_key_usage"]
    private let missing = ["missing_key"]
    private let redundant = ["redundant_key"]
    private let unstranlated = ["unstranlated_key"]
    private let unused = ["unusued_key", "unusued_key_2"]
    private let badPattern = ["bad_pattern_key", "bad_pattern_key_2"]
    private let forbiddenPattern = ["forbidden_pattern"]
    private let genericErrorBypassed = #""\(key)".localized()"#
    private let genericError = #""\(key_generic_error)".localized()"#

    private var wantedErrorCount = 0

    // MARK: - TESTS

    func testExamplePlist() {
        let path = "Example/Resources/ADLocalizeChecker/LocalizeChecker.plist"
        let url = URL(fileURLWithPath: path)
        do {
            let plistData = try Data(contentsOf: url)
            let plistDecoder = PropertyListDecoder()
            let configuration = try plistDecoder.decode(Configuration.self, from: plistData)
            XCTAssertTrue(configuration.treatScriptAsError)
            XCTAssertTrue(configuration.logsEnabled)
            XCTAssertTrue(configuration.defaultLanguageFallback == "fr")
            XCTAssertTrue(configuration.unusedPatterns == ["bypass-custom-unused-error"])
            XCTAssertTrue(configuration.customPatterns == [#"localisationCustomPattern\(@?"(\w+)""#])
            XCTAssertTrue(configuration.keysToBypass == ["key_to_bypass", "key_to_bypass_2"])
        } catch {
            print(error)
            XCTAssert(false, error.localizedDescription)
        }
    }

    func testExamplePlistVsTestPlistDiff() {
        let examplePath = "Example/Resources/ADLocalizeChecker/LocalizeChecker.plist"
        let testPath = "Example/Resources/ADLocalizeChecker/TestLocalizeChecker.plist"
        let exampleUrl = URL(fileURLWithPath: examplePath)
        let testUrl = URL(fileURLWithPath: testPath)
        do {
            let plistDecoder = PropertyListDecoder()
            let examplePlistData = try Data(contentsOf: exampleUrl)
            let exampleConfiguration = try plistDecoder.decode(Configuration.self, from: examplePlistData)
            let testPlistData = try Data(contentsOf: testUrl)
            let testConfiguration = try plistDecoder.decode(Configuration.self, from: testPlistData)
            XCTAssertTrue(exampleConfiguration.logsEnabled != testConfiguration.logsEnabled)
            XCTAssertTrue(exampleConfiguration.treatScriptAsError == testConfiguration.treatScriptAsError)
            XCTAssertTrue(exampleConfiguration.keysToBypass == testConfiguration.keysToBypass)
            XCTAssertTrue(exampleConfiguration.defaultLanguageFallback == testConfiguration.defaultLanguageFallback)
            XCTAssertTrue(testConfiguration.defaultLocalizableFolder == "Example/\( exampleConfiguration.defaultLocalizableFolder)")
            XCTAssertTrue(testConfiguration.relativeToTargetLocalizableFolder == "Example/\(exampleConfiguration.relativeToTargetLocalizableFolder)")
            XCTAssertTrue(exampleConfiguration.relativeSourceFolders != testConfiguration.relativeSourceFolders)
            XCTAssertTrue(exampleConfiguration.podsVSRelativeLocalizableFolder == testConfiguration.podsVSRelativeLocalizableFolder)
            XCTAssertTrue(exampleConfiguration.customPatterns == testConfiguration.customPatterns)
            XCTAssertTrue(exampleConfiguration.unusedPatterns == testConfiguration.unusedPatterns)
        } catch {
            print(error)
            XCTAssert(false, error.localizedDescription)
        }
    }

    func testKeys() {
        wantedErrorCount = 0
        let path = "Example/Resources/ADLocalizeChecker/TestLocalizeChecker.plist"
        do {
            try LocalizeChecker(
                targetName: "LocalizeChecker",
                plistPath: path,
                testDelegate: self
            ).run()
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("\(wantedErrorCount)"))
        }
    }
}

extension LocalizeCheckerCoreTests: LocalizeCheckerTestDelegate {

    // MARK: - LocalizeCheckerTestDelegate

    func localizeCheckerDidFind(_ error: LocatedError) {
        guard let consoleError = error.error as? ConsoleError else { return }
        let unwantedKeysInError = [valid, bypassed, unusedBypassed].flatten()
        var wantedError = false
        switch consoleError {
        case let .unusedKeyInMainLanguage(key: key):
            wantedError = check(key, in: [unused, badPattern].flatten(), notIn: unwantedKeysInError)
        case let .missingKeyInMainLanguage(key: key):
            wantedError = check(key, in: missing, notIn: unwantedKeysInError)
        case .unusedKey, .missingKey:
            break
        case let .errorPattern(value: value):
            wantedError = forbiddenPattern.first { value.contains($0) } != nil
        case let .genericKey(value: value):
            wantedError = value.contains(genericError) && !value.contains(genericErrorBypassed)
        case let .badPattern(value: value):
            wantedError = badPattern.first { value.contains($0) } != nil
        case let .redundantKey(key: key):
            wantedError = check(key, in: redundant, notIn: unwantedKeysInError)
        case let .badFormatMisplaced$Key(key: key, value: _, formattableCharacter: _):
            wantedError = check(key, in: badFormat, notIn: unwantedKeysInError)
        case let .untranslatedKey(key):
            wantedError = check(key, in: unstranlated, notIn: unwantedKeysInError)
        case let .badArguments(key, properCount: _, currentCount: _):
            wantedError = check(key, in: [badArguments, badFormat, badUsage].flatten(), notIn: unwantedKeysInError)
        case let .badUsageOfFormattedKey(key: key, properCount: _):
            wantedError = check(key, in: badUsage, notIn: unwantedKeysInError)
        case let .badArgumentsFormat(key: key):
            wantedError = check(key, in: badArgumentsFormat, notIn: unwantedKeysInError)
        }
        if wantedError {
            wantedErrorCount += 1
        } else {
            print(consoleError.errorDescription ?? "")
        }
    }

    private func check(_ key: String, in array: [String], notIn unwanted: [String]) -> Bool {
        array.contains(key) && !unwanted.contains(key)
    }
}

private extension Array where Element: Collection {

    func flatten() -> [Element.Element] {
        return reduce(into: []) { $0.append(contentsOf: $1) }
    }
}
