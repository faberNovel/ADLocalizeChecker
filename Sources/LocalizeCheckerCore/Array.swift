//
//  Array.swift
//  LocalizeChecker
//
//  Created by Claire Peyron on 12/06/2018.
//

import Foundation

extension Array where Element == String {
    func findPatterns(in fileContent: String, completion: (String, NSTextCheckingResult?) -> Void) {
        forEach { pattern in
            pattern.findPattern(in: fileContent) { completion(pattern, $0) }
        }
    }
}

extension Array where Element: Collection {
    func flatten() -> [Element.Element] {
        return reduce([]) { $0 + $1 }
    }
}

extension Array {
    func product<T, U>(with array: [T], concat: (Element, T) -> U) -> [U] {
        return map { element in array.map { concat(element, $0) } }.flatten()
    }

    func next(at index: Int) -> Element? {
        return index + 1 < count ? self[index + 1] : nil
    }
}

enum Way {
    case increasing, decreasing

    func getFollowingValue(for value: Int) -> Int {
        switch self {
        case .increasing:
            return value + 1
        case .decreasing:
            return value - 1
        }
    }

    func getPreviousValue(for value: Int) -> Int {
        switch self {
        case .increasing:
            return value - 1
        case .decreasing:
            return value + 1
        }
    }
}

extension Array where Element == Array<Int> {
    func filterAsFollowingSeries(_ way: Way) -> [[Int]] {
        let array = way == .increasing ? self : Array(self.reversed())
        var result: [[Int]] = []
        for (index, value) in array.enumerated() {
            var filtered = value
            if let next = array.next(at: index) {
                filtered = filtered.filter { next.contains(way.getFollowingValue(for: $0)) }
            }
            if let last = result.last {
                filtered = filtered.filter { last.contains(way.getPreviousValue(for: $0)) }
            }
            result.append(filtered)
        }
        return result
    }
}
