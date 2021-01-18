//
//  LocatedError.swift
//  Commander
//
//  Created by Pierre Felgines on 15/06/2018.
//

import Foundation

struct LocatedError: LocalizedError {
    let filePath: String
    let line: Int
    let error: Error

    var errorDescription: String? {
        return error.localizedDescription
    }
}
