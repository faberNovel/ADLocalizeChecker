//
//  Occurence.swift
//
//
//  Created by Claire Peyron on 29/08/2019.
//

typealias Occurences = Set<Occurence>

struct Occurence: Hashable {
    let fileName: String
    let lineNumber: Int
    private(set) var checked: Bool

    // MARK: - Lifecycle

    init(fileName: String, lineNumber: Int) {
        self.fileName = fileName
        self.lineNumber = lineNumber
        self.checked = false
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(fileName)
        hasher.combine(lineNumber)
    }

    // MARK: - Occurence

    func markAsChecked() -> Occurence {
        var copy = self
        copy.checked = true
        return copy
    }
}
