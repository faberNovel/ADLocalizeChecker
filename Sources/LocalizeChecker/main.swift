//
//  Localize.swift
//  ADLocalizeChecker
//
//  Created by Claire Peyron on 15/05/2018.
//

import Foundation
import LocalizeCheckerCore
import Commander

let main = command(
    Argument<String>("targetName", description: "Target name in Xcode project"),
    Argument<String>("plistPath", description: "Plist configuration file path")
) { targetName, plistPath in
    do {
        try LocalizeChecker(
            targetName: targetName,
            plistPath: plistPath
        ).run()
    } catch {
        print(error.localizedDescription)
        exit(1)
    }
}
main.run()
