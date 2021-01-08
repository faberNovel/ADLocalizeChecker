//
//  ScriptError.swift
//  LocalizeCheckerCore
//
//  Created by Claire Peyron on 12/06/2018.
//

import Foundation

enum ScriptError {
    case issueOnExecution(numberOfErrors: Int)
}

extension ScriptError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .issueOnExecution(let numberOfErrors):
            return "You have \(numberOfErrors) localization error(s)"
        }
    }
}
