//
//  String.swift
//  LocalizeChecker
//
//  Created by Claire Peyron on 12/06/2018.
//

import Foundation

extension String {
    func absoluteURL(baseURL: URL) -> URL {
        return baseURL.appendingPathComponent(self).standardized
    }

    func absolutePath(baseURL: URL) -> String {
        return absoluteURL(baseURL: baseURL).absoluteString
    }

    func findPattern(in fileContent: String, completion: (NSTextCheckingResult?) -> Void) {
        guard let regex = try? NSRegularExpression(pattern: self, options: []) else {
            completion(nil)
            return
        }
        let range = NSRange(location: 0, length: fileContent.count)
        regex.enumerateMatches(
            in: fileContent,
            options: [],
            range: range,
            using: { (result, _, _) in completion(result) }
        )
    }

    func patternCount(in fileContent: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: self, options: []) else { return 0 }
        let range = NSRange(location: 0, length: fileContent.count)
        return regex.numberOfMatches(
            in: fileContent,
            options: [],
            range: range
        )
    }

    func stringsFilePath(for relativeLocalizableFolder: String, baseURL: URL) -> String {
        return String.stringsFilePath(for: relativeLocalizableFolder, language: self, baseURL: baseURL)
    }

    func stringsDictFilePath(for relativeLocalizableFolder: String, baseURL: URL) -> String {
        let path = relativeLocalizableFolder
            .absoluteURL(baseURL: baseURL)
            .appendingPathComponent("\(self).lproj")
            .appendingPathComponent("Localizable.stringsdict")
            .absoluteString
        return path
    }

    static func stringsFilePath(for relativeLocalizableFolder: String, language: String, baseURL: URL) -> String {
        let path = relativeLocalizableFolder
            .absoluteURL(baseURL: baseURL)
            .appendingPathComponent("\(language).lproj")
            .appendingPathComponent("Localizable.strings")
            .absoluteString
        return path
    }

    func lineNumber(for element: String, upperThan: Int = 0) -> Int {
        let array = occurencesIndexes(of: "\(element)").filter { $0 > upperThan }
        return array.first ?? 1
    }

    func lineNumberForKey(_ key: String, upperThan: Int = 0) -> Int {
        return lineNumber(for: "\u{22}\(key)\u{22}", upperThan: upperThan)
    }

    func lineNumberForKey(_ key: String, contentOf string: String, lineSeen: [Int]) -> Int {
        let array = occurencesIndexes(of: "\(key)")
            .filter { string.findRange(in: self).contains($0) && !lineSeen.contains($0) }
        return array.first ?? 1
    }

    var firstNumber: Int? {
        let array = components(separatedBy: CharacterSet.decimalDigits.inverted)
        guard let value = array.first(where: { Int($0) != nil }) else { return nil }
        return Int(value)
    }

    func line(at index: Int) -> String {
        guard
            index > 0,
            lines.count > index else {
                return ""
        }
        return lines[index - 1]
    }

    // MARK: - Private

    private var lines: [String] {
        return components(separatedBy: "\n")
    }

    private func occurencesIndexes(of element: String) -> [Int] {
        let array = lines.indices
            .filter { lines[$0].contains("\(element)") }
            .map { $0 + 1 }
        return array
    }

    private func findRange(in file: String) -> [Int] {
        let indexes = lines.map { return file.occurencesIndexes(of: $0) }
        let increasingResult = indexes.filterAsFollowingSeries(.increasing)
        let decreasingResult = increasingResult.filterAsFollowingSeries(.decreasing)
        return Array(decreasingResult.flatten().reversed())
    }
}
