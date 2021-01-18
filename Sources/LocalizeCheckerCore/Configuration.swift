//
//  Configuration.swift
//  LocalizeCheckerCore
//
//  Created by Claire Peyron on 12/06/2018.
//

import Foundation

class Configuration: Codable {

    // MARK: - Configurable variables

    let logsEnabled: Bool
    let treatScriptAsError: Bool
    let keysToBypass: [String]

    let defaultLanguageFallback: String
    let defaultLocalizableFolder: String
    let relativeToTargetLocalizableFolder: String
    let relativeSourceFolders: [String]
    let podsVSRelativeLocalizableFolder: [String: String]
    let customPatterns: [String]
    let unusedPatterns: [String]

    enum CodingKeys: String, CodingKey {
        case logsEnabled = "LCLogsEnabled"
        case treatScriptAsError = "LCTreatScriptAsError"
        case keysToBypass = "LCKeysToBypass"
        case defaultLanguageFallback = "LCDefaultLanguageFallback"
        case defaultLocalizableFolder = "LCDefaultLocalizableFolder"
        case relativeToTargetLocalizableFolder = "LCRelativeToTargetLocalizableBaseFolder"
        case relativeSourceFolders = "LCRelativeSourceFolders"
        case podsVSRelativeLocalizableFolder = "LCPodsVSRelativeLocalizableFolder"
        case customPatterns = "LCCustomPatterns"
        case unusedPatterns = "LCUnusedPatterns"
    }

    // MARK: - Global variables

    private lazy var defaultPatterns = [
        "@?\"(\\w+)\"\\.adobjc_localized", // Objc ADUtils
        "\"(\\w+)\"\\.localized\\(\\)" // Swift ADUtils
    ]
    lazy var errorPatterns = [
        "NSLocalizedString\\(@?\"(\\w+)\"" // Swift and Objc Native
    ]
    //???: (Claire Peyron) 2018/04/16 Needed to check if we missing keys
    // example: (cond ? "key1" : "key2").localized() should be treated as error
    lazy var badFormatPatterns = [
        "(.*)[^\"]\\.adobjc_localized", // Objc ADUtils
        "(.*)[^\"]\\.localized\\(\\)" // Swift ADUtils
    ]
    //???: (Claire Peyron) 2018/04/16 Needed to check if we missing keys
    // example: "\(parameterAsKey)".localized() should be treated as error
    lazy var genericPatterns = [
        "(.*)\\)\"\\.adobjc_localized", // Objc ADUtils
        "(.*)\\)\"\\.localized\\(\\)" // Swift ADUtils
    ]
    private lazy var spacings = "\\n?\\t*\\s*"
    lazy var formattedStringArgumentsFormat = ",\(formattedStringArgumentFormat)"
    private lazy var formattedStringArgumentFormat = "[^,\\)\\]]+"
    private lazy var formattedStringPatternsFormat = [
        "String\\(\(spacings)format:\\s%1$@(\(formattedStringArgumentsFormat))+\(spacings)\\)",
        "\\[NSString stringWithFormat\\:%1$@(\(formattedStringArgumentsFormat))+\\]"
    ]
    lazy var formattedStringPatternsWithExtraFirstArgument = self.createFormattedStringPatternsWithExtraFirstArgument()
    private lazy var formattedStringPatternsFormatWithExtraFirstArgument = [
        "%1$@.attributedString\\(\(spacings)arguments:\\s\\[\(formattedStringArgumentFormat)[\(formattedStringArgumentsFormat)]*\\],"
    ]
    lazy var formattedStringPatterns: [String] = self.createFormattedStringPatterns()
    lazy var localizablePattern = "\"(\\w+)\" = \"((\\R|\\r|.)*)\";"
    lazy var localizableBypassGenericPattern = "bypass-generic-error"
    lazy var localizableBypassUntranslatedPattern = "bypass-untranslated-error"
    lazy var localizableBypassUnusedPattern = "bypass-unused-error"
    lazy var localizableBypassUnusedPatterns: [String] = self.createLocalizableBypassUnusedPatterns()
    lazy var patterns = self.createPatterns()
    private lazy var localizableFolder = self.createLocalizableFolder()

    //TODO: (Claire Peyron) 2018/06/13 remove force unwrap
    lazy var pathURL = URL(string: path)!
    private lazy var path = FileManager.default.currentDirectoryPath
    private var targetName = ""

    // MARK: - Configuration

    func setup(with targetName: String) throws {
        self.targetName = targetName
    }

    lazy var infoPlistRelativePath = "/Configuration/\(targetName)/\(self.targetName)-Info.plist"
    lazy var infoPlistDictionary = NSDictionary(contentsOfFile: infoPlistRelativePath.absolutePath(baseURL: pathURL)) as? [String: Any]
    lazy var defaultLanguage = infoPlistDictionary?["CFBundleDevelopmentRegion"] as? String ?? defaultLanguageFallback

    lazy var localizableVSSourcesFolders = self.createLocalizableVSSourcesFolders()

    // MARK: - Private

    private func createFormattedStringPatterns() -> [String] {
        let regular = createFormattedStringPatterns(for: formattedStringPatternsFormat)
        return regular + formattedStringPatternsWithExtraFirstArgument
    }

    private func createFormattedStringPatternsWithExtraFirstArgument() -> [String] {
        return createFormattedStringPatterns(for: formattedStringPatternsFormatWithExtraFirstArgument)
    }

    private func createFormattedStringPatterns(for formats: [String]) -> [String] {
        return patterns.product(with: formats) { String(format: $1, $0) }
    }

    private func createLocalizableBypassUnusedPatterns() -> [String] {
        var localizableBypassUnusedPatterns = unusedPatterns
        localizableBypassUnusedPatterns.append(localizableBypassUnusedPattern)
        return localizableBypassUnusedPatterns
    }

    private func createPatterns() -> [String] {
        return defaultPatterns + customPatterns
    }

    private func createLocalizableFolder() -> String {
        let relativeLocalizableFolder = "\(relativeToTargetLocalizableFolder)/\(targetName)"
        let relativeLocalizableFile = String.stringsFilePath(
            for: relativeLocalizableFolder,
            language: defaultLanguage,
            baseURL: pathURL
        )
        if FileManager.default.fileExists(atPath: relativeLocalizableFile) {
            return relativeLocalizableFolder
        } else {
            return defaultLocalizableFolder
        }
    }

    private func createLocalizableVSSourcesFolders() -> [String: [String]] {
        var localizableVSSourcesFolders = [
            localizableFolder: relativeSourceFolders
        ]
        let podsLocalizableVSSourcesFolders = retrievePodsLocalizableVSSourcesFolders()
        localizableVSSourcesFolders.merge(podsLocalizableVSSourcesFolders) { (current, _) in current }
        return localizableVSSourcesFolders
    }

    private func retrievePodsLocalizableVSSourcesFolders() -> [String: [String]] {
        var podsLocalizableVSSourcesFolders: [String: [String]] = [:]
        let pods = retrievePods()
        pods.forEach { podsLocalizableVSSourcesFolders["\($0.path)\($0.relativePath)"] = ["\($0.path)"] }
        return podsLocalizableVSSourcesFolders
    }

    private func retrievePods() -> [Pod] {
        let devPodPattern = "pod '([a-zA-Z0-9_]+)', :path => '(.*)'"
        var pods: [Pod] = podsVSRelativeLocalizableFolder.map { (name, relativePath) in
            return Pod(name: name, relativePath: relativePath, path: "/Pods/\(name)")
        }
        guard
            let podfile = (try? String(contentsOfFile: "\(path)/Podfile", encoding: .utf8)),
            let regex = try? NSRegularExpression(pattern: devPodPattern, options: []) else {
                return pods
        }
        let lines = podfile.components(separatedBy: CharacterSet.newlines)
        lines.forEach { line in
            let spaceFreeLine = line.trimmingCharacters(in: .whitespaces)
            guard spaceFreeLine.first != "#" else { return }
            let range = NSRange(location: 0, length: line.count)
            guard let match = regex.firstMatch(in: line, options: [], range: range) else { return }
            let podName = (line as NSString).substring(with: match.range(at: 1))
            let podPath = (line as NSString).substring(with: match.range(at: 2))
            guard let index = pods.index(where: { $0.name == podName }) else { return }
            var devPod = pods[index]
            devPod.path = "/\(podPath)"
            pods.remove(at: index)
            pods.append(devPod)
        }
        return pods
    }
}
