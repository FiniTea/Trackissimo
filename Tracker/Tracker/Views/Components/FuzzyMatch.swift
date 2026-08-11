//
//  FuzzyMatch.swift
//  Tracker
//
//  A small subsequence-based fuzzy matcher (the classic fzf-style "characters of
//  the query appear in order, not necessarily contiguous" approach), shared by
//  the SF Symbol picker and the button search on the Log tab. Kept dependency-free
//  since the matching needs here are simple — this is not a ranking engine, just
//  "does the query loosely match, and how well."
//

import Foundation

enum FuzzyMatch {
    /// Returns a match score if `query`'s characters appear in order (not
    /// necessarily contiguously) within `text`, case-insensitively; nil if they
    /// don't. Higher scores mean a tighter/better match (consecutive character
    /// runs and early matches score higher), so callers can sort results by score.
    static func score(query: String, in text: String) -> Int? {
        guard !query.isEmpty else { return 0 }

        let queryChars = Array(query.lowercased())
        let textChars = Array(text.lowercased())

        var queryIndex = 0
        var score = 0
        var consecutiveRun = 0

        for (textIndex, char) in textChars.enumerated() {
            guard queryIndex < queryChars.count else { break }
            if char == queryChars[queryIndex] {
                queryIndex += 1
                consecutiveRun += 1
                // Reward consecutive runs and matches near the start of the text.
                score += 10 + consecutiveRun * 5 - min(textIndex, 20)
            } else {
                consecutiveRun = 0
            }
        }

        return queryIndex == queryChars.count ? score : nil
    }

    /// Filters and sorts `items` by fuzzy match quality against `query`, using
    /// `keyPath` as the searchable text. Returns all items unsorted-by-score (in
    /// their original order) if `query` is empty.
    static func filter<T>(_ items: [T], query: String, text: (T) -> String) -> [T] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return items }
        return items
            .compactMap { item -> (T, Int)? in
                guard let score = score(query: query, in: text(item)) else { return nil }
                return (item, score)
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }
}
