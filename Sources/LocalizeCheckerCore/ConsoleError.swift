//
//  ConsoleError.swift
//  LocalizeCheckerCore
//
//  Created by Claire Peyron on 13/06/2018.
//

import Foundation

enum ConsoleError {
    case unusedKeyInMainLanguage(key: String)
    case missingKeyInMainLanguage(key: String)
    case errorPattern(value: String)
    case genericKey(value: String)
    case badPattern(value: String)
    case unusedKey(key: String)
    case missingKey(key: String)
    case redundantKey(key: String)
    case badFormatMisplaced$Key(key: String, value: String, formattableCharacter: String)
    case untranslatedKey(key: String)
    case badArguments(key: String, properCount: Int, currentCount: Int)
    case badUsageOfFormattedKey(key: String, properCount: Int)
    case badArgumentsFormat(key: String)
}

extension ConsoleError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .unusedKeyInMainLanguage(let key):
            return "[Unused Key on main localization file] \(key)"
        case .missingKeyInMainLanguage(let key):
            return "[Missing Key on main localization file] \(key)"
        case .errorPattern(let value):
            return "Use ADUtils Format for \(value) key"
        case .genericKey(let value):
            return "Use proper key \(value) instead of generic"
        case .badPattern(let value):
            return "Inline keys in \(value)"
        case .unusedKey(let key):
            return "[Unsued Key] \(key)"
        case .missingKey(let key):
            return "[Missing Key] \(key)"
        case .redundantKey(let key):
            return "[Redundant Key] \(key)"
        case .badFormatMisplaced$Key(let key, let value, let formattableCharacter):
            return "[Bad Format] \(key) - Use %\(value.firstNumber ?? 1)$\(formattableCharacter) instead of \(value)"
        case .untranslatedKey(let key):
            return "[Untranslated Key] \(key)"
        case .badArguments(let key, let properCount, let currentCount):
            return "[Bad Arguments] \(key) needs \(properCount) argument(s), found \(currentCount)"
        case .badUsageOfFormattedKey(let key, let properCount):
            return "[Bad Usage] \(key) needs \(properCount) argument(s)"
        case .badArgumentsFormat(let key):
            return "[Bad Arguments Format] Rewrite argument(s) count in \(key)"
        }
    }
}
