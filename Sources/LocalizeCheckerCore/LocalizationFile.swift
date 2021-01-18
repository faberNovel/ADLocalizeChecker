//
//  LocalizationFile.swift
//  LocalizeChecker
//
//  Created by Claire Peyron on 12/06/2018.
//

import Foundation

typealias Keys = Set<String>
typealias KeysVSLines = [String: Int]

class LocalizationFile {
    var keys: Keys {
        return Set(keysVSLines.keys)
    }
    private(set) var keysVSLines: KeysVSLines = [:]
    private(set) var formattedKeys: FormattedKeys = []
    private(set) var stringsFilePath = ""
    private var stringsDictFilePath = ""
    private let relativeLocalizableFolder: String
    private let name: String
    //TODO: (Claire Peyron) 2018/06/12 Called Format Specifiers in iOS docs
    // (https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html)
    private let formattableCharacters = ["@", "(\\d*)d", "(\\d*)f"]
    private let configuration: Configuration
    private let logger: Logger

    init(name: String,
         relativeLocalizableFolder: String,
         configuration: Configuration,
         logger: Logger) {
        self.name = name
        self.relativeLocalizableFolder = relativeLocalizableFolder
        self.configuration = configuration
        self.logger = logger
        setup()
    }

    // MARK: - Private

    private func setup() {
        parseStringsFile()
        parseStringsDictFile()
    }

    private func parseStringsFile() {
        stringsFilePath = name.stringsFilePath(for: relativeLocalizableFolder, baseURL: configuration.pathURL)
        guard
            let fileContent = try? String(contentsOfFile: stringsFilePath, encoding: .utf8),
            let regex = try? NSRegularExpression(pattern: configuration.localizablePattern, options: []) else {
                return
        }
        let lines = fileContent.components(separatedBy: CharacterSet.newlines)
        var dictionary: [Int: String] = [:]
        var currentLineNumber = 0
        for (lineNumber, line) in lines.enumerated() {
            guard line.count != 0 else { continue }
            if line.contains("\" = \"") {
                currentLineNumber = lineNumber
                dictionary[currentLineNumber] = line
            } else if let main = dictionary[currentLineNumber] {
                dictionary[currentLineNumber] = main + line
            }
        }
        dictionary.forEach { (lineNumber, line) in
            handle(line: line, currentLineNumber: lineNumber + 1, regex: regex)
        }
    }

    private func handle(line: String, currentLineNumber: Int, regex: NSRegularExpression) {
        let range = NSRange(location: 0, length: line.count)
        guard
            !shouldBypass(line),
            let match = regex.firstMatch(in: line, options: [], range: range) else {
                return
        }
        let key = (line as NSString).substring(with: match.range(at: 1))
        guard keysVSLines.index(forKey: key) == nil else {
            let error = LocatedError(
                filePath: stringsFilePath,
                line: currentLineNumber,
                error: ConsoleError.redundantKey(key: key)
            )
            logger.log(error)
            return
        }
        let value = (line as NSString).substring(with: match.range(at: 2))
        handleFormatErrors(for: value, currentLineNumber: currentLineNumber, key: key)
        handleArgumentsCount(for: value, currentLineNumber: currentLineNumber, key: key)
        handleUnstranslatedErrors(for: value, line: line, currentLineNumber: currentLineNumber, key: key)
        keysVSLines[key] = currentLineNumber
    }

    private func shouldBypass(_ line: String) -> Bool {
        return configuration.localizableBypassUnusedPatterns.contains { line.contains($0) }
    }

    private func parseStringsDictFile() {
        stringsDictFilePath = name.stringsDictFilePath(for: relativeLocalizableFolder, baseURL: configuration.pathURL)
        guard let dictionary = NSDictionary(contentsOfFile: stringsDictFilePath) as? [String: Any] else { return }
        for (key, _) in dictionary {
            if keysVSLines.index(forKey: key) != nil {
                let error = LocatedError(
                    filePath: stringsDictFilePath,
                    line: 1,
                    error: ConsoleError.redundantKey(key: key)
                )
                logger.log(error)
            } else {
                keysVSLines[key] = 1
            }
        }
    }

    // MARK - Private - Errors treatment

    private func handleFormatErrors(for value: String, currentLineNumber: Int, key: String) {
        formattableCharacters.forEach { formattableCharacter in
            let formattableCharactersPattern = "%(\\$(\\d+))*\(formattableCharacter)"
            formattableCharactersPattern.findPattern(in: value) { result in
                guard let result = result else { return }
                let error = LocatedError(
                    filePath: stringsFilePath,
                    line: currentLineNumber,
                    error: ConsoleError.badFormatMisplaced$Key(
                        key: key,
                        value: (value as NSString).substring(with: result.range(at: 0)),
                        formattableCharacter: formattableCharacter
                    )
                )
                logger.log(error)
            }
        }
    }

    private func handleArgumentsCount(for value: String, currentLineNumber: Int, key: String) {
        var argumentsCount = 0
        formattableCharacters.forEach { formattableCharacter in
            let formattableCharactersPattern = "%(\\d+)\\$\(formattableCharacter)"
            formattableCharactersPattern.findPattern(in: value) { result in
                guard result != nil else { return }
                argumentsCount += 1
            }
        }
        guard let formattedKey = FormattedKey(key: key, argumentsCount: argumentsCount) else { return }
        guard (1...argumentsCount).allSatisfy({ value.contains("%\($0)$") }) else {
            let error = LocatedError(
                filePath: stringsFilePath,
                line: currentLineNumber,
                error: ConsoleError.badArgumentsFormat(key: formattedKey.key)
            )
            logger.log(error)
            return
        }
        formattedKeys.insert(formattedKey)
    }

    private func handleUnstranslatedErrors(for value: String, line: String, currentLineNumber: Int, key: String) {
        guard !line.contains(configuration.localizableBypassUntranslatedPattern) else { return }
        if (value == "" || value == key) {
            let error = LocatedError(
                filePath: stringsFilePath,
                line: currentLineNumber,
                error: ConsoleError.untranslatedKey(key: key)
            )
            logger.log(error)
        }
    }
}
