//
//  FormattedKey.swift
//
//
//  Created by Claire Peyron on 28/08/2019.
//

typealias FormattedKeys = Set<FormattedKey>

struct FormattedKey: Hashable {
    let key: String
    let argumentsCount: Int
    private(set) var occurences: Occurences

    // MARK: - Lifecycle

    @available(*, unavailable)
    init(key: String, argumentsCount: Int, occurences: Occurences) {
        fatalError("init is unavailable - use init?")
    }

    init?(key: String, argumentsCount: Int) {
        guard argumentsCount > 0 else { return nil }
        self.key = key
        self.argumentsCount = argumentsCount
        self.occurences = []
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    // MARK: - FormattedKey

    func markAsUsed(in fileName: String, lineNumber: Int) -> FormattedKey {
        var copy = self
        let current = Occurence(fileName: fileName, lineNumber: lineNumber)
        if copy.occurences.contains(current) {
            copy.occurences.remove(current)
            copy.occurences.insert(current.markAsChecked())
        }
        return copy
    }

    func addFile(_ fileName: String, lineNumber: Int) -> FormattedKey {
        var copy = self
        let occurence = Occurence(fileName: fileName, lineNumber: lineNumber)
        copy.occurences.insert(occurence)
        return copy
    }

    func lastOccurenceLineNumber(in fileName: String) -> Int {
        let lastOccurence = occurences
            .filter { $0.fileName == fileName }
            .sorted { $0.lineNumber <= $1.lineNumber }
            .last
        return lastOccurence?.lineNumber ?? 0
    }

    func lineSeen(in fileName: String) -> [Int] {
        return occurences
            .filter { $0.fileName == fileName && $0.checked }
            .map { $0.lineNumber }
    }
}
