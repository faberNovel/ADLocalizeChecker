//
//  Logger.swift
//  Commander
//
//  Created by Pierre Felgines on 15/06/2018.
//

import Foundation

class Logger {

    private let configuration: Configuration
    private(set) var numberOfErrors = 0

    private weak var testDelegate: LocalizeCheckerTestDelegate?

    init(configuration: Configuration, testDelegate: LocalizeCheckerTestDelegate?) {
        self.configuration = configuration
        self.testDelegate = testDelegate
    }

    // MARK: - Public

    func log(_ string: String) {
        print(string)
    }

    func log(_ error: LocatedError) {
        testDelegate?.localizeCheckerDidFind(error)
        log("\(error.filePath):\(error.line): \(errorWording): \(error.localizedDescription)")
        numberOfErrors += 1
    }

    // MARK: - Private

    private var errorWording: String {
        return configuration.treatScriptAsError ? "error" : "warning"
    }
}
