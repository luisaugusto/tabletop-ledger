import Foundation

struct Player: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var isMe = false
}
struct Entry: Identifiable, Codable, Hashable {
    var id = UUID()
    var playerID: UUID
    var score: String = ""
    var isWinner = false
}
struct GameSession: Identifiable, Codable, Hashable {
    var id = UUID()
    var game: String = ""
    var date = Date()
    var entries: [Entry] = []
    var rating = 0
    var notes = ""
    var photo: Data? = nil
}
struct JournalData: Codable {
    var players: [Player] = [Player(name: "Me", isMe: true)]
    var sessions: [GameSession] = []
}
struct PlayerStats {
    var played: Int
    var wins: Int
    var decided: Int
    var rate: String { decided == 0 ? "—" : "\(Int((Double(wins) / Double(decided) * 100).rounded()))%" }
    static func calculate(_ playerID: UUID, sessions: [GameSession]) -> PlayerStats {
        let played = sessions.filter { $0.entries.contains { $0.playerID == playerID } }
        let decided = played.filter { $0.entries.contains(where: \.isWinner) }
        let wins = decided.filter { $0.entries.contains { $0.playerID == playerID && $0.isWinner } }
        return .init(played: played.count, wins: wins.count, decided: decided.count)
    }
}
