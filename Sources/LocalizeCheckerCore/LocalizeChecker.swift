//
//  LocalizeChecker.swift
//  LocalizeChecker
//
//  Created by Claire Peyron on 15/05/2018.
//

//TODO: (Claire Peyron) 2018/05/25 handle infoPlist.strings
import Foundation

protocol LocalizeCheckerTestDelegate: AnyObject {
    func localizeCheckerDidFind(_ error: LocatedError)
}

public final class LocalizeChecker {

    private let configuration: Configuration
    private lazy var fileManager = FileManager.default
    private var logger: Logger

    public convenience init(targetName: String, plistPath: String) throws {
        try self.init(targetName: targetName, plistPath: plistPath, testDelegate: nil)
    }

    internal init(targetName: String, plistPath: String, testDelegate: LocalizeCheckerTestDelegate?) throws {
        let plistURL = URL(fileURLWithPath: plistPath)
        let plistData = try Data(contentsOf: plistURL)
        let plistDecoder = PropertyListDecoder()
        self.configuration = try plistDecoder.decode(Configuration.self, from: plistData)
        self.logger = Logger(configuration: configuration, testDelegate: testDelegate)
        try configuration.setup(with: targetName)
    }

    public func run() throws {
        try execute()
    }

    // MARK: - Private

    private func execute() throws {
        for (localizablePath, sourceFolders) in configuration.localizableVSSourcesFolders {
            let masterLocalizationfile = LocalizationFile(
                name: configuration.defaultLanguage,
                relativeLocalizableFolder: localizablePath,
                configuration: configuration,
                logger: logger
            )
            let ignoredKeys = Set(configuration.keysToBypass)
            let masterKeys = Set(masterLocalizationfile.keys).subtracting(ignoredKeys)
            var formattedKeys = masterLocalizationfile.formattedKeys
            let usedKeys = retrieveUsedKeys(
                for: sourceFolders,
                formattedKeys: &formattedKeys,
                ignoredKeys: ignoredKeys
            ).subtracting(ignoredKeys)
            let unusedKeys = masterKeys.subtracting(usedKeys)
            let missingKeys = usedKeys.subtracting(masterKeys)
            let currentLocalizablePath = localizablePath.absolutePath(baseURL: configuration.pathURL)
            let supportedLanguages = supportedLanguagesArray(for: currentLocalizablePath)
            handleErrors(
                masterLocalizationfile: masterLocalizationfile,
                formattedKeys: formattedKeys,
                unusedKeys: unusedKeys,
                missingKeys: missingKeys,
                supportedLanguages: supportedLanguages,
                localizablePath: localizablePath,
                usedKeys: usedKeys,
                masterKeysVSLines: masterLocalizationfile.keysVSLines,
                ignoredKeys: ignoredKeys
            )

            if configuration.logsEnabled {
                logger.log("[Localize] Current localizablePath \(currentLocalizablePath)")
                logger.log("[Localize] masterKeys \(masterKeys)")
                logger.log("[Localize] usedKeys \(usedKeys)")
                logger.log("[Localize] ignoredKeys \(ignoredKeys)")
                logger.log("[Localize] unusedKeys \(unusedKeys)")
                logger.log("[Localize] formattedKeys \(formattedKeys)")
                logger.log("[Localize] missingKeys \(missingKeys)")
                logger.log("[Localize] Supported languages \(supportedLanguages)")
                logger.log("[Localize] Default language \(configuration.defaultLanguage)")
                logger.log("--------------------------------------------------------------------------")
            }
        }

        if logger.numberOfErrors > 0 && configuration.treatScriptAsError {
            throw ScriptError.issueOnExecution(numberOfErrors: logger.numberOfErrors)
        }
    }

    private func retrieveUsedKeys(for sourceFolders: [String],
                                  formattedKeys: inout FormattedKeys,
                                  ignoredKeys: Keys) -> Keys {
        var localizedStrings: [String] = []
        sourceFolders.forEach {
            appendLocalizedStrings(
                &localizedStrings,
                sourceFolder: $0,
                formattedKeys: &formattedKeys,
                ignoredKeys: ignoredKeys
            )
        }
        return Set(localizedStrings)
    }

    private func appendLocalizedStrings(_ localizedStrings: inout [String],
                                        sourceFolder: String,
                                        formattedKeys: inout FormattedKeys,
                                        ignoredKeys: Keys) {
        let sourcesURL = sourceFolder.absoluteURL(baseURL: configuration.pathURL)
        let enumerator = fileManager.enumerator(atPath: sourcesURL.absoluteString)
        while let relativeFilePath = enumerator?.nextObject() as? String {
            guard
                let url = URL(string: relativeFilePath),
                (url.pathExtension == "swift" || url.pathExtension == "m"),
                !url.pathComponents.contains("Pods") else {
                    continue
            }
            let filePath = sourcesURL.appendingPathComponent(relativeFilePath).absoluteString
            guard let fileContent = try? String(contentsOfFile: filePath, encoding: .utf8) else { continue }
            configuration.patterns.findPatterns(in: fileContent) { (_, result) in
                guard let result = result else { return }
                let key = (fileContent as NSString).substring(with: result.range(at: 1))
                guard !ignoredKeys.contains(key) else { return }
                localizedStrings.append(key)
                guard let formattedKey = formattedKeys.first(where: { $0.key == key }) else { return }
                let lastLineNumber = formattedKey.lastOccurenceLineNumber(in: filePath)
                let lineNumber = fileContent.lineNumberForKey(key, upperThan: lastLineNumber)
                let newKey = formattedKey.addFile(filePath, lineNumber: lineNumber)
                formattedKeys.remove(formattedKey)
                formattedKeys.insert(newKey)
            }
            handleErrors(
                content: fileContent,
                filePath: filePath,
                formattedKeys: &formattedKeys,
                ignoredKeys: ignoredKeys
            )
        }
    }

    private func handleErrors(content: String,
                              filePath: String,
                              formattedKeys: inout FormattedKeys,
                              ignoredKeys: Keys) {
        handleErrorPatterns(content: content, filePath: filePath, ignoredKeys: ignoredKeys)
        handleBadFormatPatterns(content: content, filePath: filePath)
        handleGenericPatterns(content: content, filePath: filePath)
        handleFormattedStringPatterns(
            content: content,
            filePath: filePath,
            formattedKeys: &formattedKeys,
            ignoredKeys: ignoredKeys
        )
    }

    private func handleErrorPatterns(content: String, filePath: String, ignoredKeys: Keys) {
        configuration.errorPatterns.findPatterns(in: content) { (_, result) in
            guard let result = result else { return }
            let key = (content as NSString).substring(with: result.range(at: 1))
            guard !ignoredKeys.contains(key) else { return }
            let error = LocatedError(
                filePath: filePath,
                line: content.lineNumberForKey(key),
                error: ConsoleError.errorPattern(value: key)
            )
            logger.log(error)
        }
    }

    private func handleBadFormatPatterns(content: String, filePath: String) {
        configuration.badFormatPatterns.findPatterns(in: content) { (_, result) in
            guard let result = result else { return }
            let value = (content as NSString).substring(with: result.range(at: 0))
            let error = LocatedError(
                filePath: filePath,
                line: content.lineNumber(for: value),
                error: ConsoleError.badPattern(value: value)
            )
            logger.log(error)
        }
    }

    private func handleGenericPatterns(content: String, filePath: String) {
        configuration.genericPatterns.findPatterns(in: content) { (_, result) in
            guard let result = result else { return }
            let value = (content as NSString).substring(with: result.range(at: 0))
            let lineNumber = content.lineNumber(for: value)
            let line = content.line(at: lineNumber)
            guard !line.contains(configuration.localizableBypassGenericPattern) else { return }
            let error = LocatedError(
                filePath: filePath,
                line: lineNumber,
                error: ConsoleError.genericKey(value: value)
            )
            logger.log(error)
        }
    }

    private func handleFormattedStringPatterns(content: String,
                                               filePath: String,
                                               formattedKeys: inout FormattedKeys,
                                               ignoredKeys: Keys) {
        configuration.formattedStringPatterns.findPatterns(in: content) { (pattern, result) in
            guard let result = result else { return }
            let key = (content as NSString).substring(with: result.range(at: 1))
            guard let formattedKey = formattedKeys.first(where: { $0.key == key }) else { return }
            guard !ignoredKeys.contains(key) else { return }
            let string = (content as NSString).substring(with: result.range(at: 0))
            let lineSeen: [Int] = formattedKey.lineSeen(in: filePath)
            let lineNumber = content.lineNumberForKey(key, contentOf: string, lineSeen: lineSeen)
            let newKey = formattedKey.markAsUsed(in: filePath, lineNumber: lineNumber)
            formattedKeys.remove(formattedKey)
            formattedKeys.insert(newKey)
            var count = configuration.formattedStringArgumentsFormat.patternCount(in: string)
            if configuration.formattedStringPatternsWithExtraFirstArgument.contains(pattern) {
                count += 1
            }
            let properCount = formattedKey.argumentsCount
            guard count != properCount else { return }
            let error = LocatedError(
                filePath: filePath,
                line: lineNumber,
                error: ConsoleError.badArguments(key: key, properCount: properCount, currentCount: count)
            )
            logger.log(error)
        }
    }

    private func supportedLanguagesArray(for currentLocalizablePath: String) -> [String] {
        var languages: [String] = []
        let enumerator = fileManager.enumerator(atPath: currentLocalizablePath)
        while let element = enumerator?.nextObject() as? String {
            guard
                let url = URL(string: element),
                url.pathExtension == "lproj" else {
                    continue
            }
            let name = url.deletingPathExtension().absoluteString
            languages.append(name)
        }
        return languages
    }

    // MARK - Private - Errors treatment

    private func handleErrorsForMainLanguage(masterLocalizationfile: LocalizationFile,
                                             unusedKeys: Keys,
                                             missingKeys: Keys,
                                             masterKeysVSLines: KeysVSLines) {
        missingKeys.forEach { missingKey in
            //TODO: (Claire Peyron) 2018/06/12 Would be nice to get the error in the source file
            let error = LocatedError(
                filePath: masterLocalizationfile.stringsFilePath,
                line: 1,
                error: ConsoleError.missingKeyInMainLanguage(key: missingKey)
            )
            logger.log(error)
        }
        unusedKeys.forEach { unusedKey in
            let line = masterKeysVSLines[unusedKey] ?? 1
            let error = LocatedError(
                filePath: masterLocalizationfile.stringsFilePath,
                line: line,
                error: ConsoleError.unusedKeyInMainLanguage(key: unusedKey)
            )
            logger.log(error)
        }
    }

    private func handleErrors(for supportedLanguages: [String],
                              localizablePath: String,
                              usedKeys: Set<String>,
                              masterKeysVSLines: [String: Int],
                              ignoredKeys: Keys) {
        let localizationFiles = supportedLanguages
            .filter { $0 != configuration.defaultLanguage }
            .map {
                LocalizationFile(
                    name: $0,
                    relativeLocalizableFolder: localizablePath,
                    configuration: configuration,
                    logger: logger
                )
            }
        for file in localizationFiles {
            let reachableKeys = file.keys.subtracting(ignoredKeys)
            let missingKeys = usedKeys.subtracting(reachableKeys)
            missingKeys.forEach { missingKey in
                let line = masterKeysVSLines[missingKey] ?? 1
                let error = LocatedError(
                    filePath: file.stringsFilePath,
                    line: line,
                    error: ConsoleError.missingKey(key: missingKey)
                )
                logger.log(error)
            }
            let unusedKeys = reachableKeys.subtracting(usedKeys)
            unusedKeys.forEach { unusedKey in
                let line = masterKeysVSLines[unusedKey] ?? 1
                let error = LocatedError(
                    filePath: file.stringsFilePath,
                    line: line,
                    error: ConsoleError.unusedKey(key: unusedKey)
                )
                logger.log(error)
            }
        }
    }

    private func handleErrors(masterLocalizationfile: LocalizationFile,
                              formattedKeys: FormattedKeys,
                              unusedKeys: Keys,
                              missingKeys: Keys,
                              supportedLanguages: [String],
                              localizablePath: String,
                              usedKeys: Keys,
                              masterKeysVSLines: KeysVSLines,
                              ignoredKeys: Keys) {
        handleErrorsForMainLanguage(
            masterLocalizationfile: masterLocalizationfile,
            unusedKeys: unusedKeys,
            missingKeys: missingKeys,
            masterKeysVSLines: masterKeysVSLines
        )
        handleErrors(
            for: supportedLanguages,
            localizablePath: localizablePath,
            usedKeys: usedKeys,
            masterKeysVSLines: masterKeysVSLines,
            ignoredKeys: ignoredKeys
        )
        handleFormattedKeysUnusedErrors(formattedKeys, ignoredKeys: ignoredKeys)
    }

    private func handleFormattedKeysUnusedErrors(_ formattedKeys: FormattedKeys, ignoredKeys: Keys) {
        formattedKeys.forEach { key in
            guard !ignoredKeys.contains(key.key) else { return }
            key.occurences.forEach {
                guard !$0.checked else { return }
                let error = LocatedError(
                    filePath: $0.fileName,
                    line: $0.lineNumber,
                    error: ConsoleError.badUsageOfFormattedKey(key: key.key, properCount: key.argumentsCount)
                )
                logger.log(error)
            }
        }
    }
}
