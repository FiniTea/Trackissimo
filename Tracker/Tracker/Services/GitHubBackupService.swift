//
//  GitHubBackupService.swift
//  Tracker
//
//  Pushes a full JSON snapshot of the SwiftData store to GitHub after every
//  change (debounced), and offers a manual, purely-additive restore. Same
//  principle as the old HTML app: a PAT typed into Settings once, stored in the
//  Keychain, pushed via the GitHub Contents API to the same repo.
//

import Foundation
import SwiftData
import Observation

enum GitHubBackupError: LocalizedError {
    case missingToken
    case requestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .missingToken: return "Kein GitHub-Token hinterlegt."
        case .requestFailed(let code): return "GitHub-Anfrage fehlgeschlagen (HTTP \(code))."
        }
    }
}

@Observable
@MainActor
final class GitHubBackupService {
    static let shared = GitHubBackupService()
    private init() {}

    private let repoOwner = "FiniTea"
    private let repoName = "Trackissimo"
    private let filePath = "backups/tracker.json"

    private(set) var isSyncing = false
    private(set) var lastSyncDate: Date?
    private(set) var lastSyncError: String?

    private var pendingSyncTask: Task<Void, Never>?

    var hasToken: Bool { KeychainStore.read() != nil }

    // MARK: - Debounced auto-sync

    /// Cancels any pending push and schedules a new one ~2s out, so rapid-fire
    /// changes (several taps in a row) coalesce into a single request instead
    /// of hammering the API once per change.
    func scheduleSync(modelContext: ModelContext) {
        guard hasToken else { return }
        pendingSyncTask?.cancel()
        pendingSyncTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await pushSnapshot(modelContext: modelContext)
        }
    }

    // MARK: - Push

    func pushSnapshot(modelContext: ModelContext) async {
        guard let token = KeychainStore.read() else {
            lastSyncError = GitHubBackupError.missingToken.localizedDescription
            return
        }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let export = try buildExport(modelContext: modelContext)
            let jsonData = try BackupCoding.makeEncoder().encode(export)
            let base64Content = jsonData.base64EncodedString()
            let sha = try await fetchCurrentSha(token: token)
            try await putFile(token: token, base64Content: base64Content, sha: sha)
            lastSyncDate = .now
            lastSyncError = nil
        } catch {
            lastSyncError = error.localizedDescription
        }
    }

    private func buildExport(modelContext: ModelContext) throws -> BackupExport {
        let groups = try modelContext.fetch(FetchDescriptor<ActivityGroup>())
        let buttons = try modelContext.fetch(FetchDescriptor<ActivityButton>())
        let entries = try modelContext.fetch(FetchDescriptor<LogEntry>())
        let wellbeing = try modelContext.fetch(FetchDescriptor<WellbeingEntry>())

        return BackupExport(
            exportedAt: .now,
            schemaVersion: 1,
            groups: groups.map {
                GroupExport(id: $0.id, name: $0.name, showsPieChart: $0.showsPieChart, sortOrder: $0.sortOrder)
            },
            buttons: buttons.map {
                ButtonExport(
                    id: $0.id,
                    name: $0.name,
                    groupId: $0.group?.id,
                    groupName: $0.group?.name,
                    icon: $0.icon,
                    colorHex: $0.colorHex,
                    loggingMode: $0.loggingModeRaw,
                    statKind: $0.statKindRaw,
                    heatmapMaxFrequency: $0.heatmapMaxFrequency
                )
            },
            logEntries: entries.map {
                LogEntryExport(
                    id: $0.id,
                    buttonId: $0.button?.id,
                    buttonName: $0.button?.name ?? "Gelöschter Button",
                    groupName: $0.button?.group?.name,
                    startDate: $0.startDate,
                    endDate: $0.endDate
                )
            },
            wellbeingEntries: wellbeing.map {
                WellbeingExport(id: $0.id, score: $0.score, timestamp: $0.timestamp)
            }
        )
    }

    // MARK: - Restore (manual, additive-only)

    /// Pulls the remote snapshot and inserts only rows whose `id` doesn't
    /// already exist locally. Deliberately not a two-way merge — this is a
    /// rare, manual recovery action, not a sync engine, so it never overwrites
    /// local edits with a possibly-stale remote value. Returns how many rows of
    /// each kind were newly imported.
    func restore(modelContext: ModelContext) async throws -> (groups: Int, buttons: Int, entries: Int, wellbeing: Int) {
        guard let token = KeychainStore.read() else { throw GitHubBackupError.missingToken }
        let export = try await fetchRemoteExport(token: token)

        let existingGroupIDs = Set(try modelContext.fetch(FetchDescriptor<ActivityGroup>()).map(\.id))
        let existingButtonIDs = Set(try modelContext.fetch(FetchDescriptor<ActivityButton>()).map(\.id))
        let existingEntryIDs = Set(try modelContext.fetch(FetchDescriptor<LogEntry>()).map(\.id))
        let existingWellbeingIDs = Set(try modelContext.fetch(FetchDescriptor<WellbeingEntry>()).map(\.id))

        // Groups first (no dependencies), then buttons (depend on groups),
        // then entries (depend on buttons), then wellbeing (no dependencies) —
        // strict order since SwiftData relationships need their target
        // objects to exist first.
        var groupsByID: [UUID: ActivityGroup] = [:]
        var importedGroups = 0
        for groupExport in export.groups where !existingGroupIDs.contains(groupExport.id) {
            let group = ActivityGroup(
                id: groupExport.id,
                name: groupExport.name,
                sortOrder: groupExport.sortOrder,
                showsPieChart: groupExport.showsPieChart
            )
            modelContext.insert(group)
            groupsByID[group.id] = group
            importedGroups += 1
        }
        // Also index pre-existing groups so newly-imported buttons can link to them.
        for group in try modelContext.fetch(FetchDescriptor<ActivityGroup>()) { groupsByID[group.id] = group }

        var buttonsByID: [UUID: ActivityButton] = [:]
        for button in try modelContext.fetch(FetchDescriptor<ActivityButton>()) { buttonsByID[button.id] = button }

        var importedButtons = 0
        for buttonExport in export.buttons where !existingButtonIDs.contains(buttonExport.id) {
            let button = ActivityButton(
                id: buttonExport.id,
                name: buttonExport.name,
                icon: buttonExport.icon,
                colorHex: buttonExport.colorHex,
                loggingMode: LoggingMode(rawValue: buttonExport.loggingMode) ?? .instant,
                statKind: StatKind(rawValue: buttonExport.statKind) ?? .none,
                heatmapMaxFrequency: buttonExport.heatmapMaxFrequency,
                group: buttonExport.groupId.flatMap { groupsByID[$0] }
            )
            modelContext.insert(button)
            buttonsByID[button.id] = button
            importedButtons += 1
        }

        var importedEntries = 0
        for entryExport in export.logEntries where !existingEntryIDs.contains(entryExport.id) {
            let entry = LogEntry(
                id: entryExport.id,
                startDate: entryExport.startDate,
                endDate: entryExport.endDate,
                button: entryExport.buttonId.flatMap { buttonsByID[$0] }
            )
            modelContext.insert(entry)
            importedEntries += 1
        }

        var importedWellbeing = 0
        for wellbeingExport in export.wellbeingEntries where !existingWellbeingIDs.contains(wellbeingExport.id) {
            let entry = WellbeingEntry(id: wellbeingExport.id, score: wellbeingExport.score, timestamp: wellbeingExport.timestamp, healthKitSynced: true)
            modelContext.insert(entry)
            importedWellbeing += 1
        }

        return (importedGroups, importedButtons, importedEntries, importedWellbeing)
    }

    // MARK: - GitHub Contents API

    private var contentsURL: URL {
        URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/contents/\(filePath)")!
    }

    private func authorizedRequest(url: URL, token: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        return request
    }

    /// Returns the current file's `sha` (required by the Contents API to update
    /// an existing file), or nil if the file doesn't exist yet (first-ever backup).
    private func fetchCurrentSha(token: String) async throws -> String? {
        let request = authorizedRequest(url: contentsURL, token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GitHubBackupError.requestFailed(-1) }
        if http.statusCode == 404 { return nil }
        guard http.statusCode == 200 else { throw GitHubBackupError.requestFailed(http.statusCode) }
        struct ContentsResponse: Decodable { let sha: String }
        return try JSONDecoder().decode(ContentsResponse.self, from: data).sha
    }

    private func putFile(token: String, base64Content: String, sha: String?) async throws {
        var request = authorizedRequest(url: contentsURL, token: token)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct PutBody: Encodable {
            let message: String
            let content: String
            let sha: String?
        }
        let body = PutBody(message: "Backup \(Date.now.formatted(.iso8601))", content: base64Content, sha: sha)
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw GitHubBackupError.requestFailed(code)
        }
    }

    private func fetchRemoteExport(token: String) async throws -> BackupExport {
        let request = authorizedRequest(url: contentsURL, token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw GitHubBackupError.requestFailed(code)
        }
        struct ContentsResponse: Decodable { let content: String }
        let contentsResponse = try JSONDecoder().decode(ContentsResponse.self, from: data)
        // GitHub returns base64 content with embedded newlines every 60 chars.
        let cleanedBase64 = contentsResponse.content.replacingOccurrences(of: "\n", with: "")
        guard let decodedData = Data(base64Encoded: cleanedBase64) else {
            throw GitHubBackupError.requestFailed(-1)
        }
        return try BackupCoding.makeDecoder().decode(BackupExport.self, from: decodedData)
    }
}
