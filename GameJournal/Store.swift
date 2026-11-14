import SwiftUI

@MainActor @Observable final class JournalStore {
    var data: JournalData
    var error: String?
    private let url: URL
    init() {
        url = URL.documentsDirectory.appending(path: "game-journal-v1.json")
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                data = try JSONDecoder().decode(JournalData.self, from: Data(contentsOf: url))
            } else { data = JournalData() }
        } catch {
            data = JournalData()
            self.error = "Your journal could not be opened. Your existing file has not been changed. \(error.localizedDescription)"
        }
    }
    var me: Player { data.players.first(where: \.isMe) ?? data.players[0] }
    func name(_ id: UUID) -> String { data.players.first { $0.id == id }?.name ?? "Unknown player" }
    func save(_ session: GameSession, players: [Player]) throws {
        var next = data
        for player in players where !next.players.contains(where: { $0.id == player.id }) { next.players.append(player) }
        if let index = next.sessions.firstIndex(where: { $0.id == session.id }) { next.sessions[index] = session }
        else { next.sessions.append(session) }
        try persist(next)
    }
    func renameMe(_ name: String) throws {
        var next = data
        if let index = next.players.firstIndex(where: \.isMe) { next.players[index].name = name }
        try persist(next)
    }
    private func persist(_ next: JournalData) throws {
        guard error == nil else { throw CocoaError(.fileReadCorruptFile) }
        let encoded = try JSONEncoder().encode(next)
        try encoded.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        data = next
    }
}
